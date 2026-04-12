import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:ib_recipe/screens/admin_screen.dart';
import 'package:ib_recipe/screens/recipe_homescreen.dart';
import 'package:ib_recipe/screens/checkout_screen.dart';
import 'package:provider/provider.dart';
import 'package:ib_recipe/auth.dart';
import 'firebase_options.dart';
import 'app_state.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file only on non-web platforms
  if (!kIsWeb) {
    await dotenv.load(fileName: ".env");
  }

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ib Recipe App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
        ),
      ),
      home: const AuthGate(),
      routes: {
        '/dashboard': (context) => const AdminDashboard(),
        '/home': (context) => const RecipeHomeScreen(),
        '/checkout': (context) => const CheckoutPage(),
      },
    );
  }
}
