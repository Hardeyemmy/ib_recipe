import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'menu_item_ad.dart';
import 'edit_menu_ad.dart';
import 'tools/backfill_price.dart';
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

  Widget _buildAdminPanel() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel"),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backfilling prices...')),
              );
              await backfillPrices();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backfill complete!')),
              );
            },
          ),
        ],
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('recipes').snapshots(),
        builder: (context, snapshot) {
          print('📊 Connection: ${snapshot.connectionState}');
          print('📊 Has data: ${snapshot.hasData}');
          print('📊 Error: ${snapshot.error}');

          if (snapshot.hasData) {
            print('📊 Recipe count: ${snapshot.data!.docs.length}');
            for (var doc in snapshot.data!.docs) {
              final dataMap = doc.data() as Map<String, dynamic>? ?? {};
              final name = dataMap['name'] ?? 'Unknown';
              final price = dataMap['price'] ?? dataMap['Price'] ?? 0;
              print('📊 Found: $name - ₦$price');
            }
          }

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
      ),
    );
  }
}
