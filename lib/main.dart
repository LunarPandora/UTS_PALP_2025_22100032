import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'fetch_receipts_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );

  await Hive.initFlutter();
  await Hive.openBox('stores');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: CheckScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CheckScreen extends StatelessWidget {
  Future<bool> _checkLogin() async {
    final box = Hive.box('stores');
    return box.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkLogin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return FetchReceiptsScreen();
        } else {
          return LoginScreen();
        }
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>{
  final TextEditingController _nimController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();

  @override
  void dispose() {
    _nimController.dispose();
    _namaController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final stores = await FirebaseFirestore.instance
    .collection('stores')
    .where('code', isEqualTo: _nimController.text)
    .limit(1)
    .get();

    if(stores.docs.isEmpty){
      showDialog(
        context: context, 
        builder: (_) => AlertDialog(
          title: Text('Toko tidak ditemukan!'),
          content: Text('Toko dengan NIM ${_nimController.text} tidak dapat ditemukan!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        )
      );
    }
    else{
      final box = Hive.box('stores');

      box.clear();
      box.put('code', stores.docs.first.id);

      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => FetchReceiptsScreen()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: (
        Container(
          width: double.infinity,
          // height: double.infinity,
          padding: EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _nimController,
                decoration: InputDecoration(
                  labelText: "NIM",
                  border: OutlineInputBorder()
                ) 
              ),
              SizedBox(height: 10),
              TextField(
                controller: _namaController,
                decoration: InputDecoration(
                  labelText: "Nama Toko",
                  border: OutlineInputBorder()
                ) 
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: login,
                child: Text('Masuk'),
              ),
            ]
          )
        )
      )
    );
  }
}

// class ReceiptsPage extends StatelessWidget {
//   final CollectionReference receipts = FirebaseFirestore.instance.collection('stores');
//   // ).where('store_ref', isEqualTo: '/stores/1').get();

//   // Future<void> saveData() async {
//   //   SharedPreferences prefs = await SharedPreferences.getInstance();
//   //   await prefs.setStringList(key, value)
//   //   await prefs.setString('key_name', 'value');
//   //   await prefs.setInt('key_age', 25);
//   //   await prefs.setBool('is_logged_in', true);
//   // }
  
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("History Pembelian")),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: receipts.orderBy('created_at', descending: true).snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           }

//           final filteredDocs = snapshot.data!.docs.where((DocumentSnapshot document) {
//             final data = document.data()! as Map<String, dynamic>;
//             return data['store_ref'] == 'Wendy';
//           }).toList();

//           if (filteredDocs.isEmpty) {
//             return Center(child: Text("Belum ada catatan."));
//           }

//           return ListView(
//             children:
//                 filteredDocs.map((DocumentSnapshot document) {
//                   final data = document.data()! as Map<String, dynamic>;
//                   return Card(
//                     margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                     child: ListTile(
//                       title: Text(data['title'] ?? '-'),
//                       subtitle: Text(data['content'] ?? ''),
//                       trailing:
//                         Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             data['synced'] == true
//                               ? Icon(Icons.cloud_done, color: Colors.green)
//                               : Icon(Icons.cloud_off, color: Colors.grey),
//                             IconButton(
//                               hoverColor: Colors.transparent,
//                               onPressed: () async {
//                                 bool confirm = await showDialog(
//                                   context: context,
//                                   builder: (context) => AlertDialog(
//                                     title: Text('Hapus catatan'),
//                                     content: Text('Apakah anda yakin ingin menghapus catatan ini?'),
//                                     actions: [
//                                       TextButton(
//                                         onPressed: () => Navigator.pop(context, false),
//                                         child: Text('Batal'),
//                                       ),
//                                       TextButton(
//                                         onPressed: () => Navigator.pop(context, true),
//                                         child: Text('Hapus'),
//                                       ),
//                                     ],
//                                   ),
//                                 );
//                                 if (confirm) {
//                                   await FirebaseFirestore.instance
//                                     .collection('receipts')
//                                     .doc(document.id)
//                                     .delete();
//                                 }
//                               }, 
//                               icon: Icon(Icons.delete, color: Colors.red.shade500)
//                             )
//                           ]
//                         )
                          
//                     ),
//                   );
//                 }).toList(),
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => AddNotePage())
//           );
//         },
//         child: Icon(Icons.add),
//       ),
//     );
//   }
// }
