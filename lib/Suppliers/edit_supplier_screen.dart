import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

class SupplierEditPage extends StatefulWidget {
  final DocumentReference supplierRef;
  final Map<String, dynamic> supplierData;

  const SupplierEditPage({
    super.key,
    required this.supplierRef,
    required this.supplierData,
  });

  @override
  _SupplierEditPageState createState() => _SupplierEditPageState();
}

class _SupplierEditPageState extends State<SupplierEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.supplierData['name'] ?? '';
  }

  Future<void> _updateSupplier() async {
    if (!_formKey.currentState!.validate() ||
        _nameController.text.isEmpty) return;

    final box = Hive.box('stores');
    final storePath = box.get('code');
    if (storePath == null) return;

    await widget.supplierRef.update({
      'name': _nameController.text.trim(),
      'createdAt': FieldValue.serverTimestamp()
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Supplier')),
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
                      onPressed: _updateSupplier,
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
