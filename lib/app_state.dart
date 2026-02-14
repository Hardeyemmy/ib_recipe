import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'recipe.dart';
import 'cart_item.dart';

class ApplicationState extends ChangeNotifier {
  ApplicationState() {
    _init();
  }

  // 🔐 Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 👤 Auth user
  User? _user;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _profileSubscription;

  // 📄 Profile
  DocumentSnapshot<Map<String, dynamic>>? _profile;
  bool _profileLoading = true;
  String _role = 'user';

  // GETTERS

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isEmailVerified => _user?.emailVerified ?? false;

  bool get isProfileLoading => _profileLoading;
  DocumentSnapshot<Map<String, dynamic>>? get profile => _profile;
  String? get photoUrl => _profile?.data()?['photoUrl'];
  bool get isAdmin => _role == 'admin';

  final List<CartItem> _cartItems = [];
  List<CartItem> get cartItems => _cartItems;
//add to cart
  void addToCart(CartItem item) {
    final index = _cartItems.indexWhere((e) => e.recipeId == item.recipeId);
    if (index >= 0) {
      _cartItems[index].quantity++;
    } else {
      _cartItems.add(item);
    }

    notifyListeners();
  }

//remove from cart
  void removeFromCart(String recipeId) {
    _cartItems.removeWhere((item) => item.recipeId == recipeId);
    notifyListeners();
  }

  //clear cart
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  double get cartTotal {
    return _cartItems.fold(
        0.0, (sumUp, item) => sumUp + (item.price * item.quantity));
  }

  int getItemQuantity(String recipeId) {
    final index = _cartItems.indexWhere((item) => item.recipeId == recipeId);

    if (index >= 0) {
      return _cartItems[index].quantity;
    }

    return 0;
  }

  double get totalPrice {
    double total = 0.0;

    for (var item in _cartItems) {
      total += item.price * item.quantity;
    }

    return total;
  }

  void increaseQuantity(String recipeId) {
    final index = _cartItems.indexWhere((item) => item.recipeId == recipeId);

    if (index >= 0) {
      _cartItems[index].quantity++;
      notifyListeners();
    }
  }

  void decreaseQuantity(String recipeId) {
    final index = _cartItems.indexWhere((item) => item.recipeId == recipeId);

    if (index >= 0) {
      if (_cartItems[index].quantity > 1) {
        _cartItems[index].quantity--;
      } else {
        _cartItems.removeAt(index);
      }
      notifyListeners();
    }
  }

  /// 👋 This is what your UI uses
  String? get displayName => _profile?.data()?['displayName'];

  bool get isProfileComplete {
    final name = displayName;
    return name != null && name.trim().isNotEmpty;
  }

  // INIT

  void _init() {
    _authSubscription = _auth.authStateChanges().listen((user) async {
      _user = user;

      // Clean up old listeners
      await _profileSubscription?.cancel();
      _profile = null;
      _profileLoading = true;

      if (user != null) {
        await _createProfileIfNotExists(user);
        _listenToProfile(user.uid);
      } else {
        _profileLoading = false;
      }

      notifyListeners();
    });
  }

  Future<void> addRecipesBatch(List<Recipe> recipes) async {
    if (_user == null) return;

    final batch = _firestore.batch();
    final recipesRef = _firestore.collection('recipes');

    for (final recipe in recipes) {
      final docRef = recipesRef.doc();

      batch.set(docRef, {
        ...recipe.toMap(),
        'createdBy': _user!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // PROFILE LISTENER

  void _listenToProfile(String uid) {
    _profileSubscription =
        _firestore.collection('users').doc(uid).snapshots().listen(
      (doc) {
        _profile = doc;
        _profileLoading = false;
        // Update role from profile document so UI can react to admin changes
        try {
          final roleValue = doc.data()?['role'];
          _role = roleValue is String ? roleValue : _role;
        } catch (_) {
          // ignore and keep existing role
        }

        notifyListeners();
      },
      onError: (e) {
        debugPrint('Profile listener error: $e');
        _profileLoading = false;
      },
    );
  }

  // PROFILE CREATION

  Future<void> _createProfileIfNotExists(User user) async {
    final ref = _firestore.collection('users').doc(user.uid);

    try {
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        await ref.set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName ?? 'New User',
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Web/offline safe
      debugPrint('Firestore offline, profile creation deferred');
    }
  }

  // ✏️ EDIT PROFILE

  Future<void> updateDisplayName(String name) async {
    if (_user == null) return;

    await _firestore.collection('users').doc(_user!.uid).update({
      'displayName': name.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // EMAIL VERIFICATION

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

  Future<void> loadUserRole(String uid) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    _role = doc.data()?['role'];
    notifyListeners();
  }

  // SIGN OUT

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // DISPOSE

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }
}
