import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

class MutasiBarangApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mutasi Barang',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MutationPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MutationPage extends StatefulWidget {
  @override
  _MutationPageState createState() => _MutationPageState();
}

class _MutationPageState extends State<MutationPage> {
  final box = Hive.box('stores');

  // final List<String> items = ['Barang A', 'Barang B', 'Barang C'];
  // final List<String> warehouses = ['Gudang 1', 'Gudang 2', 'Gudang 3'];

  DocumentReference? selectedItem;
  DocumentReference? fromWarehouse;
  DocumentReference? toWarehouse;

  List<DocumentSnapshot> items = [];
  List<DocumentSnapshot> warehouses = [];

  final TextEditingController quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final ref = FirebaseFirestore.instance.collection('stores').doc(box.get('code'));
    
    final item = await FirebaseFirestore.instance.collection('products').where('store_ref', isEqualTo: ref).get();
    final warehouse = await FirebaseFirestore.instance.collection('warehouses').where('store_ref', isEqualTo: ref).get();

    setState(() {
      warehouses = warehouse.docs;
      items = item.docs;
    });
  }

  void submitMutation() async {
    if (selectedItem == null || fromWarehouse == null || toWarehouse == null || quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mohon lengkapi semua data')),
      );
      return;
    }

    if (fromWarehouse == toWarehouse) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gudang asal dan tujuan tidak boleh sama')),
      );
      return;
    }

    final int? qty = int.tryParse(quantityController.text);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Jumlah harus angka yang valid')),
      );
      return;
    }

    final storeRef = FirebaseFirestore.instance.collection('stores').doc(box.get('code'));

    try {
      // Get current stock from source warehouse
      final fromStockQuery = await FirebaseFirestore.instance.collection('stock')
          .where('store_ref', isEqualTo: storeRef)
          .where('product_ref', isEqualTo: selectedItem)
          .where('warehouse_ref', isEqualTo: fromWarehouse)
          .get();

      if (fromStockQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stok tidak ditemukan di gudang asal')),
        );
        return;
      }

      final fromStockDoc = fromStockQuery.docs.first;
      final fromStockRef = fromStockDoc.reference;
      final currentStock = fromStockDoc['stock'] ?? 0;

      if (currentStock < qty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stok di gudang asal tidak mencukupi')),
        );
        return;
      }

      // Update source warehouse stock
      await fromStockRef.update({'stock': currentStock - qty});

      // Update or create stock in destination warehouse
      final toStockQuery = await FirebaseFirestore.instance.collection('stock')
          .where('store_ref', isEqualTo: storeRef)
          .where('product_ref', isEqualTo: selectedItem)
          .where('warehouse_ref', isEqualTo: toWarehouse)
          .get();

      if (toStockQuery.docs.isNotEmpty) {
        final toStockDoc = toStockQuery.docs.first;
        final toStockRef = toStockDoc.reference;
        final currentToStock = toStockDoc['stock'] ?? 0;
        await toStockRef.update({'stock': currentToStock + qty});
      } else {
        await FirebaseFirestore.instance.collection('stock').add({
          'store_ref': storeRef,
          'product_ref': selectedItem,
          'warehouse_ref': toWarehouse,
          'stock': qty,
        });
      }

      // Optional: Log mutation (recommended for tracking)
      await FirebaseFirestore.instance.collection('mutations').add({
        'store_ref': storeRef,
        'product_ref': selectedItem,
        'from_warehouse': fromWarehouse,
        'to_warehouse': toWarehouse,
        'qty': qty,
        'created_at': FieldValue.serverTimestamp(),
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mutasi berhasil dilakukan')),
      );

      // Reset form
      setState(() {
        selectedItem = null;
        fromWarehouse = null;
        toWarehouse = null;
        quantityController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mutasi Barang')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            DropdownButtonFormField<DocumentReference>(
              decoration: InputDecoration(labelText: 'Pilih Barang'),
              value: selectedItem,
              items: items.map((doc) {
                return DropdownMenuItem(
                  value: doc.reference,
                  child: Text(doc['name']),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedItem = value),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<DocumentReference>(
              decoration: InputDecoration(labelText: 'Gudang Asal'),
              value: fromWarehouse,
              items: warehouses.map((wh) {
                return DropdownMenuItem(value: wh.reference, child: Text(wh['name']));
              }).toList(),
              onChanged: (value) => setState(() => fromWarehouse = value),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<DocumentReference>(
              decoration: InputDecoration(labelText: 'Gudang Tujuan'),
              value: toWarehouse,
              items: warehouses.map((wh) {
                return DropdownMenuItem(value: wh.reference, child: Text(wh['name']));
              }).toList(),
              onChanged: (value) => setState(() => toWarehouse = value),
            ),
            SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Jumlah'),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: submitMutation,
              child: Text('Kirim Mutasi'),
            ),
          ],
        ),
      ),
    );
  }
}