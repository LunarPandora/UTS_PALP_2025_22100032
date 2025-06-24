import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uts_palp_2025_22100032/main_menu.dart';

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
          return FlatNavApp();
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

      await box.clear();
      await box.put('code', stores.docs.first.id);

      Navigator.push(context, MaterialPageRoute(builder: (_) => FlatNavApp()));
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