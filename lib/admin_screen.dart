import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'menu_item_ad.dart';
import 'edit_menu_ad.dart';
import 'recipe_homescreen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildAdminPanel(),
      const RecipeHomeScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  // ================= ADMIN PANEL WITH TABS =================
  Widget _buildAdminPanel() {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Admin Panel"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Recipes"),
              Tab(text: "Orders"),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddMenuItemScreen(),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
        body: const TabBarView(
          children: [
            AdminRecipesTab(),
            AdminOrdersTab(),
          ],
        ),
      ),
    );
  }
}

// ================= RECIPES TAB =================
class AdminRecipesTab extends StatelessWidget {
  const AdminRecipesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('recipes').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(
            child: Text("No recipes. Tap + to add one."),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final dataMap = doc.data() as Map<String, dynamic>? ?? {};
            final name = dataMap['name'] ?? 'Unknown';
            final price = dataMap['price'] ?? dataMap['Price'] ?? 0;

            return ListTile(
              title: Text(name),
              subtitle: Text("₦$price"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // EDIT
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditMenuItemScreen(doc: doc),
                        ),
                      );
                    },
                  ),

                  // DELETE
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('recipes')
                          .doc(doc.id)
                          .delete();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class AdminOrdersTab extends StatelessWidget {
  const AdminOrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('orders')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No orders yet."));
        }

        final orders = snapshot.data!.docs;

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final orderDoc = orders[index];
            final data = orderDoc.data() as Map<String, dynamic>;

            final userId = orderDoc.reference.parent.parent?.id ?? 'Unknown';
            final items = (data['items'] as List<dynamic>? ?? []);

            return Card(
              margin: const EdgeInsets.all(10),
              child: ExpansionTile(
                title: Text("User: $userId"),
                subtitle: Text(
                    "Total: ₦${data['total'] ?? 0} | Status: ${data['status'] ?? 'Pending'}"),
                children: [
                  // Show each item in the order
                  ...items.map((item) {
                    final itemMap = item as Map<String, dynamic>;
                    return ListTile(
                      title: Text(itemMap['name'] ?? ''),
                      subtitle: Text("Qty: ${itemMap['quantity'] ?? 0}"),
                      trailing: Text("₦${itemMap['price'] ?? 0}"),
                    );
                  }),

                  // Delivery address & payment
                  ListTile(
                    title: Text("Address: ${data['address'] ?? 'N/A'}"),
                    subtitle:
                        Text("Payment: ${data['paymentMethod'] ?? 'N/A'}"),
                  ),

                  // Status update buttons
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        'Pending',
                        'Confirmed',
                        'Delivered',
                        'Cancelled'
                      ].map((status) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: ElevatedButton(
                            onPressed: () {
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userId)
                                  .collection('orders')
                                  .doc(orderDoc.id)
                                  .update({'status': status});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: statusColor(status),
                            ),
                            child: Text(status),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper: color based on status
  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}
