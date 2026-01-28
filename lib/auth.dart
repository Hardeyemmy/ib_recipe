import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'main.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ApplicationState>();

    // 🔓 Logged in & email verified
    if (appState.isLoggedIn && appState.isEmailVerified) {
      return RecipeHomeScreen();
    }

    // 📧 Logged in but NOT verified
    if (appState.isLoggedIn && !appState.isEmailVerified) {
      return EmailVerificationScreen(
        actions: [
          EmailVerifiedAction(() {
            // When verified, rebuild → AuthGate sends user to home
          }),
          AuthCancelledAction((context) {
            context.read<ApplicationState>().signOut();
          }),
        ],
      );
    }

    // 🔐 Not logged in → Register / Login
    return SignInScreen(
      providers: [
        EmailAuthProvider(),
      ],
      showAuthActionSwitch: true,
    );
  }
}
