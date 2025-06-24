import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:intl/intl.dart';

final rupiahFormat = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);

class ReceiptEditPage extends StatefulWidget {
  final DocumentReference receiptRef;
  final Map<String, dynamic> receiptData;

  const ReceiptEditPage({
    super.key,
    required this.receiptRef,
    required this.receiptData,
  });

  @override
  State<ReceiptEditPage> createState() => _ReceiptEditPageState();
}

class _ReceiptEditPageState extends State<ReceiptEditPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _formNumberController = TextEditingController();

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
    _formNumberController.text = widget.receiptData['no_form'] ?? '';
    _supplierRef = widget.receiptData['supplier_ref'];
    _warehouseRef = widget.receiptData['warehouse_ref'];
    _loadData();
  }

  Future<void> _loadData() async {
    final suppliersSnapshot = await FirebaseFirestore.instance.collection('suppliers').get();
    final warehousesSnapshot = await FirebaseFirestore.instance.collection('warehouses').get();
    final productsSnapshot = await FirebaseFirestore.instance.collection('products').get();
    final detailSnapshot = await widget.receiptRef.collection('details').get();

    setState(() {
      _suppliers = suppliersSnapshot.docs;
      _warehouses = warehousesSnapshot.docs;
      _products = productsSnapshot.docs;
      _details.clear();
      for (var doc in detailSnapshot.docs) {
        _details.add(_ProductDetail.fromFirestore(doc.data(), _products, doc.reference));
      }
    });
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate() ||
        _supplierRef == null ||
        _warehouseRef == null ||
        _details.isEmpty) return;

    await widget.receiptRef.update({
      'no_form': _formNumberController.text.trim(),
      'supplier_ref': _supplierRef,
      'warehouse_ref': _warehouseRef,
      'item_total': _totalItems,
      'grandtotal': _totalPrice,
      'updated_at': DateTime.now(),
    });

    final detailsCollection = widget.receiptRef.collection('details');
    final existingDetails = await detailsCollection.get();
    for (var doc in existingDetails.docs) {
      await doc.reference.delete();
    }
    for (var detail in _details) {
      await detailsCollection.add(detail.toMap());
    }

    if (mounted) Navigator.pop(context, 'updated');
  }

  void _addDetailRow() {
    setState(() => _details.add(_ProductDetail(products: _products)));
  }

  void _removeDetailRow(int index) {
    setState(() => _details.removeAt(index));
  }

  Future<void> _promptDeleteReceipt() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Konfirmasi'),
        content: Text('Yakin ingin menghapus receipt ini? Semua detail akan ikut terhapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final detailDocs = await widget.receiptRef.collection('details').get();
    for (var doc in detailDocs.docs) {
      await doc.reference.delete();
    }

    await widget.receiptRef.delete();
    await FirebaseFirestore.instance
        .collection('purchaseGoodsReceipts')
        .doc(widget.receiptRef.id)
        .delete();

    if (mounted) Navigator.pop(context, 'deleted');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Receipt')),
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
                      decoration: InputDecoration(labelText: 'No. Form'),
                      validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<DocumentReference>(
                      value: _supplierRef,
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
                      value: _warehouseRef,
                      items: _warehouses.map((doc) {
                        return DropdownMenuItem(
                          value: doc.reference,
                          child: Text(doc['name']),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _warehouseRef = val),
                      decoration: InputDecoration(labelText: 'Warehouse'),
                      validator: (val) => val == null ? 'Pilih warehouse' : null,
                    ),
                    SizedBox(height: 24),
                    Text("Detail Produk", style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    ..._details.asMap().entries.map((entry) {
                      final idx = entry.key;
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
                                onChanged: (val) {
                                  setState(() {
                                    detail.productRef = val;
                                    detail.unitName = val!.id == '1' ? 'pcs' : 'dus';
                                  });
                                },
                                decoration: InputDecoration(labelText: "Produk"),
                                validator: (val) => val == null ? 'Pilih produk' : null,
                              ),
                              SizedBox(height: 10),
                              TextFormField(
                                initialValue: detail.price.toString(),
                                decoration: InputDecoration(labelText: "Harga"),
                                keyboardType: TextInputType.number,
                                onChanged: (val) {
                                  setState(() => detail.price = int.tryParse(val) ?? 0);
                                },
                                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                              ),
                              SizedBox(height: 10),
                              TextFormField(
                                initialValue: detail.qty.toString(),
                                decoration: InputDecoration(labelText: "Jumlah"),
                                keyboardType: TextInputType.number,
                                onChanged: (val) {
                                  setState(() => detail.qty = int.tryParse(val) ?? 1);
                                },
                                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                              ),
                              SizedBox(height: 8),
                              Text("Satuan  : ${detail.unitName}"),
                              Text("Subtotal: ${rupiahFormat.format(detail.subtotal)}"),
                              SizedBox(height: 4),
                              TextButton.icon(
                                onPressed: () => _removeDetailRow(idx),
                                icon: Icon(Icons.delete, color: Colors.white),
                                label: Text("Hapus Produk"),
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
                      onPressed: _addDetailRow,
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
                    Text("Item Total: $_totalItems"),
                    Text("Grand Total: ${rupiahFormat.format(_totalPrice)}"),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitUpdate,
                      child: Text('Update'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.all(20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // Set your desired radius here
                        ),
                        backgroundColor: Colors.yellow.shade900,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _promptDeleteReceipt,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.all(20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // Set your desired radius here
                        ),
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Delete'),
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
  final DocumentReference? docRef;

  _ProductDetail({
    this.productRef,
    this.price = 0,
    this.qty = 1,
    this.unitName = 'unit',
    required this.products,
    this.docRef,
  });

  factory _ProductDetail.fromFirestore(Map<String, dynamic> data, List<DocumentSnapshot> products, DocumentReference ref) {
    return _ProductDetail(
      productRef: data['product_ref'],
      price: data['price'],
      qty: data['qty'],
      unitName: data['unit_name'] ?? 'unit',
      products: products,
      docRef: ref,
    );
  }

  int get subtotal => price * qty;

  Map<String, dynamic> toMap() {
    return {
      'product_ref': productRef,
      'price': price,
      'qty': qty,
      'unit_name': unitName,
      'subtotal': subtotal,
    };
  }
}
