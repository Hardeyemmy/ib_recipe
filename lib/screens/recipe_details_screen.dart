import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/app_state.dart';
import '/recipe.dart';
import '../cart_item.dart';
import 'cart_screen.dart';
import 'recipe_homescreen.dart';

class RecipeDetailsScreen extends StatefulWidget {
  const RecipeDetailsScreen({required this.recipe, super.key});

  final Recipe recipe;

  @override
  State<RecipeDetailsScreen> createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  int quantity = 1; // Local quantity for this recipe

  static const double _appBarElevation = 2;
  static const double _padding = 12.0;
  static const double _imageBorderRadius = 8.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.recipe.name),
          backgroundColor: Colors.green,
          elevation: _appBarElevation,
          actions: [
            Consumer<ApplicationState>(
              builder: (context, appState, _) {
                int itemCount = appState.cartItems.fold(
                  0,
                  (sum, item) => sum + item.quantity,
                );

                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CartPage()),
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
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(_padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(_imageBorderRadius),
                child: Image.asset(
                  widget.recipe.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 400,
                ),
              ),
              const SizedBox(height: _padding),
              Text(widget.recipe.description,
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: _padding),
              Text(
                'Ingredients:',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...widget.recipe.ingredients.map((ingredient) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ${ingredient.name}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        Text('  ${ingredient.description}',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  )),
              const SizedBox(height: 100), // space for sticky bottom bar
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.1),
                  blurRadius: 10,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quantity Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (quantity > 1) setState(() => quantity--);
                      },
                    ),
                    Text(
                      quantity.toString(),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        setState(() => quantity++);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Home and Add to Cart buttons with equal spacing
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.home),
                          label: const Text('Home'),
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RecipeHomeScreen()),
                              (route) => false,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<ApplicationState>().addToCart(
                                  CartItem(
                                    recipeId: widget.recipe.id,
                                    name: widget.recipe.name,
                                    price: widget.recipe.price.toDouble(),
                                    quantity: quantity,
                                  ),
                                );

                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  '$quantity x ${widget.recipe.name} added to cart!'),
                              duration: const Duration(seconds: 2),
                            ));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: Text(
                              'Add to Cart - ₦${widget.recipe.price * quantity}',
                              style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
  }
}
