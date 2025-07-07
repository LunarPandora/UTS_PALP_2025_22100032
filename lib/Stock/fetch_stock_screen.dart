import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';

final rupiahFormat = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);

class WarehouseStockPage extends StatelessWidget {
  final DocumentReference warehouseRef;

  const WarehouseStockPage({super.key, required this.warehouseRef});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('stores');
    final storeRef = FirebaseFirestore.instance.collection('stores').doc(box.get('code'));

    return Scaffold(
      appBar: AppBar(title: const Text('Stok Gudang')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stock')
            .where('warehouse_ref', isEqualTo: warehouseRef)
            .where('store_ref', isEqualTo: storeRef)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Tidak ada stok ditemukan.'));
          }

          final stocks = snapshot.data!.docs;

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchProductDetails(stocks),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final stockData = snapshot.data!;

              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTableTheme(
                        data: DataTableThemeData(
                          headingRowColor: WidgetStateProperty.resolveWith<Color?>(
                            (states) => Colors.blue.shade700
                          ),
                          headingTextStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold
                          )
                        ),
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Produk')),
                            DataColumn(label: Text('Unit')),
                            DataColumn(label: Text('Stok')),
                          ],
                          rows: stockData.map((data) {
                            return DataRow(cells: [
                              DataCell(Text(data['name'] ?? '-')),
                              DataCell(Text(data['unit'] ?? '-')),
                              DataCell(Text('${data['stock']}')),
                            ]);
                          }).toList(),
                        ),
                      )
                    )
                  );
                }
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchProductDetails(
    List<QueryDocumentSnapshot> stocks,
  ) async {
    List<Map<String, dynamic>> result = [];

    for (var stock in stocks) {
      try {
        final productRef = stock['product_ref'];
        if (productRef is! DocumentReference) {
          print('Invalid productRef: $productRef');
          continue;
        }

        final productSnap = await productRef.get();
        final productData = productSnap.data() as Map<String, dynamic>?;

        if (productData == null) {
          print('Product not found for ref: $productRef');
          continue;
        }

        result.add({
          'name': productData['name'] ?? '-',
          'unit': productData['unit'] ?? '-',
          'stock': stock['stock'] ?? 0,
        });
      } catch (e, stack) {
        print('Error fetching product details: $e');
        print(stack);
        continue;
      }
    }

    return result;
  }
}
