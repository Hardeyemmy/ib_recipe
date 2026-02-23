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

  Future<void> placeOrder(appState) async {
    try {
      print("Checkout button pressed");

      final user = FirebaseAuth.instance.currentUser;
      print("Current user: ${user?.uid}");

      if (user == null) {
        print("User is NULL. Cannot place order.");
        return;
      }

      final orderRef = FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("orders");

      print("Writing to path: users/${user.uid}/orders");

      await orderRef.add({
        "status": "Pending",
        "createdAt": FieldValue.serverTimestamp(),
      });

      print("Order successfully saved!");
    } catch (e) {
      print("FULL ERROR: $e");
    }
  }
}
