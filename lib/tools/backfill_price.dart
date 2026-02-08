import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> backfillPrices() async {
  final col = FirebaseFirestore.instance.collection('recipes');
  final snap = await col.get();
  for (final doc in snap.docs) {
    final data = doc.data();
    // Only update if Price doesn't exist AND price (lowercase) doesn't exist
    if (!data.containsKey('Price') && !data.containsKey('price')) {
      await doc.reference.update({'Price': 0});
    } else if (data['Price'] is String) {
      final p = int.tryParse(data['Price'] as String) ?? 0;
      await doc.reference.update({'Price': p});
    }
  }
}
