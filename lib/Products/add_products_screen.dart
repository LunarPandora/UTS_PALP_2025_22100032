import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

class ProductFormPage extends StatefulWidget {
  @override
  _ProductFormPageState createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate() ||
        _nameController.text.isEmpty ||
        _priceController.text.isEmpty) return;

    final box = Hive.box('stores');
    final storePath = box.get('code');
    if (storePath == null) return;

    final storeRef = FirebaseFirestore.instance.collection('stores').doc(storePath);

    final productsData = {
      'name': _nameController.text.trim(),
      'price': _priceController.text.trim(),
      'qty': 0,
      'store_ref': storeRef,
      'createdAt': FieldValue.serverTimestamp()
    };

    final productsDoc = await FirebaseFirestore.instance
        .collection('products')
        .add(productsData);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tambah Product baru')),
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
                      onPressed: _submitProduct,
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
