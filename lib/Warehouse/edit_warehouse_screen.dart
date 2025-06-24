import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

class WarehouseEditPage extends StatefulWidget {
  final DocumentReference warehouseRef;
  final Map<String, dynamic> warehouseData;

  const WarehouseEditPage({
    super.key,
    required this.warehouseRef,
    required this.warehouseData,
  });

  @override
  _WarehouseEditPageState createState() => _WarehouseEditPageState();
}

class _WarehouseEditPageState extends State<WarehouseEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.warehouseData['name'] ?? '';
  }

  Future<void> _updateWarehouse() async {
    if (!_formKey.currentState!.validate() ||
        _nameController.text.isEmpty) return;

    final box = Hive.box('stores');
    final storePath = box.get('code');
    if (storePath == null) return;

    await widget.warehouseRef.update({
      'name': _nameController.text.trim(),
      'createdAt': FieldValue.serverTimestamp()
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Warehouse')),
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
                      onPressed: _updateWarehouse,
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
