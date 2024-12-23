
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome to Delivery App',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // TODO: Navigate to create new order
            },
            child: const Text('Create New Order'),
          ),
          const SizedBox(height: 20),
          const Text(
            'Recent Orders',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 5, // Example count
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    title: Text('Order #${1000 + index}'),
                    subtitle: const Text('Status: Pending'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // TODO: Navigate to order details
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}