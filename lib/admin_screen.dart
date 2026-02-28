import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'menu_item_ad.dart';
import 'edit_menu_ad.dart';
import 'recipe_homescreen.dart';
import 'responsive.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    final pages = [
      _buildAdminPanel(),
      const RecipeHomeScreen(),
    ];

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text("Admin Dashboard"),
            ),

      drawer: isDesktop ? null : _buildDrawer(),

      body: Row(
        children: [
          // 💻 DESKTOP NAVIGATION RAIL
          if (isDesktop)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.admin_panel_settings_outlined),
                  selectedIcon: Icon(Icons.admin_panel_settings),
                  label: Text("Admin"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text("Home"),
                ),
              ],
            ),

          // MAIN CONTENT
          Expanded(
            child: pages[_selectedIndex],
          ),
        ],
      ),

      // 📱 MOBILE BOTTOM NAV
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.admin_panel_settings),
                  label: "Admin",
                ),
                NavigationDestination(
                  icon: Icon(Icons.home),
                  label: "Home",
                ),
              ],
            ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            child: Center(
              child: Text(
                "Admin Dashboard",
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text("Admin"),
            selected: _selectedIndex == 0,
            onTap: () {
              setState(() => _selectedIndex = 0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Home"),
            selected: _selectedIndex == 1,
            onTap: () {
              setState(() => _selectedIndex = 1);
              Navigator.pop(context);
            },
          ),
        ],
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
  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Unknown";

    if (timestamp is Timestamp) {
      final date = timestamp.toDate();

      return "${date.day}/${date.month}/${date.year} "
          "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    }

    return "Unknown";
  }

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
                title: Text(data['displayName'] ?? "Unknown"),
                subtitle: Text(
                  "Total: ₦${data['total'] ?? 0} | Status: ${data['status'] ?? 'Pending'} | Time Of Order: ${formatTimestamp(data['createdAt']) ?? 'Unknown'}",
                ),
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
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Status Buttons
                        ...['Pending', 'Confirmed', 'Delivered', 'Cancelled']
                            .map((status) {
                          return ElevatedButton(
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
                          );
                        }).toList(),

                        // 🔥 DELETE BUTTON
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Delete Order"),
                                content: const Text(
                                    "Are you sure you want to delete this order? This action cannot be undone."),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text("Delete"),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userId)
                                  .collection('orders')
                                  .doc(orderDoc.id)
                                  .delete();
                            }
                          },
                          child: const Text("Delete"),
                        ),
                      ],
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
