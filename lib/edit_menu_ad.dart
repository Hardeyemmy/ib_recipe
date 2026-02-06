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
    priceController =
        TextEditingController(text: data['price']?.toString() ?? '');
    descriptionController =
        TextEditingController(text: data['description'] ?? '');
  }

  // 🔥 Update Menu Item
  Future<void> updateMenuItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('menu')
          .doc(widget.doc.id)
          .update({
        'name': nameController.text.trim(),
        'price': double.parse(priceController.text.trim()),
        'description': descriptionController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Menu updated successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: $e")),
      );
    }

    setState(() => isLoading = false);
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
      appBar: AppBar(
        title: const Text("Edit Menu Item"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 🍲 Name
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Menu Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter menu name" : null,
              ),

              const SizedBox(height: 16),

              // 💰 Price
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Price (₦)",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Enter price";
                  }
                  if (double.tryParse(value) == null) {
                    return "Enter valid number";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 📝 Description
              TextFormField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 30),

              // 💾 Update Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : updateMenuItem,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          "Update Menu Item",
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
