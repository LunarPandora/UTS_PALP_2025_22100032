import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import 'package:intl/intl.dart';

final rupiahFormat = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);

class DeliveryFormPage extends StatefulWidget {
  @override
  _DeliveryFormPageState createState() => _DeliveryFormPageState();
}

class _DeliveryFormPageState extends State<DeliveryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _deliveriesNumberController = TextEditingController();

  final box = Hive.box('stores');

  DocumentReference? _selectedSupplierRef;
  DocumentReference? _selectedWarehouseRef;

  List<DocumentSnapshot> _supplierList = [];
  List<DocumentSnapshot> _warehouseList = [];
  List<DocumentSnapshot> _productList = [];

  final List<_ProductEntry> _deliveriesItems = [];

  int get totalItems => _deliveriesItems.fold(0, (sum, item) => sum + item.quantity);
  int get totalCost => _deliveriesItems.fold(0, (sum, item) => sum + item.subtotal);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final ref = FirebaseFirestore.instance.collection('stores').doc(box.get('code'));
    
    final suppliers = await FirebaseFirestore.instance.collection('suppliers').where('store_ref', isEqualTo: ref).get();
    final warehouses = await FirebaseFirestore.instance.collection('warehouses').where('store_ref', isEqualTo: ref).get();
    final products = await FirebaseFirestore.instance.collection('products').where('store_ref', isEqualTo: ref).get();

    setState(() {
      _supplierList = suppliers.docs;
      _warehouseList = warehouses.docs;
      _productList = products.docs;
    });
  }

  void _addProductEntry() {
    setState(() {
      _deliveriesItems.add(_ProductEntry(availableProducts: _productList));
    });
  }

  void _removeProductEntry(int index) {
    setState(() {
      _deliveriesItems.removeAt(index);
    });
  }

  Future<void> _submitDelivery() async {
    if (!_formKey.currentState!.validate() ||
        _selectedSupplierRef == null ||
        _selectedWarehouseRef == null ||
        _deliveriesItems.isEmpty) return;

    final box = Hive.box('stores');
    final storePath = box.get('code');
    if (storePath == null) return;

    final storeRef = FirebaseFirestore.instance.collection('stores').doc(storePath);

    final deliveriesData = {
      'no_form': _deliveriesNumberController.text.trim(),
      'grandtotal': totalCost,
      'item_total': totalItems,
      'post_date': DateTime.now().toIso8601String(),
      'created_at': DateTime.now(),
      'store_ref': storeRef,
      'supplier_ref': _selectedSupplierRef,
      'warehouse_ref': _selectedWarehouseRef,
      'synced': true,
    };

    final deliveriesDoc = await FirebaseFirestore.instance
        .collection('deliveries')
        .add(deliveriesData);

    for (final product in _deliveriesItems) {
      await deliveriesDoc.collection('details').add(product.toMap());
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tambah Delivery baru')),
      body: _productList.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _deliveriesNumberController,
                      decoration: InputDecoration(labelText: 'Delivery Number'),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<DocumentReference>(
                      items: _supplierList.map((doc) {
                        return DropdownMenuItem(
                          value: doc.reference,
                          child: Text(doc['name']),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedSupplierRef = value),
                      decoration: InputDecoration(labelText: "Supplier"),
                      validator: (value) => value == null ? 'Select a supplier' : null,
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<DocumentReference>(
                      items: _warehouseList.map((doc) {
                        return DropdownMenuItem(
                          value: doc.reference,
                          child: Text(doc['name']),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedWarehouseRef = value),
                      decoration: InputDecoration(labelText: "Warehouse"),
                      validator: (value) => value == null ? 'Select a warehouse' : null,
                    ),
                    SizedBox(height: 24),
                    Text("Product Details", style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    ..._deliveriesItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final product = entry.value;
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<DocumentReference>(
                                value: product.productRef,
                                items: _productList.map((doc) {
                                  return DropdownMenuItem(
                                    value: doc.reference,
                                    child: Text(doc['name']),
                                  );
                                }).toList(),
                                onChanged: (value) => setState(() {
                                  product.productRef = value;
                                  product.unit = value!.id == '1' ? 'pcs' : 'box';
                                }),
                                decoration: InputDecoration(labelText: "Product"),
                                validator: (value) => value == null ? 'Select a product' : null,
                              ),
                              SizedBox(height: 10),
                              TextFormField(
                                initialValue: product.price.toString(),
                                decoration: InputDecoration(labelText: "Price"),
                                keyboardType: TextInputType.number,
                                onChanged: (val) => setState(() {
                                  product.price = int.tryParse(val) ?? 0;
                                }),
                                validator: (val) => val!.isEmpty ? 'Required' : null,
                              ),
                              SizedBox(height: 10),
                              TextFormField(
                                initialValue: product.quantity.toString(),
                                decoration: InputDecoration(labelText: "Quantity"),
                                keyboardType: TextInputType.number,
                                onChanged: (val) => setState(() {
                                  product.quantity = int.tryParse(val) ?? 1;
                                }),
                                validator: (val) => val!.isEmpty ? 'Required' : null,
                              ),
                              SizedBox(height: 8),
                              Text("Unit: ${product.unit}"),
                              Text("Subtotal: ${rupiahFormat.format(product.subtotal)}"),
                              SizedBox(height: 4),
                              TextButton.icon(
                                onPressed: () => _removeProductEntry(index),
                                icon: Icon(Icons.delete, color: Colors.white),
                                label: Text("Hapus produk"),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.all(20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10), // Set your desired radius here
                                  ),
                                  backgroundColor: Colors.red.shade700,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    ElevatedButton.icon(
                      onPressed: _addProductEntry,
                      icon: Icon(Icons.add),
                      label: Text('Tambah Produk'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.all(20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // Set your desired radius here
                        ),
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text("Total Items: $totalItems"),
                    Text("Total Cost: ${rupiahFormat.format(totalCost)}"),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitDelivery,
                      child: Text('Save Delivery'),
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

class _ProductEntry {
  DocumentReference? productRef;
  int price = 0;
  int quantity = 1;
  String batchNumber = "1";
  String unit = 'unit';
  final List<DocumentSnapshot> availableProducts;

  _ProductEntry({required this.availableProducts});

  int get subtotal => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'product_ref': productRef,
      'price': price,
      'qty': quantity,
      'unit_name': unit,
      'subtotal': subtotal,
      'batch_number': batchNumber
    };
  }
}
