import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditMenuItemScreen extends StatefulWidget {
  final DocumentSnapshot doc;

  const EditMenuItemScreen({
    super.key,
    required this.doc,
  });

  @override
  State<EditMenuItemScreen> createState() => _EditMenuItemScreenState();
}

class _EditMenuItemScreenState extends State<EditMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController descriptionController;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    final data = widget.doc.data() as Map<String, dynamic>;

    nameController = TextEditingController(text: data['name'] ?? '');
    priceController = TextEditingController(
      text: (data['price'] != null) ? data['price'].toString() : '',
    );
    descriptionController =
        TextEditingController(text: data['description'] ?? '');
  }

  // 🔥 Update Menu Item
  Future<void> updateMenuItem() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      final price = int.tryParse(priceController.text.trim()) ?? 0;
      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(widget.doc.id)
          .update({
        'name': nameController.text.trim(),
        'description': descriptionController.text.trim(),
        'price': price,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Recipe')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Recipe Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter description' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price (₦)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter price';
                  if (int.tryParse(value) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : updateMenuItem,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Update Recipe'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
