import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final _users = FirebaseFirestore.instance.collection('users');

  Future<void> createProfileIfNotExists(User user) async {
    final doc = _users.doc(user.uid);

    if (!(await doc.get()).exists) {
      await doc.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? 'New User',
        'photoUrl': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<DocumentSnapshot> profileStream(String uid) {
    return _users.doc(uid).snapshots();
  }
}
