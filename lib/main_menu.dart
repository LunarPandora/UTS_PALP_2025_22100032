import 'package:flutter/material.dart';

import 'Suppliers/fetch_supplier_screen.dart';
import 'Warehouse/fetch_warehouse_screen.dart';
import 'Receipts/fetch_receipts_screen.dart';
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
    FetchReceiptsScreen(),
    FetchSuppliersScreen(),
    FetchWarehousesScreen(),
    FetchProductScreen(),
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
            icon: Icon(Icons.price_check),
            label: "Receipts"
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