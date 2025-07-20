import 'package:flutter/material.dart';
import 'home_screen.dart';       // Replace with your actual dashboard file
import 'bill_payment_screen.dart';  // Replace with your bill payment screen file
import 'maintenance_screen.dart';   // Your UPI screen
import 'card_screen.dart';          // Your card screen
import 'MyProfileScreen.dart';    // Your profile screen

class MainNavigationScreen extends StatefulWidget {
  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  List<Widget> get _screens => [
    HomeScreen(),
    BillPaymentScreen(onTabChanged: _onTabTapped),
    MaintenanceScreen(),
    CardScreen(),
    MyProfileScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.account_balance), label: "Banking"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: "Bill Pay"),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: "BHIM UPI"),
          BottomNavigationBarItem(icon: Icon(Icons.credit_card), label: "Cards"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
