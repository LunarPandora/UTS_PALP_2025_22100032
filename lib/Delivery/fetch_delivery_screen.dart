import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import 'add_delivery_screen.dart';
// import 'edit_delivery_screen.dart';

import 'package:intl/intl.dart';

final rupiahFormat = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);

class FetchDeliveriesScreen extends StatelessWidget {
  final box = Hive.box('stores');

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance.collection('stores').doc(box.get('code'));
    final delivery = FirebaseFirestore.instance.collection(
      'deliveries',
    ).where('store_ref', isEqualTo: ref);

    return Scaffold(
      appBar: AppBar(title: Text("History Pengantaran")),
      body: StreamBuilder<QuerySnapshot>(
        stream: delivery.snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Belum ada catatan."));
          }

          return ListView(
            children:
                snapshot.data!.docs.map((DocumentSnapshot document) {
                  final data = document.data()! as Map<String, dynamic>;
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(data['no_form'] ?? '-'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Harga total: ${rupiahFormat.format(data["grandtotal"])}'),
                        ]
                      ),
                      trailing:
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            data['synced'] == true
                              ? Icon(Icons.cloud_done, color: Colors.green)
                              : Icon(Icons.cloud_off, color: Colors.grey),
                            IconButton(
                              hoverColor: Colors.transparent,
                              onPressed: () { 
                                // Navigator.push(
                                //   context,
                                //   MaterialPageRoute(builder: (context) => DeliveryEditPage(
                                //     receiptRef: document.reference,
                                //     receiptData: data,
                                //   ))
                                // );
                              },
                              icon: Icon(Icons.edit, color: Colors.yellow.shade800)
                            ),
                            IconButton(
                              hoverColor: Colors.transparent,
                              onPressed: () async {
                                bool confirm = await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Hapus catatan'),
                                    content: Text('Apakah anda yakin ingin menghapus receipt ini?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: Text('Batal'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: Text('Hapus'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm) {
                                  await FirebaseFirestore.instance
                                    .collection('deliveries')
                                    .doc(document.id)
                                    .delete();
                                }
                              }, 
                              icon: Icon(Icons.delete, color: Colors.red.shade500)
                            )
                          ]
                        )
                          
                    ),
                  );
                }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DeliveryFormPage())
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}