import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

final rupiahFormat = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);

class PengirimanFormPage extends StatefulWidget {
  const PengirimanFormPage({super.key});

  @override
  State<PengirimanFormPage> createState() => _PengirimanFormPageState();
}

class _PengirimanFormPageState extends State<PengirimanFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _formNumberController = TextEditingController();
  final box = Hive.box('stores');

  DocumentReference? _supplierRef;
  DocumentReference? _warehouseRef;

  List<DocumentSnapshot> _suppliers = [];
  List<DocumentSnapshot> _warehouses = [];
  List<DocumentSnapshot> _products = [];
  final List<_ProductDetail> _details = [];

  int get _totalItems => _details.fold(0, (sum, item) => sum + item.qty);
  int get _totalPrice => _details.fold(0, (sum, item) => sum + item.subtotal);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final storeRef = FirebaseFirestore.instance.collection('stores').doc(box.get('code'));
    final suppliersSnapshot = await FirebaseFirestore.instance
        .collection('suppliers')
        .where('store_ref', isEqualTo: storeRef)
        .get();
    final warehousesSnapshot = await FirebaseFirestore.instance
        .collection('warehouses')
        .where('store_ref', isEqualTo: storeRef)
        .get();
    final productsSnapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('store_ref', isEqualTo: storeRef)
        .get();

    setState(() {
      _suppliers = suppliersSnapshot.docs;
      _warehouses = warehousesSnapshot.docs;
      _products = productsSnapshot.docs;
    });
  }

  Future<void> _submitPengiriman() async {
    final storeRef = FirebaseFirestore.instance.collection('stores').doc(box.get('code'));

    if (!_formKey.currentState!.validate() || _supplierRef == null || _warehouseRef == null || _details.isEmpty) return;

    final now = DateTime.now().toUtc();

    final pengirimanData = {
      'no_form': _formNumberController.text.trim(),
      'supplier_ref': _supplierRef,
      'warehouse_ref': _warehouseRef,
      'item_total': _totalItems,
      'grandtotal': _totalPrice,
      'created_at': now,
      'post_date': now.toIso8601String(),
      'store_ref': storeRef,
      'synced': true,
    };

    final pengirimanRef = await FirebaseFirestore.instance
        .collection('outgoingReceipts')
        .add(pengirimanData);

    for (var detail in _details) {
      if (detail.productRef == null || detail.price <= 0 || detail.qty <= 0) continue;

      await pengirimanRef.collection('details').add(detail.toMap());
      final productRef = detail.productRef;
      final warehouseRef = _warehouseRef;

      final stockQuery = await FirebaseFirestore.instance.collection('stock')
          .where('product_ref', isEqualTo: productRef)
          .where('store_ref', isEqualTo: storeRef)
          .where('warehouse_ref', isEqualTo: warehouseRef)
          .get();

      if (stockQuery.docs.isNotEmpty) {
        final stockRef = stockQuery.docs.first.reference;
        final currentStock = stockQuery.docs.first['stock'] ?? 0;
        final updatedStock = currentStock - detail.qty;
        if (updatedStock >= 0) {
          await stockRef.update({
            'stock': updatedStock,
          });
        }
      } else {
        await FirebaseFirestore.instance.collection('stock').add({
          'product_ref': productRef,
          'store_ref': storeRef,
          'warehouse_ref': warehouseRef,
          'stock': -detail.qty,
        });
      }
    }

    if (mounted) {
      FocusScope.of(context).unfocus();
      Navigator.pop(context);
    }
  }

  void _addDetailRow() {
    setState(() => _details.add(_ProductDetail(products: _products)));
  }

  void _removeDetailRow(int index) {
    setState(() => _details.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tambah Pengiriman')),
      body: _products.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _formNumberController,
                      decoration: InputDecoration(labelText: 'No Pengiriman'),
                      validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<DocumentReference>(
                      items: _suppliers.map((doc) {
                        return DropdownMenuItem(
                          value: doc.reference,
                          child: Text(doc['name']),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _supplierRef = val),
                      decoration: InputDecoration(labelText: 'Supplier'),
                      validator: (val) => val == null ? 'Pilih supplier' : null,
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<DocumentReference>(
                      items: _warehouses.map((doc) {
                        return DropdownMenuItem(
                          value: doc.reference,
                          child: Text(doc['name']),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _warehouseRef = val),
                      decoration: InputDecoration(labelText: 'Gudang'),
                      validator: (val) => val == null ? 'Pilih gudang' : null,
                    ),
                    SizedBox(height: 24),
                    Text('Detail Produk', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    ..._details.asMap().entries.map((entry) {
                      final index = entry.key;
                      final detail = entry.value;
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<DocumentReference>(
                                value: detail.productRef,
                                items: _products.map((doc) {
                                  return DropdownMenuItem(
                                    value: doc.reference,
                                    child: Text(doc['name']),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() {
                                  detail.productRef = val;
                                  final selected = _products.firstWhere((doc) => doc.reference == val);
                                  detail.unitName = selected['unit'] ?? 'unit';
                                }),
                                decoration: InputDecoration(labelText: 'Produk'),
                                validator: (val) => val == null ? 'Pilih produk' : null,
                              ),
                              SizedBox(height: 10),
                              TextFormField(
                                initialValue: detail.price.toString(),
                                decoration: InputDecoration(labelText: 'Harga'),
                                keyboardType: TextInputType.number,
                                onChanged: (val) => setState(() => detail.price = int.tryParse(val) ?? 0),
                                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                              ),
                              SizedBox(height: 10),
                              TextFormField(
                                initialValue: detail.qty.toString(),
                                decoration: InputDecoration(labelText: 'Jumlah'),
                                keyboardType: TextInputType.number,
                                onChanged: (val) => setState(() => detail.qty = int.tryParse(val) ?? 1),
                                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                              ),
                              SizedBox(height: 4),
                              Text('Unit: ${detail.unitName}'),
                              Text('Subtotal: ${rupiahFormat.format(detail.subtotal)}'),
                              TextButton.icon(
                                onPressed: () => _removeDetailRow(index),
                                icon: Icon(Icons.delete, color: Colors.white),
                                label: Text('Hapus Produk'),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.all(20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
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
                      onPressed: _addDetailRow,
                      icon: Icon(Icons.add),
                      label: Text('Tambah Produk'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.all(20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text("Total Items: $_totalItems"),
                    Text("Total Cost: ${rupiahFormat.format(_totalPrice)}"),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitPengiriman,
                      child: Text('Simpan Pengiriman'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.all(20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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

class _ProductDetail {
  DocumentReference? productRef;
  int price;
  int qty;
  String unitName;
  final List<DocumentSnapshot> products;

  _ProductDetail({
    this.productRef,
    this.price = 0,
    this.qty = 1,
    this.unitName = 'unit',
    required this.products,
  });

  int get subtotal => price * qty;

  Map<String, dynamic> toMap() {
    return {
      'product_ref': productRef,
      'price': price,
      'qty': qty,
      'unit': unitName,
      'subtotal': subtotal,
    };
  }
}