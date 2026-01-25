import 'package:flutter/material.dart';
import 'recipe.dart';

class RecipeDetailsScreen extends StatelessWidget {
  const RecipeDetailsScreen({required this.recipe, super.key});

  final Recipe recipe;

  static const double _appBarElevation = 2;
  static const double _padding = 12.0;
  static const double _imageBorderRadius = 8.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.name),
        backgroundColor: Colors.green,
        elevation: _appBarElevation,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(_padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.all(
                  Radius.circular(_imageBorderRadius),
                ),
                child: Image.asset(
                  recipe.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 650,
                ),
              ),
              const SizedBox(height: _padding),
              Text(
                recipe.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: _padding),
              Text(
                'Ingredients:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...recipe.ingredients.map(
                (ingredient) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ${ingredient.name}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '  ${ingredient.description}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
