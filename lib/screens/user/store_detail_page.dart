import 'package:flutter/material.dart';
import '../../components/app_bar/custom_app_bar.dart';
import '../../components/card/custom_card.dart';
import 'store_orders_screen.dart';

class StoreDetailPage extends StatelessWidget {
  final Map<String, dynamic> store;
  
  const StoreDetailPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:const CustomAppBar(
        title: 'Store Details',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomCard(
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/store-detail-info',
                    arguments: store,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store['name'] ?? '',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        store['address'] ?? '',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        store['phone_number'] ?? '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          Text('Tap to view details'),
                          Icon(Icons.arrow_forward_ios),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (store['status'] == 'approved') ...[
              CustomCard(
                child: ListTile(
                  leading: const Icon(Icons.restaurant_menu),
                  title: const Text('Manage Food Items'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/food-management',
                      arguments: store['id'],
                    );
                  },
                ),
              ),
              CustomCard(
                child: ListTile(
                  leading: const Icon(Icons.shopping_bag),
                  title: const Text('View Orders'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StoreOrdersScreen(
                          storeId: store['id'],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}