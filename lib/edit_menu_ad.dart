import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'dart:html' as html;

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
  String? _selectedImageName;
  Uint8List? _imageBytes;
  String? _currentImageUrl;

  // List to store ingredients with name and description
  List<Map<String, String>> ingredients = [];
  TextEditingController ingredientNameController = TextEditingController();
  TextEditingController ingredientDescController = TextEditingController();

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
    _currentImageUrl = data['imageUrl'] ?? '';

    // Load existing ingredients
    final existingIngredients = data['ingredients'] as List<dynamic>? ?? [];
    ingredients = existingIngredients
        .map((ing) => {
              'name': ing['name']?.toString() ?? '',
              'description': ing['description']?.toString() ?? '',
            })
        .toList();
  }

  // 🖼️ Pick image from device using HTML file input
  Future<void> _pickImage() async {
    try {
      final html.FileUploadInputElement uploadInput =
          html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((e) async {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final file = files[0];
          final reader = html.FileReader();
          reader.readAsArrayBuffer(file);

          reader.onLoadEnd.listen((e) {
            if (mounted) {
              setState(() {
                _imageBytes = reader.result as Uint8List;
                _selectedImageName = file.name;
              });
            }
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  // 🔥 Update Menu Item
  Future<void> updateMenuItem() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      final price = int.tryParse(priceController.text.trim()) ?? 0;

      // Use new image path if selected, otherwise keep current
      final imageUrl = _selectedImageName ?? _currentImageUrl ?? '';

      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(widget.doc.id)
          .update({
        'name': nameController.text.trim(),
        'description': descriptionController.text.trim(),
        'price': price,
        'imageUrl': imageUrl,
        'ingredients': ingredients,
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
    ingredientNameController.dispose();
    ingredientDescController.dispose();
    super.dispose();
  }

  // Add ingredient to list
  void _addIngredient() {
    if (ingredientNameController.text.isEmpty ||
        ingredientDescController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill ingredient name and description')),
      );
      return;
    }

    setState(() {
      ingredients.add({
        'name': ingredientNameController.text.trim(),
        'description': ingredientDescController.text.trim(),
      });
      ingredientNameController.clear();
      ingredientDescController.clear();
    });
  }

  // Remove ingredient from list
  void _removeIngredient(int index) {
    setState(() {
      ingredients.removeAt(index);
    });
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
              const SizedBox(height: 16),
              // Ingredients Section
              const Text(
                'Ingredients',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: ingredientNameController,
                decoration: const InputDecoration(labelText: 'Ingredient Name'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: ingredientDescController,
                decoration:
                    const InputDecoration(labelText: 'Ingredient Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _addIngredient,
                icon: const Icon(Icons.add),
                label: const Text('Add Ingredient'),
              ),
              const SizedBox(height: 12),
              // Display added ingredients
              if (ingredients.isNotEmpty)
                Column(
                  children: [
                    const Text(
                      'Ingredients:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ingredients.length,
                      itemBuilder: (context, index) {
                        final ingredient = ingredients[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(ingredient['name'] ?? ''),
                            subtitle: Text(ingredient['description'] ?? ''),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeIngredient(index),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              const SizedBox(height: 16),
              // Image Preview & Picker
              if (_imageBytes != null)
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _imageBytes!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Pick New Image'),
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
