import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

class WarehouseFormPage extends StatefulWidget {
  @override
  _WarehouseFormPageState createState() => _WarehouseFormPageState();
}

class _WarehouseFormPageState extends State<WarehouseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  Future<void> _submitWarehouse() async {
    if (!_formKey.currentState!.validate() ||
        _nameController.text.isEmpty) return;

    final box = Hive.box('stores');
    final storePath = box.get('code');
    if (storePath == null) return;

    final storeRef = FirebaseFirestore.instance.collection('stores').doc(storePath);

    final warehouseData = {
      'name': _nameController.text.trim(),
      'store_ref': storeRef,
      'createdAt': FieldValue.serverTimestamp()
    };

    final warehouseDoc = await FirebaseFirestore.instance
        .collection('warehouses')
        .add(warehouseData);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tambah Warehouse baru')),
      body: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Nama Warehouse'),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),

                    SizedBox(height: 16),
                    
                    ElevatedButton(
                      onPressed: _submitWarehouse,
                      child: Text('Save Warehouse'),
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
