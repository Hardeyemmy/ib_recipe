import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view orders')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final orders = snapshot.data?.docs ?? [];

          if (orders.isEmpty) {
            return const Center(
              child: Text(
                'No orders yet',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              final items = order['items'] as List<dynamic>? ?? [];
              final total = order['total'] as double? ?? 0.0;
              final status = order['status'] as String? ?? 'Unknown';
              final createdAt = order['createdAt'] as Timestamp?;
              final address = order['address'] as String? ?? '';
              final paymentMethod = order['paymentMethod'] as String? ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${orders[index].id.substring(0, 8)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: status == 'Pending'
                                  ? Colors.orange
                                  : status == 'Completed'
                                      ? Colors.green
                                      : Colors.grey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (createdAt != null)
                        Text(
                          'Ordered on: ${createdAt.toDate().toString().split(' ')[0]}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      const SizedBox(height: 12),
                      const Text(
                        'Items:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      ...items.map((item) {
                        final itemData = item as Map<String, dynamic>;
                        final name = itemData['name'] as String? ?? '';
                        final quantity = itemData['quantity'] as int? ?? 0;
                        final price = itemData['price'] as double? ?? 0.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('$name x$quantity'),
                              Text('₦${(price * quantity).toStringAsFixed(2)}'),
                            ],
                          ),
                        );
                      }),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '₦${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Payment: $paymentMethod'),
                      if (address.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Address: $address'),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
