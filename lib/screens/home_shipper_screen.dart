import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/config.dart';
import 'shipper/available_orders_page.dart';
import 'shipper/my_deliveries_page.dart';
import 'shipper/settings_page.dart';

class HomeShipperScreen extends StatefulWidget {
  const HomeShipperScreen({super.key});

  @override
  State<HomeShipperScreen> createState() => _HomeShipperScreenState();
}

class _HomeShipperScreenState extends State<HomeShipperScreen> {
  int _selectedIndex = 0;
  List<dynamic> availableOrders = [];
  List<dynamic> myDeliveries = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAvailableOrders();
    fetchMyDeliveries();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pushReplacementNamed(
                    context, '/login'); // Navigate to login screen
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> fetchAvailableOrders() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseurl}/orders/confirmed'),
      );

      if (response.statusCode == 200) {
        setState(() {
          availableOrders = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load orders')),
      );
    }
  }

  Future<void> fetchMyDeliveries() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${Config.baseurl}/orders/shipper/1/active'), // Replace 1 with actual shipperId
      );

      if (response.statusCode == 200) {
        setState(() {
          myDeliveries = json.decode(response.body);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load deliveries')),
      );
    }
  }

  Future<void> acceptOrder(int orderId) async {
    try {
      print('Accepting order: $orderId');
      
      final response = await http.post(
        Uri.parse('${Config.baseurl}/orders/$orderId/accept'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'shipperId': 1, // Replace with actual logged in shipper ID
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        await Future.wait([
          fetchAvailableOrders(),
          fetchMyDeliveries(),
        ]);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order accepted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _selectedIndex = 1;
        });
      } else {
        throw Exception(responseData['error'] ?? 'Failed to accept order');
      }
    } catch (e) {
      print('Error accepting order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipper Dashboard'),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          AvailableOrdersPage(
            availableOrders: availableOrders,
            isLoading: isLoading,
            acceptOrder: acceptOrder,
          ),
          MyDeliveriesPage(
            myDeliveries: myDeliveries,
          ),
          const Center(child: Text('Earnings')),
          const SettingsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Orders'),
          BottomNavigationBarItem(
              icon: Icon(Icons.delivery_dining), label: 'Deliveries'),
          BottomNavigationBarItem(
              icon: Icon(Icons.attach_money), label: 'Earnings'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
