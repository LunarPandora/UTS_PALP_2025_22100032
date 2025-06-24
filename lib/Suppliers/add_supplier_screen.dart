import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

class SupplierFormPage extends StatefulWidget {
  @override
  _SupplierFormPageState createState() => _SupplierFormPageState();
}

class _SupplierFormPageState extends State<SupplierFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  Future<void> _submitSupplier() async {
    if (!_formKey.currentState!.validate() ||
        _nameController.text.isEmpty) return;

    final box = Hive.box('stores');
    final storePath = box.get('code');
    if (storePath == null) return;

    final storeRef = FirebaseFirestore.instance.collection('stores').doc(storePath);

    final supplierData = {
      'name': _nameController.text.trim(),
      'store_ref': storeRef,
      'createdAt': FieldValue.serverTimestamp()
    };

    final supplierDoc = await FirebaseFirestore.instance
        .collection('suppliers')
        .add(supplierData);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tambah Supplier baru')),
      body: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Nama Supplier'),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),

                    SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: _submitSupplier,
                      child: Text('Save Supplier'),
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
