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

  Widget _buildAvailableOrdersPage() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (availableOrders.isEmpty) {
      return const Center(child: Text('No orders available for delivery'));
    }

    return ListView.builder(
      itemCount: availableOrders.length,
      itemBuilder: (context, index) {
        final order = availableOrders[index];
        final items = List<dynamic>.from(order['items'] ?? []);

        return Card(
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #${order['id']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${order['total_amount']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Customer: ${order['customer_name'] ?? 'N/A'}'),
                Text('Phone: ${order['customer_phone'] ?? 'N/A'}'),
                Text('Address: ${order['address']}'),
                const Divider(),
                ...items
                    .map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${item['quantity']}x ${item['food_name'] ?? 'Unknown Item'}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          item['store_name'] ?? 'Unknown Store',
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '\$${item['price'] ?? '0.00'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              if ((item['store_address'] ?? '').isNotEmpty)
                                Text(
                                  'Store Address: ${item['store_address']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              if ((item['store_phone'] ?? '').isNotEmpty)
                                Text(
                                  'Store Phone: ${item['store_phone']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              const Divider(),
                            ],
                          ),
                        ))
                    .toList(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => acceptOrder(order['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text(
                        'Accept Delivery',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMyDeliveriesPage() {
    if (myDeliveries.isEmpty) {
      return const Center(child: Text('No active deliveries'));
    }

    return ListView.builder(
      itemCount: myDeliveries.length,
      itemBuilder: (context, index) {
        final delivery = myDeliveries[index];
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            title: Text('Order #${delivery['id']}'),
            trailing: Text('\$${delivery['total_amount']}'),
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
          _buildMyDeliveriesPage(),
          const Center(child: Text('Earnings')),
          const Center(child: Text('Profile')),
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
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
