import 'package:flutter/material.dart';

class MyDeliveriesPage extends StatelessWidget {
  final List<dynamic> myDeliveries;

  const MyDeliveriesPage({
    Key? key,
    required this.myDeliveries,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
}
