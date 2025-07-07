import 'package:flutter/material.dart';
import 'package:uts_palp_2025_22100032/Mutation/add_mutasi_screen.dart';
import 'package:uts_palp_2025_22100032/Transactions/Pengiriman/fetch_pengiriman_screen.dart';

import 'Suppliers/fetch_supplier_screen.dart';
import 'Warehouse/fetch_warehouse_screen.dart';
import 'Transactions/Pembelian/fetch_pembelian_screen.dart';
import 'Products/fetch_products_screen.dart';

void main(){
  runApp(FlatNavApp());
}

class FlatNavApp extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Main Menu",
      home: MainScreen()
    );
  }
}

class MainScreen extends StatefulWidget{
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>{
  int _currentIndex = 0;

  final List<Widget> _screens = [
    FetchPembelianScreen(),
    FetchPengirimanScreen(),
    FetchSuppliersScreen(),
    FetchWarehousesScreen(),
    FetchProductScreen(),
    MutationPage(),
    // ResponsiveExample()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.arrow_circle_down_outlined),
            label: "Incoming"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.arrow_circle_up_outlined),
            label: "Outgoing"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storage),
            label: "Suppliers"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warehouse),
            label: "Warehouse"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: "Products"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.move_down_rounded),
            label: "Mutation"
          ),
        ],
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index){
          setState(() {
            _currentIndex = index;
          });
        }
      ),
    );
  }
}