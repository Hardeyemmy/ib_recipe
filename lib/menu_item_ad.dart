import 'package:cloud_firestore/cloud_firestore.dart';

class AddMenuItemScreen {
  Future<void> addMenuItem({
    required String name,
    required double price,
    required String description,
  }) async {
    await FirebaseFirestore.instance.collection('menu').add({
      'name': name,
      'price': price,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
