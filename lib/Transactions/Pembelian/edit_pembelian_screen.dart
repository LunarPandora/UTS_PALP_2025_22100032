import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

final rupiahFormat = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);

class PembelianEditPage extends StatefulWidget {
  final DocumentReference pembelianRef;
  final Map<String, dynamic> pembelianData;
  const PembelianEditPage({
    super.key,
    required this.pembelianRef,
    required this.pembelianData,
  });

  @override
  State<PembelianEditPage> createState() => _PembelianEditPageState();
}

class _PembelianEditPageState extends State<PembelianEditPage> {
  final _formKey = GlobalKey<FormState>();
  final box = Hive.box('stores');
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
    _formNumberController.text = widget.pembelianData['no_form'] ?? '';
    _supplierRef = widget.pembelianData['supplier_ref'];
    _warehouseRef = widget.pembelianData['warehouse_ref'];
    _loadData();
  }

  Future<void> _loadData() async {
    final suppliersSnapshot = await FirebaseFirestore.instance.collection('suppliers').get();
    final warehousesSnapshot = await FirebaseFirestore.instance.collection('warehouses').get();
    final productsSnapshot = await FirebaseFirestore.instance.collection('products').get();
    final detailSnapshot = await widget.pembelianRef.collection('details').get();

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
    final storeRef = FirebaseFirestore.instance.collection('stores').doc(box.get('code'));

    if (!_formKey.currentState!.validate() || _supplierRef == null || _warehouseRef == null || _details.isEmpty) return;

    await widget.pembelianRef.update({
      'no_form': _formNumberController.text.trim(),
      'supplier_ref': _supplierRef,
      'warehouse_ref': _warehouseRef,
      'item_total': _totalItems,
      'grandtotal': _totalPrice,
      'updated_at': DateTime.now(),
    });

    final detailsCollection = widget.pembelianRef.collection('details');
    final existingDetails = await detailsCollection.get();

    // Delete old details and revert their stock
    for (var doc in existingDetails.docs) {
      final productRef = doc['product_ref'];
      final warehouseRef = widget.pembelianData['warehouse_ref'];
      final stockQuery = await FirebaseFirestore.instance.collection('stock')
        .where('product_ref', isEqualTo: productRef)
        .where('store_ref', isEqualTo: storeRef)
        .where('warehouse_ref', isEqualTo: warehouseRef)
        .get();
      if (stockQuery.docs.isNotEmpty) {
        final stockRef = stockQuery.docs.first.reference;
        await stockRef.update({
          'stock': FieldValue.increment(-doc['qty'])
        });
      }
      await doc.reference.delete();
    }

    // Add new details and apply stock changes
    for (var detail in _details) {
      await detailsCollection.add(detail.toMap());
      final productRef = detail.productRef;
      final warehouseRef = _warehouseRef;

      final stockQuery = await FirebaseFirestore.instance.collection('stock')
        .where('product_ref', isEqualTo: productRef)
        .where('store_ref', isEqualTo: storeRef)
        .where('warehouse_ref', isEqualTo: warehouseRef)
        .get();

      if (stockQuery.docs.isNotEmpty) {
        final stockRef = stockQuery.docs.first.reference;
        await stockRef.update({
          'stock': FieldValue.increment(detail.qty),
        });
      } else {
        await FirebaseFirestore.instance.collection('stock').add({
          'product_ref': productRef,
          'store_ref': storeRef,
          'warehouse_ref': warehouseRef,
          'stock': detail.qty,
        });
      }
    }

    if (mounted) Navigator.pop(context, 'updated');
  }

  void _addDetailRow() {
    setState(() => _details.add(_ProductDetail(products: _products)));
  }

  void _removeDetailRow(int index) async {
    final removed = _details.removeAt(index);
    final storeRef = FirebaseFirestore.instance.collection('stores').doc(box.get('code'));
    final warehouseRef = _warehouseRef;

    if (removed.productRef != null && warehouseRef != null) {
      final stockQuery = await FirebaseFirestore.instance.collection('stock')
        .where('product_ref', isEqualTo: removed.productRef)
        .where('store_ref', isEqualTo: storeRef)
        .where('warehouse_ref', isEqualTo: warehouseRef)
        .get();
      if (stockQuery.docs.isNotEmpty) {
        final stockRef = stockQuery.docs.first.reference;
        await stockRef.update({
          'stock': FieldValue.increment(-removed.qty),
        });
      }
    }

    setState(() {});
  }

  Future<void> _promptDeletePembelian() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Konfirmasi'),
        content: Text('Yakin ingin menghapus pembelian ini? Semua detail akan ikut terhapus.'),
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

    if (confirm == true){
      final detailDocs = await widget.pembelianRef.collection('details').get();
      final storeRef = FirebaseFirestore.instance.collection('stores').doc(box.get('code'));

      for (var doc in detailDocs.docs) {
        final warehouseRef = widget.pembelianData['warehouse_ref'];
        final productRef = doc['product_ref'];

        final stock = await FirebaseFirestore.instance.collection('stock')
          .where('product_ref', isEqualTo: productRef)
          .where('store_ref', isEqualTo: storeRef)
          .where('warehouse_ref', isEqualTo: warehouseRef)
          .get();

        if (stock.docs.isNotEmpty) {
          await FirebaseFirestore.instance.collection('stock')
            .doc(stock.docs.first.id)
            .update({
              'stock': stock.docs.first['stock'] - doc['qty']
            });
        }

        await doc.reference.delete();
      }

      await widget.pembelianRef.delete();
      await FirebaseFirestore.instance
        .collection('incomingReceipts')
        .doc(widget.pembelianRef.id)
        .delete();

      if (mounted) Navigator.pop(context, 'deleted');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Pembelian')),
      body: _products.isEmpty ? Center(child: CircularProgressIndicator()) : Padding(
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
                              final selected = _products.firstWhere((d) => d.reference == val);
                              detail.unitName = selected['unit'] ?? 'unit';
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
              Text("Item Total: $_totalItems"),
              Text("Grand Total: ${rupiahFormat.format(_totalPrice)}"),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitUpdate,
                child: Text('Update'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.yellow.shade900,
                  foregroundColor: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _promptDeletePembelian,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
      unitName: data['unit'] ?? 'unit',
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
      'unit': unitName,
      'subtotal': subtotal,
    };
  }
}
