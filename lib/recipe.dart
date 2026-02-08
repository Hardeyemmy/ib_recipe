import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  final String id;
  final String name;
  final String imageUrl;
  final String description;
  final List<Ingredient> ingredients;
  final int price;

  Recipe({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.ingredients,
    required this.price,
  });

  /// 🔄 Convert Recipe from Firestore document
  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Debug: Print all data to see what's in Firestore
    print('🔍 Recipe Data: $data');
    print('🔍 Price Field: ${data['price']}');
    print('🔍 All keys: ${data.keys.toList()}');

    final ingredientsList =
        (data['ingredients'] as List<dynamic>? ?? []).map((ing) {
      final map = ing as Map<String, dynamic>? ?? {};
      return Ingredient(
        name: map['name'] ?? '',
        description: map['description'] ?? '',
      );
    }).toList();

    // Handle price conversion - supports int, num, double, and string formats
    int price = 0;
    // Check for both 'price' and 'Price' (case-insensitive)
    final priceData = data['price'] ?? data['Price'];
    if (priceData != null) {
      if (priceData is int) {
        price = priceData;
      } else if (priceData is num) {
        price = priceData.toInt();
      } else if (priceData is String) {
        price = int.tryParse(priceData) ?? 0;
      }
    }

    return Recipe(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      ingredients: ingredientsList,
      price: price,
    );
  }

  /// 📤 Convert Recipe to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
      'ingredients': ingredients.map((i) => i.toMap()).toList(),
      'price': price,
    };
  }
}

/// 📤 Convert Recipe to Firestore map

class Ingredient {
  final String name;
  final String description;

  Ingredient({
    required this.name,
    required this.description,
  });

  /// 📤 Convert Ingredient to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
    };
  }
}
