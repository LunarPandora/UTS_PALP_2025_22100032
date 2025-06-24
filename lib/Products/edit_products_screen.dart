import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

class ProductEditPage extends StatefulWidget {
  final DocumentReference productRef;
  final Map<String, dynamic> productData;

  const ProductEditPage({
    super.key,
    required this.productRef,
    required this.productData,
  });

  @override
  _ProductEditPageState createState() => _ProductEditPageState();
}

class _ProductEditPageState extends State<ProductEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.productData['name'] ?? '';
    _priceController.text = widget.productData['price'] ?? '';
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate() ||
        _nameController.text.isEmpty ||
        _priceController.text.isEmpty) return;

    final box = Hive.box('stores');
    final storePath = box.get('code');
    if (storePath == null) return;

    await widget.productRef.update({
      'name': _nameController.text.trim(),
      'price': _priceController.text.trim(),
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Product')),
      body: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Nama Product'),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),

                    SizedBox(height: 10),

                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(labelText: 'Product Prices'),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),

                    SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: _updateProduct,
                      child: Text('Save Product'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.all(20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // Set your desired radius here
                        ),
                        backgroundColor: Colors.green.shade800,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
