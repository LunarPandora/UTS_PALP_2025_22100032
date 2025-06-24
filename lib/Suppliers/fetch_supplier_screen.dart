import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import 'add_supplier_screen.dart';
import 'edit_supplier_screen.dart';

class FetchSuppliersScreen extends StatelessWidget {
  final box = Hive.box('stores');

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance.collection('stores').doc(box.get('code'));
    final suppliers = FirebaseFirestore.instance.collection(
      'suppliers',
    ).where('store_ref', isEqualTo: ref);

    return Scaffold(
      appBar: AppBar(title: Text("List Supplier")),
      body: StreamBuilder<QuerySnapshot>(
        stream: suppliers.snapshots(),
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
                      title: Text(data['name'] ?? '-'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['createdAt'] != null
                              ? 'Created at ${data['createdAt'].toDate()}'
                              : 'Created at -'),
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
                                  MaterialPageRoute(builder: (context) => SupplierEditPage(
                                    supplierRef: document.reference,
                                    supplierData: data,
                                  ))
                                );
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
                                    .collection('suppliers')
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
            MaterialPageRoute(builder: (context) => SupplierFormPage())
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}