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

// ================= ORDERS TAB =================
class AdminOrdersTab extends StatelessWidget {
  const AdminOrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data!.docs;

        if (orders.isEmpty) {
          return const Center(child: Text("No orders yet."));
        }

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final data = order.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.all(10),
              child: ListTile(
                title: Text(data['recipeName'] ?? ''),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Customer: ${data['customerName'] ?? ''}"),
                    Text("Phone: ${data['phone'] ?? ''}"),
                    Text("Address: ${data['address'] ?? ''}"),
                    Text("Quantity: ${data['quantity'] ?? ''}"),
                    Text("Status: ${data['status'] ?? 'Pending'}"),
                  ],
                ),

                // ORDER STATUS CONTROL
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    FirebaseFirestore.instance
                        .collection('orders')
                        .doc(order.id)
                        .update({'status': value});
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'Confirmed',
                      child: Text('Confirm'),
                    ),
                    PopupMenuItem(
                      value: 'Delivered',
                      child: Text('Mark Delivered'),
                    ),
                    PopupMenuItem(
                      value: 'Cancelled',
                      child: Text('Cancel'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
