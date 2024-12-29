import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/config.dart';
import '../../providers/auth_provider.dart';

class ActiveDeliveriesPage extends StatefulWidget {
  @override
  _ActiveDeliveriesPageState createState() => _ActiveDeliveriesPageState();
}

class _ActiveDeliveriesPageState extends State<ActiveDeliveriesPage> {
  List<dynamic> _activeOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActiveOrders();
  }

  Future<void> _loadActiveOrders() async {
    setState(() => _isLoading = true);
    try {
      final userId = await AuthProvider.getUserId();
      if (userId == null) return;

      final response = await http.get(
        Uri.parse('${Config.baseurl}/orders/shipper/$userId/active'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _activeOrders = json.decode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading active orders: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeOrders.isEmpty) {
      return const Center(child: Text('No active deliveries'));
    }

    return RefreshIndicator(
      onRefresh: _loadActiveOrders,
      child: ListView.builder(
        itemCount: _activeOrders.length,
        itemBuilder: (context, index) {
          final order = _activeOrders[index];
          // Fix: items is already a List<dynamic>, no need to decode
          final items = order['items'] as List<dynamic>;
          
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text('Order #${order['id']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status: ${order['status']}'),
                  Text('Customer: ${order['customer_name']}'),
                  Text('Phone: ${order['customer_phone']}'),
                  Text('Address: ${order['address']}'),
                  const SizedBox(height: 8),
                  Text('Items:'),
                  ...items.map((item) => Text(
                    '- ${item['food_name']} x${item['quantity']} from ${item['store_name']}'
                  )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}