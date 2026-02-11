import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart' as ui;
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'complete_profile.dart';
import 'recipe_homescreen.dart';
import 'admin_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ApplicationState>();

    // Admins should get the admin dashboard first
    if (appState.isLoggedIn && appState.isAdmin) {
      return const AdminDashboard();
    }

    // Logged in & email verified & profile complete → App access
    if (appState.isLoggedIn &&
        appState.isEmailVerified &&
        appState.isProfileComplete) {
      return const RecipeHomeScreen();
    }

    // Profile incomplete → force completion
    if (appState.isLoggedIn &&
        appState.isEmailVerified &&
        !appState.isProfileComplete) {
      return const CompleteProfileScreen();
    }

    // Logged in but NOT verified → Force verification
    if (appState.isLoggedIn && !appState.isEmailVerified) {
      return ui.EmailVerificationScreen(
        actions: [
          ui.EmailVerifiedAction(() async {
            await context.read<ApplicationState>().reloadUser();
          }),
          ui.AuthCancelledAction((context) async {
            await context.read<ApplicationState>().signOut();
          }),
        ],
      );
    }

    // 🔐 Not logged in → Show SignInScreen with Glassmorphism
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

              // 2️⃣ Dark overlay (optional, makes text pop)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withAlpha(90), // 0.35 * 255 = 90
                ),
              ),

              // 3️⃣ Centered Glassmorphism Card
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 400,
                    maxHeight: constraints.maxHeight * 0.9,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(0), // 0.2 * 255 = 51
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.white.withAlpha(0), // 0.3 * 255 = 77
                          ),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            scaffoldBackgroundColor: Colors.transparent,
                            cardColor: Colors.white.withAlpha(20),
                            colorScheme: Theme.of(context).colorScheme.copyWith(
                                  surface: Colors.white.withAlpha(0),
                                ),
                            dialogTheme: const DialogThemeData(
                              backgroundColor: Colors.white,
                            ),
                          ),
                          child: ui.SignInScreen(
                            providers: [ui.EmailAuthProvider()],
                            showAuthActionSwitch: true,
                          ),
                        ),
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
