import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/config.dart';

class StoreOrdersScreen extends StatefulWidget {
  final int storeId;

  const StoreOrdersScreen({super.key, required this.storeId});

  @override
  State<StoreOrdersScreen> createState() => _StoreOrdersScreenState();
}

class _StoreOrdersScreenState extends State<StoreOrdersScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseurl}/orders/store/${widget.storeId}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _orders = json.decode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading orders: $e')),
      );
    }
  }

  Future<void> _reviewOrder(int orderId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('${Config.baseurl}/orders/$orderId/review'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status}),
      );
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'accepted' 
                ? 'Order confirmed successfully' 
                : 'Order rejected'
            ),
            backgroundColor: status == 'accepted' ? Colors.green : Colors.red,
          ),
        );
      }
      
      _loadOrders(); // Reload orders after review
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Store Orders')),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _orders.length,
            itemBuilder: (context, index) {
              final order = _orders[index];
              final items = order['items'];
              final status = order['status'];
              
              return Card(
                margin: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    ListTile(
                      title: Text('Order #${order['id']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status: ${status.toUpperCase()}',
                            style: TextStyle(
                              color: status == 'confirmed' 
                                ? Colors.green 
                                : status == 'cancelled' 
                                  ? Colors.red 
                                  : Colors.black,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          Text('Total: \$${order['total_amount']}'),
                          Text('Items: ${items.length}'),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                    if (status == 'pending')
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _reviewOrder(order['id'], 'rejected'),
                              child: const Text('Reject'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _reviewOrder(order['id'], 'accepted'),
                              child: const Text('Accept'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
    );
  }
}
