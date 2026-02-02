import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:provider/provider.dart';
import 'package:ib_recipe/auth.dart';
import 'recipe.dart';
import 'recipe_card.dart';
import 'firebase_options.dart';
import 'app_state.dart';
import 'profileedit_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseUIAuth.configureProviders([EmailAuthProvider()]);
  runApp(ChangeNotifierProvider(
    create: (_) => ApplicationState(),
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ApplicationState(),
      child: MaterialApp(
        title: 'Ib Recipe App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class RecipeHomeScreen extends StatelessWidget {
  RecipeHomeScreen({super.key});
  final List<Recipe> recipes = [
    Recipe(
      id: '0',
      name: 'Spaghetti Cabanaro',
      imageUrl: 'menu1.jpg',
      description: 'A classic Italian pasta dish with a rich tomato sauce.',
      ingredients: [
        Ingredient(name: 'Spaghetti', description: 'Long, thin pasta'),
        Ingredient(
            name: 'Tomato sauce', description: 'Rich tomato-based sauce'),
        Ingredient(name: 'Cheese', description: 'Grated Parmesan'),
        Ingredient(name: 'Basil', description: 'Fresh herb'),
      ],
    ),
    Recipe(
      id: '1',
      name: 'Abula',
      imageUrl: 'menu2.jpg',
      description:
          'A traditional Nigerian dish made with beans and vegetables.',
      ingredients: [
        Ingredient(name: 'Beans', description: 'Cooked black-eyed beans'),
        Ingredient(name: 'Vegetables', description: 'Mixed veggies'),
        Ingredient(name: 'Spices', description: 'Traditional Nigerian spices'),
        Ingredient(name: 'Palm oil', description: 'Red palm oil'),
      ],
    ),
    Recipe(
      id: '2',
      name: 'Iyan and Egusi',
      imageUrl: 'menu3.jpg',
      description:
          'A popular Nigerian meal consisting of pounded yam and melon seed soup',
      ingredients: [
        Ingredient(
          name: 'White Yam',
          description:
              'Fresh yam peeled, boiled, and pounded to make smooth iyan (pounded yam)',
        ),
        Ingredient(
          name: 'Egusi (Melon Seeds)',
          description:
              'Ground melon seeds used as the main thickener for egusi soup',
        ),
        Ingredient(
            name: 'Palm Oil',
            description:
                'Red palm oil that gives egusi soup its rich color and flavor'),
        Ingredient(
            name: 'Assorted Meat',
            description:
                'Beef, goat meat, shaki, or stockfish used to enrich the soup'),
        Ingredient(
          name: 'Leafy Vegetables',
          description:
              'Bitter leaf or ugu (pumpkin leaf) added for taste and nutrition',
        ),
      ],
    ),
    Recipe(
      id: '3',
      name: 'Jollof Rice',
      imageUrl: 'menu4.jpg',
      description:
          'A beloved West African dish made with rice, tomatoes, and spices.',
      ingredients: [
        Ingredient(
          name: 'Rice',
          description: 'Long-grain rice used as the main base for jollof rice',
        ),
        Ingredient(
          name: 'Tomatoes',
          description: 'Blended fresh tomatoes that form the jollof sauce base',
        ),
        Ingredient(
          name: 'Red Bell Pepper',
          description: 'Adds sweetness, color, and flavor to the jollof sauce',
        ),
        Ingredient(
          name: 'Onions',
          description: 'Used for frying and seasoning to enhance flavor',
        ),
        Ingredient(
          name: 'Spices and Seasoning',
          description:
              'Includes curry powder, thyme, bay leaf, and seasoning cubes',
        ),
      ],
    ),
    Recipe(
      id: '4',
      name: 'Moimoi and Custard',
      imageUrl: 'menu5.jpg',
      description:
          'A traditional Nigerian snack made with beans pudding and served with custard.',
      ingredients: [
        Ingredient(
          name: 'Custard Powder',
          description: 'Cornstarch-based powder used to make custard',
        ),
        Ingredient(
          name: 'Milk',
          description: 'Adds creaminess and richer taste',
        ),
        Ingredient(
          name: 'Sugar',
          description: 'Sweetens the custard',
        ),
        Ingredient(
          name: 'Water',
          description: 'Used to dissolve and cook the custard',
        ),
        Ingredient(
          name: 'Vanilla Flavor',
          description: 'Enhances aroma and taste',
        ),
      ],
    ),
    Recipe(
      id: '5',
      name: 'Banga Soup and Starch',
      imageUrl: 'menu6.jpg',
      description:
          'A traditional Nigerian soup made with banga and served with starch.',
      ingredients: [
        Ingredient(
          name: 'Starch Powder',
          description: 'Processed cassava starch used as the main ingredient',
        ),
        Ingredient(
          name: 'Water',
          description: 'Used to dissolve and cook the starch',
        ),
        Ingredient(
          name: 'Palm Oil',
          description:
              'Gives starch its characteristic yellow color and flavor',
        ),
        Ingredient(
          name: 'Salt',
          description: 'Added lightly to enhance taste',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Welcome, ${context.watch<ApplicationState>().displayName ?? 'User'}'),
        backgroundColor: Colors.green,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<ApplicationState>().signOut();
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EditProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        padding: const EdgeInsets.all(8),
        itemCount: recipes.length,
        itemBuilder: (context, index) => RecipeCard(recipe: recipes[index]),
      ),
    );
  }
}
