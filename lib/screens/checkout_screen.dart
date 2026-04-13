import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_state.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_paystack_max/flutter_paystack_max.dart';
import 'package:flutter/foundation.dart';
import './recipe_homescreen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum PaymentMethod { cashOnDelivery, cardPayment }

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController addressController = TextEditingController();
  PaymentMethod selectedPayment = PaymentMethod.cashOnDelivery;
  bool isPlacingOrder = false;
  bool _orderPlaced = false;

  // --- PAYSTACK INTEGRATION ---
  // --- PAYSTACK INTEGRATION ---
  Future<bool> payWithCard(
      BuildContext context, ApplicationState appState) async {
    // 1. Initialize and get the key immediately in local scope
    if (!dotenv.isInitialized) {
      await dotenv.load();
    }

    // Capture the key in a local variable to avoid 'NoSuchMethodError' in callbacks
    final String localSecretKey = dotenv.maybeGet('SecretKey') ?? "";

    if (localSecretKey.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: SecretKey not found in .env")),
        );
      }
      return false;
    }

    final user = FirebaseAuth.instance.currentUser;
    String customerEmail = user?.email ?? "customer@email.com";
    double totalAmount = appState.totalPrice;

    final int amountInKobo = (totalAmount * 100).round();
    final String localRef = 'REF_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final request = PaystackTransactionRequest(
        reference: localRef,
        secretKey: localSecretKey, // Use local variable
        currency: PaystackCurrency.ngn,
        email: customerEmail,
        amount: amountInKobo.toDouble(),
        channel: [
          PaystackPaymentChannel.card,
          PaystackPaymentChannel.ussd,
          PaystackPaymentChannel.bankTransfer
        ],
      );

      final initialized = await PaymentService.initializeTransaction(request);

      if (!initialized.status || initialized.data == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.red, content: Text(initialized.message)));
        }
        return false;
      }

      final String finalReference = initialized.data?.reference ?? localRef;

      if (kIsWeb) {
        final url = Uri.parse(initialized.data?.authorizationUrl ?? "");
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);

          // ignore: use_build_context_synchronously
          return await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) => AlertDialog(
                  title: const Text("Confirm Payment"),
                  content: const Text(
                      "Finish the payment in the new tab, then click 'Verify'."),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text("Cancel")),
                    ElevatedButton(
                      onPressed: () async {
                        // 1. Show a loading indicator so the user doesn't spam the button
                        showDialog(
                          context: dialogContext,
                          barrierDismissible: false,
                          builder: (context) =>
                              const Center(child: CircularProgressIndicator()),
                        );

                        final response = await PaymentService.verifyTransaction(
                          finalReference,
                          paystackSecretKey: localSecretKey,
                        );

                        // Remove the loading indicator
                        Navigator.pop(dialogContext);

                        debugPrint("--- VERIFICATION DEBUG ---");
                        debugPrint("Raw Response Message: ${response.message}");
                        debugPrint("Raw Data Status: ${response.data?.status}");

                        // 2. Expanded Success Check
                        // Some versions of the API return 'success', 'successful', or just status true with a success message
                        bool isSuccess = (response.status == true) &&
                            (response.data?.status == 'success' ||
                                response.data?.status == 'successful' ||
                                response.message
                                        ?.toLowerCase()
                                        .contains("success") ==
                                    true);

                        if (isSuccess) {
                          if (!_orderPlaced) {
                            await placeOrder(appState, isCardPayment: true);
                          }

                          // Close the "Confirm Payment" Alert Dialog
                          Navigator.of(dialogContext).pop(true);

                          // Navigate to Home
                          if (mounted) {
                            Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const RecipeHomeScreen()),
                                (route) => false);
                          }
                        } else {
                          // 3. Inform the user exactly what the server said
                          // 1. Get the status as a string (handling potential nulls safely)
                          final String dataStatus =
                              response.data.status?.toString() ??
                                  "unknown_status";

// 2. Get the message as a string
                          final String apiMessage =
                              response.message?.toString() ??
                                  "No message from server";

// 3. Construct the failure reason with explicit String typing
                          String failureReason;

                          if (dataStatus == "abandoned") {
                            failureReason =
                                "Payment was abandoned. Please complete the transaction in the other tab.";
                          } else if (dataStatus == "failed") {
                            failureReason =
                                "The bank declined the transaction.";
                          } else {
                            // Fallback to the API message, ensuring it's a String
                            failureReason = apiMessage;
                          }

// 4. Show the SnackBar
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.orange,
                              content:
                                  Text("Verification Failed: $failureReason"),
                            ),
                          );

                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            backgroundColor: Colors.orange,
                            content: Text(
                                "Paystack says: $failureReason. Try again in a moment."),
                            action: SnackBarAction(
                                label: "OK",
                                textColor: Colors.white,
                                onPressed: () {}),
                          ));
                        }
                      },
                      child: const Text("Verify Payment"),
                    ),
                  ],
                ),
              ) ??
              false;
        }
      } else {
        // MOBILE FLOW
        await PaymentService.showPaymentModal(
          context,
          transaction: initialized,
          callbackUrl: 'https://standard.paystack.co/close',
        );

        final response = await PaymentService.verifyTransaction(
          finalReference,
          paystackSecretKey: localSecretKey,
        );

        if (response.status && response.data?.status == 'success') {
          if (!_orderPlaced) {
            await placeOrder(appState, isCardPayment: true);
          }
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const RecipeHomeScreen()),
              (route) => false,
            );
          }
          return true;
        }
      }
    } catch (e) {
      debugPrint("Paystack Error: $e");
      return false;
    }
    return false;
  }

  // ... (build method and placeOrder method stay largely the same, but ensure mounted checks)

  @override
  Widget build(BuildContext context) {
    return Consumer<ApplicationState>(
      builder: (context, appState, _) {
        return Scaffold(
          appBar: AppBar(title: const Text("Checkout")),
          body: appState.cartItems.isEmpty
              ? const Center(child: Text("Your cart is empty"))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView(
                    children: [
                      const Text("Order Summary",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      ...appState.cartItems.map((item) => Card(
                            child: ListTile(
                              title: Text(item.name),
                              subtitle: Text("Qty: ${item.quantity}"),
                              trailing: Text("₦${item.price * item.quantity}"),
                            ),
                          )),
                      const SizedBox(height: 20),
                      const Text("Delivery Address",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      TextField(
                          controller: addressController,
                          decoration: const InputDecoration(
                              hintText: "Enter delivery address")),
                      const SizedBox(height: 20),
                      const Text("Payment Method",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      RadioListTile<PaymentMethod>(
                        title: const Text("Cash on Delivery"),
                        value: PaymentMethod.cashOnDelivery,
                        groupValue: selectedPayment,
                        onChanged: (val) =>
                            setState(() => selectedPayment = val!),
                      ),
                      RadioListTile<PaymentMethod>(
                        title: const Text("Card Payment"),
                        value: PaymentMethod.cardPayment,
                        groupValue: selectedPayment,
                        onChanged: (val) =>
                            setState(() => selectedPayment = val!),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("₦${appState.totalPrice.toStringAsFixed(2)}",
                              style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.home),
                      label: const Text('Home'),
                      onPressed: () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RecipeHomeScreen()),
                        (route) => false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.shopping_cart_checkout),
                      label: Text(_orderPlaced
                          ? "Order Placed!"
                          : isPlacingOrder
                              ? "Processing..."
                              : "Place Order"),
                      onPressed: isPlacingOrder || _orderPlaced
                          ? null
                          : () async {
                              if (addressController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("Enter an address")));
                                return;
                              }

                              setState(() => isPlacingOrder = true);

                              if (selectedPayment ==
                                  PaymentMethod.cardPayment) {
                                await payWithCard(context, appState);
                              } else {
                                await placeOrder(appState,
                                    isCardPayment: false);
                              }

                              if (mounted)
                                setState(() => isPlacingOrder = false);
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> placeOrder(ApplicationState appState,
      {required bool isCardPayment}) async {
    if (_orderPlaced) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final String orderId = 'ORD_${DateTime.now().millisecondsSinceEpoch}';
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();
      final userData = userDoc.data();

      final Map<String, dynamic> orderData = {
        "orderId": orderId,
        "items": appState.cartItems
            .map((e) =>
                {"name": e.name, "price": e.price, "quantity": e.quantity})
            .toList(),
        "address": addressController.text.trim(),
        "paymentMethod": isCardPayment ? "cardPayment" : "cashOnDelivery",
        "paymentStatus": isCardPayment ? "Paid" : "Pending (COD)",
        "total": appState.totalPrice,
        "status": "Pending",
        "createdAt": FieldValue.serverTimestamp(),
        "userId": user.uid,
        "email": userData?['email'] ?? user.email,
        "displayName": userData?['displayName'] ?? 'Customer',
      };

      WriteBatch batch = FirebaseFirestore.instance.batch();
      batch.set(
          FirebaseFirestore.instance.collection("all_orders").doc(orderId),
          orderData);
      batch.set(
          FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .collection("orders")
              .doc(orderId),
          orderData);

      await batch.commit();
      appState.clearCart();
      _orderPlaced = true;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Order placed successfully!"),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      debugPrint("🛑 FIRESTORE ERROR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Database Error: $e"), backgroundColor: Colors.red));
      }
    }
  }
}
