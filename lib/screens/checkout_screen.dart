import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './recipe_homescreen.dart';
import '../app_state.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_paystack_max/flutter_paystack_max.dart';
import 'package:flutter/foundation.dart';

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
  final String mySecretKey = "sk_test_4831664b70082b74c3630c778f7c1130bd283ed7";

  // --- PAYSTACK INTEGRATION ---
  Future<bool> payWithCard(
      BuildContext context, ApplicationState appState) async {
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
                          paystackSecretKey:
                              "sk_test_4831664b70082b74c3630c778f7c1130bd283ed7",
                          initialized.data?.reference ?? ref,
                        );

                        // Debug: Print response details
                        debugPrint(
                            "Verification Response - Status: ${response.status}, Message: ${response.message}, Data Status: ${response.data?.status}");

                        bool success = response.status &&
                            (response.data?.status == 'success');

                        if (!mounted) return;
                        if (success) {
                          await placeOrder(appState, isCardPayment: true);
                          Navigator.pop(context, true);
                        } else {
                          String errorMessage =
                              "Payment not verified. Try again after paying.";
                          if (response.message != null &&
                              response.message!.isNotEmpty) {
                            errorMessage += " Details: ${response.message}";
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(errorMessage)),
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
            paystackSecretKey:
                "sk_test_4831664b70082b74c3630c778f7c1130bd283ed7",
            initialized.data?.reference ?? ref,
          );

          // Debug: Print response details
          debugPrint(
              "Mobile Verification Response - Status: ${response.status}, Message: ${response.message}, Data Status: ${response.data?.status}");

          if (response.status && response.data?.status == 'success') {
            await placeOrder(appState, isCardPayment: true);
            return true;
          } else {
            // Show error message for mobile flow
            String errorMessage = "Payment not verified. Please try again.";
            if (response.message != null && response.message!.isNotEmpty) {
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
      appBar: AppBar(title: const Text("Checkout")),
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
          child: ElevatedButton.icon(
            icon: const Icon(Icons.shopping_cart_checkout),
            label: Text(isPlacingOrder ? "Processing..." : "Place Order"),
            onPressed: isPlacingOrder
                ? null
                : () async {
                    if (addressController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Enter an address")));
                      return;
                    }

                    setState(() => isPlacingOrder = true);

                    if (selectedPayment == PaymentMethod.cardPayment) {
                      // For Card, the placeOrder is called INSIDE payWithCard upon verification
                      await payWithCard(context, appState);
                    } else {
                      // For Cash, we call it directly here
                      await placeOrder(appState, isCardPayment: false);
                    }

                    if (mounted) setState(() => isPlacingOrder = false);
                  },
          ),
        ),
      ),
    );
  }

  Future<void> placeOrder(ApplicationState appState,
      {required bool isCardPayment}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String orderId = 'ORD_${DateTime.now().millisecondsSinceEpoch}';
    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();
    final userData = userDoc.data();

    final Map<String, dynamic> orderData = {
      "orderId": orderId,
      "items": appState.cartItems
          .map(
              (e) => {"name": e.name, "price": e.price, "quantity": e.quantity})
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
    batch.set(FirebaseFirestore.instance.collection("all_orders").doc(orderId),
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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Order placed successfully!"),
          backgroundColor: Colors.green));
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const RecipeHomeScreen()),
          (route) => false);
    }
  }
}
