import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../components/app_bar/custom_app_bar.dart';
import '../components/bottom_navigation_bar/custom_bottom_navigation_bar.dart';
import '../config/config.dart';
import '../providers/auth_provider.dart';
import 'shipper/settings_page.dart';
import 'shipper/order_list_page.dart';
import 'shipper/active_deliveries_page.dart';

class HomeShipperScreen extends StatefulWidget {
  const HomeShipperScreen({super.key});

  @override
  State<HomeShipperScreen> createState() => _HomeShipperScreenState();
}

class _HomeShipperScreenState extends State<HomeShipperScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      OrderListPage(),
      ActiveDeliveriesPage(),
      const Center(child: Text('Earnings')),
      const SettingsPage(),
    ]);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:const CustomAppBar(
        title: 'Shipper Dashboard',
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: CustomBottomNavBar(
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Orders'),
            BottomNavigationBarItem(icon: Icon(Icons.delivery_dining), label: 'Deliveries'),
            BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Earnings'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
