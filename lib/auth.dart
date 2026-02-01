import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart' as ui;
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'main.dart';
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
      return RecipeHomeScreen();
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
    return ui.SignInScreen(
      providers: [
        ui.EmailAuthProvider(),
      ],
      showAuthActionSwitch: true,
    );
  }
}
