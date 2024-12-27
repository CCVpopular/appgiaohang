import 'package:flutter/material.dart';
// ...existing imports...
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/config.dart';

class AvailableOrdersPage extends StatelessWidget {
  final List<dynamic> availableOrders;
  final bool isLoading;
  final Function(int) acceptOrder;

  const AvailableOrdersPage({
    Key? key,
    required this.availableOrders,
    required this.isLoading,
    required this.acceptOrder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                // ...existing code...
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
          ),
        );
      },
    );
  }
}
