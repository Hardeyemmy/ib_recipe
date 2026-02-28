import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:ib_recipe/admin_screen.dart';
import 'package:ib_recipe/recipe_details.dart';
import 'package:ib_recipe/recipe_homescreen.dart';
import 'package:provider/provider.dart';
import 'package:ib_recipe/auth.dart';
import 'firebase_options.dart';
import 'app_state.dart';

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
        debugShowCheckedModeBanner: false,
        title: 'Ib Recipe App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthGate(),
          '/dashboard': (context) => const AdminDashboard(),
          '/home': (context) => const RecipeHomeScreen(),
        },
      ),
    );
  }
}
