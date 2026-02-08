import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> backfillPrices() async {
  final col = FirebaseFirestore.instance.collection('recipes');
  final snap = await col.get();
  for (final doc in snap.docs) {
    final data = doc.data();
    if (!data.containsKey('price') || data['price'] == null) {
      await doc.reference.update({'price': 0});
    } else if (data['price'] is String) {
      final p = int.tryParse(data['price'] as String) ?? 0;
      await doc.reference.update({'price': p});
    }
  }
}
