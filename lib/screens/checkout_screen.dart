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
    // 1. Check if key exists
    if (mySecretKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Payment configuration missing.")),
      );
      return false;
    }

    final user = FirebaseAuth.instance.currentUser;
    String customerEmail = user?.email ?? "customer@email.com";
    double totalAmount = appState.totalPrice;

    // Paystack expects an integer in Kobo/Cents
    final double amountInKobo = (totalAmount * 100).toDouble();
    final String localRef = 'REF_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final request = PaystackTransactionRequest(
        reference: localRef,
        secretKey: mySecretKey,
        currency: PaystackCurrency.ngn,
        email: customerEmail,
        amount: amountInKobo,
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

      if (kIsWeb) {
        final url = Uri.parse(initialized.data?.authorizationUrl ?? "");
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);

          return await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) => AlertDialog(
                  title: const Text("Confirm Payment"),
                  content: const Text(
                      "Once you have finished the payment in the new tab, click 'Verify'."),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text("Cancel")),
                    ElevatedButton(
                      onPressed: () async {
                        final response = await PaymentService.verifyTransaction(
                          initialized.data?.reference ??
                              localRef, // Positional argument (First)
                          paystackSecretKey: mySecretKey, // Named argument
                        );
                        if (response.status &&
                            (response.data?.status == 'success')) {
                          // IMPORTANT: Wait for Firestore to finish BEFORE navigating
                          if (!_orderPlaced) {
                            await placeOrder(appState, isCardPayment: true);
                          }
                          if (!mounted) return;

                          Navigator.pop(dialogContext, true); // Close Dialog

                          // Clear stack and go home
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RecipeHomeScreen()),
                            (route) => false,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "Verification failed. Please finish payment.")),
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
        final result = await PaymentService.showPaymentModal(
          context,
          transaction: initialized,
          callbackUrl: 'https://standard.paystack.co/close',
        );

        // If user closed the modal, we still verify just in case the webhook was faster
        final response = await PaymentService.verifyTransaction(
          initialized.data?.reference ??
              localRef, // Positional argument (First)
          paystackSecretKey: mySecretKey, // Named argument
        );

        if (response.status && response.data.status == 'success') {
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ApplicationState>(
      builder: (context, appState, _) {
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

                              if (selectedPayment ==
                                  PaymentMethod.cardPayment) {
                                print(
                                    "💳 Card payment selected, calling payWithCard");
                                // For Card, the placeOrder is called INSIDE payWithCard upon verification
                                await payWithCard(context, appState);
                              } else {
                                print(
                                    "💵 Cash payment selected, calling placeOrder directly");
                                // For Cash, we call it directly here
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
