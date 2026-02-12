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

    // 🔓 Admin
    if (appState.isLoggedIn && appState.isAdmin) {
      return const AdminDashboard();
    }

    // 🔓 Normal user
    if (appState.isLoggedIn &&
        appState.isEmailVerified &&
        appState.isProfileComplete) {
      return const RecipeHomeScreen();
    }

    // 🧾 Complete profile
    if (appState.isLoggedIn &&
        appState.isEmailVerified &&
        !appState.isProfileComplete) {
      return const CompleteProfileScreen();
    }

    // 📧 Email verification
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

    // 🔐 NOT LOGGED IN → Your custom background login screen
    return Scaffold(
      body: Stack(
        children: [
          // 1️⃣ Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/ib_recipes.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // 2️⃣ Dark Overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withAlpha(90),
            ),
          ),

          // 3️⃣ Glass Card with SignInScreen
          // 3️⃣ Centered Logo + Glassmorphism Card
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ App Logo

                  const SizedBox(height: 20),

                  // ✅ Glass Card
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 400,
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(40),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.white.withAlpha(80),
                            ),
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              scaffoldBackgroundColor: Colors.transparent,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
