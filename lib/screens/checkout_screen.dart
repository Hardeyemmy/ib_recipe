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
  bool _orderPlaced = false; // Prevent duplicate order placement
  final String mySecretKey = dotenv.env['SecretKey'] ?? "";

  @override
  void initState() {
    super.initState();
    // Reset order placed flag when entering checkout
    _orderPlaced = false;
  }

  // --- PAYSTACK INTEGRATION ---
  Future<bool> payWithCard(
      BuildContext context, ApplicationState appState) async {
    print("💳 payWithCard called");
    final user = FirebaseAuth.instance.currentUser;

    // FIX 1: Guarantee the Email is never null
    // If Firebase doesn't have an email, we use a placeholder so Paystack doesn't crash
    String customerEmail = user?.email ?? "customer@email.com";
    if (customerEmail.isEmpty) customerEmail = "customer@email.com";

    // FIX 2: Guarantee the Amount is valid
    double totalAmount = appState.totalPrice;
    if (totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Cart amount cannot be zero.")),
      );
      return false;
    }

    final String ref = 'REF_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final request = PaystackTransactionRequest(
        reference: ref,
        secretKey: mySecretKey,
        currency: PaystackCurrency.ngn,
        email: customerEmail,
        amount: totalAmount.round() * 100, // Paystack expects amount in kobo
        channel: [
          PaystackPaymentChannel.card,
          PaystackPaymentChannel.ussd,
          PaystackPaymentChannel.bankTransfer
        ],
      );

      // This is the line where the crash was happening
      final initialized = await PaymentService.initializeTransaction(request);

      // FIX 3: Add extra safety checks for the response
      if (!initialized.status || initialized.data == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.red,
            content: Text(initialized.message),
          ));
        }
        return false;
      }

      // WEB FLOW
      if (kIsWeb) {
        final url = Uri.parse(initialized.data?.authorizationUrl ?? "");
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);

          return await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  title: const Text("Confirm Payment"),
                  content: const Text(
                      "Once you have finished the payment in the new tab, click 'Verify'."),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel")),
                    ElevatedButton(
                      onPressed: () async {
                        final response = await PaymentService.verifyTransaction(
                          paystackSecretKey: mySecretKey,
                          initialized.data?.reference ?? ref,
                        );

                        bool success = response.status &&
                            (response.data.status == 'success' ||
                                response.data.status ==
                                    PaystackTransactionStatus.success);

                        if (success) {
                          if (!mounted) return;

                          // 1. Save the order
                          if (!_orderPlaced) {
                            await placeOrder(appState, isCardPayment: true);
                          }

                          // 2. Close the Dialog first
                          Navigator.pop(context);

                          // 3. Navigate to Home and clear the history
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text("Payment not verified. Try again.")),
                          );
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
        return await PaymentService.showPaymentModal(
          context,
          transaction: initialized,
          callbackUrl: 'https://standard.paystack.co/close',
        ).then((_) async {
          final response = await PaymentService.verifyTransaction(
            paystackSecretKey: mySecretKey,
            initialized.data?.reference ?? ref,
          );

          // Debug: Print response details
          debugPrint(
              "Mobile Verification Response - Status: ${response.status}, Message: ${response.message}, Data Status: ${response.data.status}");

          bool mobileSuccess = response.status &&
              (response.data.status == 'success' ||
                  response.data.status == PaystackTransactionStatus.success);

          debugPrint("Mobile success check result: $mobileSuccess");
          debugPrint("Mobile response.data?.status: ${response.data.status}");
          debugPrint(
              "Mobile response.data?.status type: ${response.data.status.runtimeType}");

          if (mobileSuccess) {
            print(
                "✅ Mobile payment verification successful, calling placeOrder");

            // Prevent duplicate order placement
            if (!_orderPlaced) {
              await placeOrder(appState, isCardPayment: true);
            } else {
              print("⚠️ Order already placed, skipping placeOrder call");
            }
            return true;
          } else {
            // Show error message for mobile flow
            String errorMessage = "Payment not verified. Please try again.";
            if (response.message.isNotEmpty) {
              errorMessage += " Details: ${response.message}";
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorMessage)),
              );
            }
            return false;
          }
        });
      }
    } catch (e) {
      // FIX 4: Catch the error so the app doesn't freeze
      debugPrint("Paystack Error: $e");
      return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<ApplicationState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout"),
      ),
      body: appState.cartItems.isEmpty
          ? const Center(child: Text("Your cart is empty"))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  const Text("Order Summary",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ...appState.cartItems.map((item) => Card(
                        child: ListTile(
                          title: Text(item.name),
                          subtitle: Text("Qty: ${item.quantity}"),
                          trailing: Text("₦${item.price * item.quantity}"),
                        ),
                      )),
                  const SizedBox(height: 20),
                  const Text("Delivery Address",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                          hintText: "Enter delivery address")),
                  const SizedBox(height: 20),
                  const Text("Payment Method",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  RadioListTile<PaymentMethod>(
                    title: const Text("Cash on Delivery"),
                    value: PaymentMethod.cashOnDelivery,
                    groupValue: selectedPayment,
                    onChanged: (val) => setState(() => selectedPayment = val!),
                  ),
                  RadioListTile<PaymentMethod>(
                    title: const Text("Card Payment"),
                    value: PaymentMethod.cardPayment,
                    groupValue: selectedPayment,
                    onChanged: (val) => setState(() => selectedPayment = val!),
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
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RecipeHomeScreen()),
                      (route) => false,
                    );
                  },
                ),
              ),
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
                          print("🛒 Place Order button pressed");

                          // Prevent multiple order attempts
                          if (_orderPlaced) {
                            print(
                                "⚠️ Order already placed, ignoring button press");
                            return;
                          }

                          if (addressController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Enter an address")));
                            return;
                          }

                          setState(() => isPlacingOrder = true);

                          if (selectedPayment == PaymentMethod.cardPayment) {
                            print(
                                "💳 Card payment selected, calling payWithCard");
                            // For Card, the placeOrder is called INSIDE payWithCard upon verification
                            await payWithCard(context, appState);
                          } else {
                            print(
                                "💵 Cash payment selected, calling placeOrder directly");
                            // For Cash, we call it directly here
                            await placeOrder(appState, isCardPayment: false);
                          }

                          if (mounted) setState(() => isPlacingOrder = false);
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> placeOrder(ApplicationState appState,
      {required bool isCardPayment}) async {
    print("🔥 PLACEORDER CALLED - isCardPayment: $isCardPayment");

    // Prevent duplicate order placement
    if (_orderPlaced) {
      print("⚠️ Order already placed, skipping duplicate call");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("❌ User is null - cannot place order");
      return;
    }

    print("📦 Starting placeOrder for user: ${user.uid}");

    try {
      final String orderId = 'ORD_${DateTime.now().millisecondsSinceEpoch}';
      debugPrint("📋 Order ID: $orderId");

      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();
      final userData = userDoc.data();
      debugPrint("👤 User data fetched: ${userData?.keys.toList()}");

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
      debugPrint("📝 Order data prepared: ${orderData.keys.toList()}");

      debugPrint("💾 Creating WriteBatch...");
      WriteBatch batch = FirebaseFirestore.instance.batch();

      debugPrint("💾 Batch set 1: all_orders/$orderId");
      batch.set(
          FirebaseFirestore.instance.collection("all_orders").doc(orderId),
          orderData);

      debugPrint("💾 Batch set 2: users/${user.uid}/orders/$orderId");
      batch.set(
          FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .collection("orders")
              .doc(orderId),
          orderData);

      debugPrint("⏳ Committing batch...");
      await batch.commit();
      debugPrint("✅ Batch committed successfully!");

      appState.clearCart();
      debugPrint("🗑️ Cart cleared");

      // Mark order as placed to prevent duplicates
      _orderPlaced = true;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Order placed successfully! Tap back to continue."),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3)));
        debugPrint("✨ Success snackbar shown");

        // Don't auto-navigate - let user tap back button manually
        // This prevents navigation crashes during hot reload
        debugPrint("🏠 User can navigate back manually");
      }
    } catch (e) {
      debugPrint("🛑 FIRESTORE ERROR: $e");
      debugPrint("🛑 Error type: ${e.runtimeType}");

      // Reset flags on error
      _orderPlaced = false;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Database Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
}
