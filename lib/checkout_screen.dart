import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_state.dart';

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

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<ApplicationState>(context);
    final cartItems = appState.cartItems;

    double totalPrice = cartItems.fold(
      0,
      (sumUp, item) => sumUp + (item.price * item.quantity),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout"),
      ),
      body: cartItems.isEmpty
          ? const Center(
              child: Text(
                "Your cart is empty",
                style: TextStyle(fontSize: 18),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  /// ORDER SUMMARY
                  const Text(
                    "Order Summary",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Column(
                    children: cartItems.map((item) {
                      return Card(
                        child: ListTile(
                          title: Text(item.name),
                          subtitle: Text("Qty: ${item.quantity}"),
                          trailing: Text(
                            "₦${item.price * item.quantity}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  /// DELIVERY ADDRESS
                  const Text(
                    "Delivery Address",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: addressController,
                    decoration: InputDecoration(
                      hintText: "Enter delivery address",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// PAYMENT METHOD

                  const Text(
                    "Payment Method",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  RadioGroup<PaymentMethod>(
                    groupValue: selectedPayment,
                    onChanged: (PaymentMethod? value) {
                      if (value != null) {
                        setState(() {
                          selectedPayment = value;
                        });
                      }
                    },
                    child: const Column(
                      children: [
                        RadioListTile<PaymentMethod>(
                          value: PaymentMethod.cashOnDelivery,
                          title: Text("Cash on Delivery"),
                        ),
                        RadioListTile<PaymentMethod>(
                          value: PaymentMethod.cardPayment,
                          title: Text("Card Payment"),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// TOTAL
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "₦$totalPrice",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  /// PLACE ORDER BUTTON
                  ElevatedButton(
                    onPressed:
                        isPlacingOrder ? null : () => placeOrder(appState),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isPlacingOrder
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            "Place Order",
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> placeOrder(ApplicationState appState) async {
    try {
      setState(() {
        isPlacingOrder = true;
      });

      final user = FirebaseAuth.instance.currentUser;

      // 🔐 Authentication Check
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("You must be logged in to place an order.")),
        );
        return;
      }

      // 🛒 Cart Check
      if (appState.cartItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Your cart is empty.")),
        );
        return;
      }

      // 📍 Address Check
      if (addressController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter delivery address.")),
        );
        return;
      }

      // 💰 Calculate Total
      double totalPrice = appState.cartItems.fold(
        0,
        (sumUp, item) => sumUp + (item.price * item.quantity),
      );

      // 🧾 Convert Cart Items
      final orderItems = appState.cartItems.map((item) {
        return {
          "name": item.name,
          "price": item.price,
          "quantity": item.quantity,
        };
      }).toList();

      // 🔥 GET USER PROFILE FROM FIRESTORE (Reliable Source)
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      final userData = userDoc.data();

      final displayName = userData?['displayName'] ?? '';
      final email = userData?['email'] ?? user.email ?? '';

      // 📝 SAVE ORDER
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("orders")
          .add({
        "items": orderItems,
        "address": addressController.text.trim(),
        "paymentMethod": selectedPayment.name,
        "total": totalPrice,
        "status": "Pending",
        "createdAt": FieldValue.serverTimestamp(),

        // 🔥 Guaranteed profile data
        "email": email,
        "displayName": displayName,
        "userId": user.uid,
      });

      // 🧹 Clear Cart
      appState.clearCart();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order placed successfully!")),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );
    } catch (e) {
      print("FULL ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to place order: $e")),
      );
    } finally {
      setState(() {
        isPlacingOrder = false;
      });
    }
  }
}
