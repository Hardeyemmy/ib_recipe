import 'package:flutter/material.dart';
import 'recipe.dart';
import 'recipe_card.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ib Recipe App',
      home: RecipeHomeScreen(),
    );
  }
}

class RecipeHomeScreen extends StatelessWidget {
  RecipeHomeScreen({super.key});
  final List<Recipe> recipes = [
    Recipe(
        name: 'Spaghetti Cabanaro',
        imageUrl: 'menu1.jpg',
        description: 'A classic Italian pasta dish with a rich tomato sauce.'),
    Recipe(
        name: 'Abula',
        imageUrl: 'menu2.jpg',
        description:
            'A traditional Nigerian dish made with beans and vegetables.'),
    Recipe(
        name: 'Iyan and Egusi',
        imageUrl: 'menu3.jpg',
        description:
            'A popular Nigerian meal consisting of pounded yam and melon seed soup'),
    Recipe(
        name: 'Jollof Rice',
        imageUrl: 'menu4.jpg',
        description:
            'A beloved West African dish made with rice, tomatoes, and spices.'),
    Recipe(
        name: 'Moimoi and Custard',
        imageUrl: 'menu5.jpg',
        description:
            'A traditional Nigerian snack made with beans pudding and served with custard.'),
    Recipe(
        name: 'Banga Soup and Starch',
        imageUrl: 'menu6.jpg',
        description:
            'A traditional Nigerian soup made with banga and served with starch.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Ib Recipe App',
            style: TextStyle(color: Colors.purpleAccent),
            textAlign: TextAlign.justify,
          ),
          backgroundColor: Colors.black,
        ),
        body: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              return RecipeCard(recipe: recipes[index]);
            }));
  }
}
