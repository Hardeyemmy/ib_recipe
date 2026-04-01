import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'recipe_homescreen.dart';
import 'app_state.dart';
import 'package:url_launcher/url_launcher.dart'; // Changed to standard url_launcher
import 'package:flutter_paystack_max/flutter_paystack_max.dart';
import 'package:flutter/foundation.dart'; // Needed for kIsWeb

enum PaymentMethod {
  cashOnDelivery,
  cardPayment,
}

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController addressController = TextEditingController();
  PaymentMethod selectedPayment = PaymentMethod.cashOnDelivery;
  bool isPlacingOrder = false;

  // --- START PAYSTACK INTEGRATION ---

  Future<bool> payWithCard(BuildContext context, double amount) async {
    final user = FirebaseAuth.instance.currentUser;
    const String mySecretKey =
        "sk_test_4831664b70082b74c3630c778f7c1130bd283ed7";

    final request = PaystackTransactionRequest(
      reference: 'REF_${DateTime.now().millisecondsSinceEpoch}',
      secretKey: mySecretKey,
      email: user?.email ?? "customer@email.com",
      amount: (amount * 100).toDouble(), // Paystack expects integers (Kobo)
      currency: PaystackCurrency.ngn,
      channel: [
        PaystackPaymentChannel.card,
        PaystackPaymentChannel.ussd,
        PaystackPaymentChannel.bankTransfer,
      ],
    );

    final initialized = await PaymentService.initializeTransaction(request);

    if (!initialized.status) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text(initialized.message),
      ));
      return false;
    }

    // WEB SPECIFIC FLOW
    if (kIsWeb) {
      final url = Uri.parse(initialized.data?.authorizationUrl ?? "");
      if (await canLaunchUrl(url)) {
        // Open Paystack in a new tab
        await launchUrl(url, mode: LaunchMode.externalApplication);

        // Show a dialog to the user to verify once they return
        return await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text("Confirm Payment"),
                content: const Text(
                    "Once you have finished the payment in the new tab, click 'Verify' to complete your order."),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel"),
                  ),
                  // ... inside your showDialog builder ...
                  ElevatedButton(
                    onPressed: () async {
                      // 1. Perform the verification
                      final response = await PaymentService.verifyTransaction(
                        paystackSecretKey: mySecretKey,
                        initialized.data?.reference ?? request.reference,
                      );

                      bool success =
                          response.status && response.data?.status == 'success';

                      // 2. CRITICAL FIX: Check if the widget is still in the tree
                      // before calling Navigator or using context.
                      if (!mounted) return;

                      // 3. Now it is safe to close the dialog
                      Navigator.of(context).pop(success);
                    },
                    child: const Text("Verify Payment"),
                  ),
                ],
              ),
            ) ??
            false;
      }
      return false;
    }

    // MOBILE FLOW (WebView Modal)
    else {
      return await PaymentService.showPaymentModal(
        context,
        transaction: initialized,
        callbackUrl: 'https://standard.paystack.co/close',
      ).then((_) async {
        final response = await PaymentService.verifyTransaction(
          paystackSecretKey: 'sk_test_4831664b70082b74c3630c778f7c1130bd283ed7',
          initialized.data?.reference ?? request.reference,
        );
        return response.status && response.data?.status == 'success';
      });
    }
  }

  // --- END PAYSTACK INTEGRATION ---

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<ApplicationState>(context);
    final cartItems = appState.cartItems;

    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: cartItems.isEmpty
          ? const Center(
              child: Text("Your cart is empty", style: TextStyle(fontSize: 18)))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  const Text("Order Summary",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...cartItems
                      .map((item) => Card(
                            child: ListTile(
                              title: Text(item.name),
                              subtitle: Text("Qty: ${item.quantity}"),
                              trailing: Text("₦${item.price * item.quantity}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ),
                          ))
                      .toList(),
                  const SizedBox(height: 20),
                  const Text("Delivery Address",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressController,
                    decoration: InputDecoration(
                      hintText: "Enter delivery address",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("Payment Method",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ListTile(
                    title: const Text("Cash on Delivery"),
                    leading: Radio<PaymentMethod>(
                      value: PaymentMethod.cashOnDelivery,
                      groupValue: selectedPayment,
                      onChanged: (val) =>
                          setState(() => selectedPayment = val!),
                    ),
                  ),
                  ListTile(
                    title: const Text("Card Payment"),
                    leading: Radio<PaymentMethod>(
                      value: PaymentMethod.cardPayment,
                      groupValue: selectedPayment,
                      onChanged: (val) =>
                          setState(() => selectedPayment = val!),
                    ),
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
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
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
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.home),
                  label: const Text("Home"),
                  onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RecipeHomeScreen()),
                      (route) => false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: Text(isPlacingOrder ? "Processing..." : "Place Order"),
                  onPressed: isPlacingOrder
                      ? null
                      : () async {
                          if (addressController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Enter an address")));
                            return;
                          }

                          setState(() => isPlacingOrder = true);

                          try {
                            if (selectedPayment == PaymentMethod.cardPayment) {
                              bool success = await payWithCard(
                                  context, appState.totalPrice);
                              if (!success) {
                                setState(() => isPlacingOrder = false);
                                return;
                              }
                            }
                            await placeOrder(appState);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: $e")));
                          } finally {
                            setState(() => isPlacingOrder = false);
                          }
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> placeOrder(ApplicationState appState) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();
    final userData = userDoc.data();

    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("orders")
        .add({
      "items": appState.cartItems
          .map(
              (e) => {"name": e.name, "price": e.price, "quantity": e.quantity})
          .toList(),
      "address": addressController.text.trim(),
      "paymentMethod": selectedPayment.name,
      "paymentStatus": selectedPayment == PaymentMethod.cardPayment
          ? "Paid"
          : "Cash on Delivery",
      "total": appState.totalPrice,
      "status": "Pending",
      "createdAt": FieldValue.serverTimestamp(),
      "userId": user.uid,
      "email": userData?['email'] ?? user.email,
      "displayName": userData?['displayName'] ?? '',
    });

    appState.clearCart();
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order placed successfully!")));
    Navigator.pop(context);
  }
}
