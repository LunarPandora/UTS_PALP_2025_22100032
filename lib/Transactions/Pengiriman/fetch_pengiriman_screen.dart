import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import 'add_pengiriman_screen.dart';
import 'edit_pengiriman_screen.dart';

import 'package:intl/intl.dart';

final rupiahFormat = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);

class FetchPengirimanScreen extends StatelessWidget {
  final box = Hive.box('stores');

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance.collection('stores').doc(box.get('code'));
    final pengirimans = FirebaseFirestore.instance.collection(
      'outgoingReceipts',
    ).where('store_ref', isEqualTo: ref);

    return Scaffold(
      appBar: AppBar(title: Text("History Pesanan")),
      body: StreamBuilder<QuerySnapshot>(
        stream: pengirimans.snapshots(),
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => PengirimanEditPage(
                                    pengirimanRef: document.reference,
                                    pengirimanData: data,
                                  ))
                                );
                              },
                              icon: Icon(Icons.edit, color: Colors.yellow.shade800)
                            ),
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
            MaterialPageRoute(builder: (context) => PengirimanFormPage())
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}