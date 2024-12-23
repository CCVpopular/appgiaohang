import 'package:flutter/material.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Active Orders'),
              Tab(text: 'Order History'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Active Orders Tab
                ListView.builder(
                  itemCount: 5, // Replace with actual order count
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        leading: const Icon(Icons.delivery_dining),
                        title: Text('Order #${index + 1}'),
                        subtitle: const Text('Order Status: In Progress'),
                        trailing: const Text('\$25.00'),
                        onTap: () {
                          // Handle order tap
                        },
                      ),
                    );
                  },
                ),
                // Order History Tab
                ListView.builder(
                  itemCount: 10, // Replace with actual history count
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        leading: const Icon(Icons.history),
                        title: Text('Order #${index + 1}'),
                        subtitle: const Text('Completed'),
                        trailing: const Text('\$30.00'),
                        onTap: () {
                          // Handle history item tap
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}