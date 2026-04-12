import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

class AddMenuItemScreen extends StatefulWidget {
  const AddMenuItemScreen({super.key});

  @override
  State<AddMenuItemScreen> createState() => _AddMenuItemScreenState();
}

class _AddMenuItemScreenState extends State<AddMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController imageController = TextEditingController();

  bool isLoading = false;
  String? _selectedImageName;
  Uint8List? _imageBytes;

  // List to store ingredients with name and description
  List<Map<String, String>> ingredients = [];
  TextEditingController ingredientNameController = TextEditingController();
  TextEditingController ingredientDescController = TextEditingController();

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
                imageController.text = file.name;
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

  // 🔥 Add Menu Item to Firestore
  Future<void> addMenuItem() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      final price = int.tryParse(priceController.text.trim()) ?? 0;

      // Use selected image name or default, ensure it has assets/ prefix
      String imageUrl = _selectedImageName ?? 'default_recipe.jpg';
      if (!imageUrl.startsWith('assets/')) {
        imageUrl = 'assets/$imageUrl';
      }

      await FirebaseFirestore.instance.collection('recipes').add({
        'name': nameController.text.trim(),
        'description': descriptionController.text.trim(),
        'price': price,
        'createdAt': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
        'ingredients': ingredients,
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
      appBar: AppBar(title: const Text('Add New Recipe')),
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
                      'Added Ingredients:',
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
                label: const Text('Pick Image from Device'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : addMenuItem,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Add Recipe'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
