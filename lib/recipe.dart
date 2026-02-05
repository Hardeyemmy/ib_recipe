import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  final String id;
  final String name;
  final String imageUrl;
  final String description;
  final List<Ingredient> ingredients;

  Recipe({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.ingredients,
  });

  /// 🔄 Convert Recipe to Firestore map
  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Recipe(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      ingredients: (data['ingredients'] as List? ?? [])
          .map((i) => Ingredient(
                name: i['name'],
                description: i['description'],
              ))
          .toList(),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
      'ingredients': ingredients.map((i) => i.toMap()).toList(),
    };
  }
}

class Ingredient {
  final String name;
  final String description;

  Ingredient({
    required this.name,
    required this.description,
  });

  /// 🔄 Convert Ingredient to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
    };
  }
}
