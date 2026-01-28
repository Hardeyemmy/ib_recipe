import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApplicationState extends ChangeNotifier {
  ApplicationState() {
    _init();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  StreamSubscription<User?>? _subscription;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isEmailVerified => _user?.emailVerified ?? false;

  void _init() {
    _subscription = _auth.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<void> sendEmailVerification() async {
    if (_user != null && !_user!.emailVerified) {
      await _user!.sendEmailVerification();
    }
  }

  Future<void> reloadUser() async {
    await _user?.reload();
    _user = _auth.currentUser;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
