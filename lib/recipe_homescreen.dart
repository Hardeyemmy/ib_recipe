import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'profileedit_screen.dart';
import 'cart_page.dart';
import 'recipe_card.dart';
import 'recipe.dart';
import 'responsive.dart';

class RecipeHomeScreen extends StatefulWidget {
  const RecipeHomeScreen({super.key});

  @override
  State<RecipeHomeScreen> createState() => _RecipeHomeScreenState();
}

class _RecipeHomeScreenState extends State<RecipeHomeScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    int crossAxisCount;

    if (Responsive.isMobile(context)) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 3;
    }

    return Scaffold(
      appBar: _buildAppBar(context),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: _buildRecipeGrid(crossAxisCount),
        ),
      ),
    );
  }

  // ✅ MOVE THIS INSIDE
  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      toolbarHeight: 110,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF2E7D32),
              Color(0xFF66BB6A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/ib_logo.jpg',
                  height: 34,
                  width: 34,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "IB Recipes",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 🔍 SEARCH
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Search recipes...",
                hintStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.search, color: Colors.white),
                border: InputBorder.none,
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ],
      ),
      actions: [
        _buildCartButton(context),
      ],
    );
  }

  // ✅ ALSO MOVE THIS INSIDE
  Widget _buildCartButton(BuildContext context) {
    return Consumer<ApplicationState>(
      builder: (context, appState, _) {
        int itemCount = appState.cartItems.fold(
          0,
          (sumUp, item) => sumUp + item.quantity,
        );

        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CartPage(),
                  ),
                );
              },
            ),
            if (itemCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    itemCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ✅ ALSO MOVE THIS INSIDE
  Widget _buildRecipeGrid(int crossAxisCount) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('recipes').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allRecipes = snapshot.data!.docs
            .map((doc) => Recipe.fromFirestore(doc))
            .toList();

        final filteredRecipes = allRecipes.where((recipe) {
          return recipe.name.toLowerCase().contains(searchQuery);
        }).toList();

        if (filteredRecipes.isEmpty) {
          return const Center(child: Text("No recipes found"));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredRecipes.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) =>
              RecipeCard(recipe: filteredRecipes[index]),
        );
      },
    );
  }
}
