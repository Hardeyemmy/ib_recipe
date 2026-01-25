import 'package:flutter/material.dart';
import 'recipe.dart';
import 'recipe_card.dart';

class RecipeDetailsScreen extends StatelessWidget {
  const RecipeDetailsScreen({required this.recipe, super.key});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.name),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                recipe.imageUrl,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 12.0),
              const Text('Ingredients: '),
              Text(recipe.description),
            ],
          ),
        ),
      ),
    );
  }
}
