import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart' as ui;
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'recipe_homescreen.dart';
import 'complete_profile.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ApplicationState>();

    // 🔓 Logged in & email verified → App access
    // 🔓 Logged in, verified, profile complete
    if (appState.isLoggedIn &&
        appState.isEmailVerified &&
        appState.isProfileComplete) {
      return const RecipeHomeScreen();
    }

    // 🧾 Profile incomplete → force completion
    if (appState.isLoggedIn &&
        appState.isEmailVerified &&
        !appState.isProfileComplete) {
      return const CompleteProfileScreen();
    }

    // 📧 Logged in but NOT verified → Force verification
    if (appState.isLoggedIn && !appState.isEmailVerified) {
      return ui.EmailVerificationScreen(
        actions: [
          // Rebuild happens automatically via ApplicationState.reloadUser()
          ui.EmailVerifiedAction(() async {
            await context.read<ApplicationState>().reloadUser();
          }),

          // User cancels → sign out
          ui.AuthCancelledAction((context) async {
            await context.read<ApplicationState>().signOut();
          }),
        ],
      );
    }

    // 🔐 Not logged in → Register / Login
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // 1️⃣ Background image
              Positioned.fill(
                child: Image.asset(
                  'assets/ib_recipes.jpg',
                  fit: BoxFit.cover,
                ),
              ),

              // 2️⃣ Dark overlay
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.45),
                ),
              ),

              // 3️⃣ Centered login card
              Center(
                child: ConstrainedBox(
                  // Constrain max width and height for SignInScreen
                  constraints: BoxConstraints(
                    maxWidth: 400, // optional for wide screens
                    maxHeight: constraints.maxHeight * 0.9,
                  ),
                  child: Card(
                    elevation: 12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: ui.SignInScreen(
                        providers: [
                          ui.EmailAuthProvider(),
                        ],
                        showAuthActionSwitch: true,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
