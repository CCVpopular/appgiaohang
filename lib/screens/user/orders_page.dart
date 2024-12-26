import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/config.dart';
import '../../utils/shared_prefs.dart';

class Order {
  final int id;
  final String status;
  final double totalAmount;
  final String address;
  final List<OrderItem> items;
  final String createdAt;

  Order({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.address,
    required this.items,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List;
    return Order(
      id: json['id'],
      status: json['status'],
      totalAmount: double.parse(json['total_amount'].toString()),
      address: json['address'],
      createdAt: json['created_at'],
      items: itemsList.map((item) => OrderItem.fromJson(item)).toList(),
    );
  }
}

class OrderItem {
  final int foodId;
  final int quantity;
  final double price;
  final int storeId;

  OrderItem({
    required this.foodId,
    required this.quantity,
    required this.price,
    required this.storeId,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      foodId: json['foodId'],
      quantity: json['quantity'],
      price: double.parse(json['price'].toString()),
      storeId: json['storeId'],
    );
  }
}

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final userId = await SharedPrefs.getUserId();
      if (userId == null) throw Exception('User not logged in');

      final response = await http.get(
        Uri.parse('${Config.baseurl}/orders/user/$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> ordersJson = json.decode(response.body);
        setState(() {
          _orders = ordersJson.map((json) => Order.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Order> _getCurrentOrders() {
    return _orders.where((order) => 
      ['pending', 'confirmed', 'preparing', 'delivering'].contains(order.status)
    ).toList();
  }

  List<Order> _getPastOrders() {
    return _orders.where((order) => 
      ['completed', 'cancelled'].contains(order.status)
    ).toList();
  }

  Widget _buildOrderCard(Order order) {
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
                  'Đơn hàng #${order.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  order.status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(order.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            Text('Địa chỉ: ${order.address}'),
            const SizedBox(height: 8),
            Text(
              'Tổng tiền: \$${order.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Ngày đặt: ${_formatDate(order.createdAt)}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'delivering':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            ElevatedButton(
              onPressed: _loadOrders,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Đơn hàng hiện tại'),
              Tab(text: 'Lịch sử đơn hàng'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Current Orders Tab
                _getCurrentOrders().isEmpty
                    ? const Center(child: Text('Không có đơn hàng nào'))
                    : ListView.builder(
                        itemCount: _getCurrentOrders().length,
                        itemBuilder: (context, index) {
                          return _buildOrderCard(_getCurrentOrders()[index]);
                        },
                      ),
                // Order History Tab
                _getPastOrders().isEmpty
                    ? const Center(child: Text('Không có lịch sử đơn hàng'))
                    : ListView.builder(
                        itemCount: _getPastOrders().length,
                        itemBuilder: (context, index) {
                          return _buildOrderCard(_getPastOrders()[index]);
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