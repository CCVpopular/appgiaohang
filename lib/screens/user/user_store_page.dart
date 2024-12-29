import 'package:flutter/material.dart';
import '../../components/app_bar/custom_app_bar.dart';
import '../../providers/store_provider.dart';
import 'store_orders_screen.dart';

class UserStorePage extends StatefulWidget {
  const UserStorePage({super.key});

  @override
  State<UserStorePage> createState() => _UserStorePageState();
}

class _UserStorePageState extends State<UserStorePage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _stores = [];

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    setState(() => _isLoading = true);
    try {
      final stores = await StoreProvider.getUserStores();
      setState(() => _stores = stores);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load stores: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return '🟢 Approved';
      case 'pending':
        return '🟡 Pending';
      case 'rejected':
        return '🔴 Rejected';
      default:
        return '⚪ Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:const CustomAppBar(
        title: 'My Stores',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stores.isEmpty
              ? _buildEmptyState()
              : _buildStoreList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/register-store');
          if (result == true) {
            _loadStores(); // Refresh store list after registration
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.store_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No stores yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Tap the + button to register a new store'),
        ],
      ),
    );
  }

  Widget _buildStoreList() {
    return ListView.builder(
      itemCount: _stores.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final store = _stores[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Column(
            children: [
              ListTile(
                title: Text(
                  store['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('📍 ${store['address']}'),
                    Text('📞 ${store['phone_number']}'),
                    Text(_getStatusColor(store['status'])),
                  ],
                ),
                isThreeLine: true,
                onTap: () {
                  Navigator.pushNamed(
                    context, 
                    '/store-detail',
                    arguments: store,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}