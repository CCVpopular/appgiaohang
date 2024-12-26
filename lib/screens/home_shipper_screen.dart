import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/config.dart';

class HomeShipperScreen extends StatefulWidget {
  const HomeShipperScreen({super.key});

  @override
  State<HomeShipperScreen> createState() => _HomeShipperScreenState();
}

class _HomeShipperScreenState extends State<HomeShipperScreen> {
  int _selectedIndex = 0;
  List<dynamic> availableOrders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAvailableOrders();
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
                Navigator.pushReplacementNamed(context, '/login'); // Navigate to login screen
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
        Uri.parse('${Config.baseurl}/orders/pending'),
      );

      if (response.statusCode == 200) {
        setState(() {
          availableOrders = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      // Handle error
    }
  }

  Widget _buildAvailableOrdersPage() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (availableOrders.isEmpty) {
      return const Center(child: Text('No available orders'));
    }

    return ListView.builder(
      itemCount: availableOrders.length,
      itemBuilder: (context, index) {
        final order = availableOrders[index];
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            title: Text('Order #${order['id']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Delivery to: ${order['address']}'),
                Text('Total: \$${order['total_amount']}'),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () {
                // Handle accept order
              },
              child: const Text('Accept'),
            ),
          ),
        );
      },
    );
  }

  final List<Widget> _pages = [
    const Center(child: Text('Available Orders')),
    const Center(child: Text('My Deliveries')),
    const Center(child: Text('Earnings')),
    const Center(child: Text('Profile')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipper Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildAvailableOrdersPage(),
          const Center(child: Text('My Deliveries')),
          const Center(child: Text('Earnings')),
          const Center(child: Text('Profile')),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.delivery_dining), label: 'Deliveries'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Earnings'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}