import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/config.dart';
import '../../providers/auth_provider.dart';
import '../chat_screen.dart';
import './delivery_navigation_page.dart';

class ActiveDeliveriesPage extends StatefulWidget {
  @override
  _ActiveDeliveriesPageState createState() => _ActiveDeliveriesPageState();
}

class _ActiveDeliveriesPageState extends State<ActiveDeliveriesPage> {
  List<dynamic> _activeOrders = [];
  bool _isLoading = true;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadActiveOrders();
  }

  Future<void> _loadActiveOrders() async {
    setState(() => _isLoading = true);
    try {
      final id = await AuthProvider.getUserId();
      userId = id?.toString();
      if (userId == null) return;

      final response = await http.get(
        Uri.parse('${Config.baseurl}/orders/shipper/$userId/active'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _activeOrders = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        print('Error: ${response.body}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading active orders: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startDelivery(Map<String, dynamic> order) async {
    try {
      final shipperId = await AuthProvider.getUserId();
      if (shipperId == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse('${Config.baseurl}/orders/${order['id']}/start-delivery'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'shipperId': shipperId}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery started successfully')),
        );
        _loadActiveOrders();
      } else {
        final error = json.decode(response.body)['error'];
        throw Exception(error ?? 'Failed to start delivery');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _completeDelivery(Map<String, dynamic> order) async {
    try {
      final shipperId = await AuthProvider.getUserId();
      if (shipperId == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse('${Config.baseurl}/orders/${order['id']}/complete-delivery'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'shipperId': shipperId}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã giao hàng thành công')),
        );
        _loadActiveOrders();
      } else {
        final error = json.decode(response.body)['error'];
        throw Exception(error ?? 'Failed to complete delivery');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không có đơn hàng đang giao',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadActiveOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _activeOrders.length,
        itemBuilder: (context, index) {
          final order = _activeOrders[index];
          final items = order['items'] as List<dynamic>;

          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: order['status'] == 'preparing' 
                        ? Colors.blue[50] 
                        : Colors.green[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        order['status'] == 'preparing'
                            ? Icons.pending_actions
                            : Icons.delivery_dining,
                        color: order['status'] == 'preparing'
                            ? Colors.blue
                            : Colors.green,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Order #${order['id']}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: order['status'] == 'preparing'
                              ? Colors.blue[700]
                              : Colors.green[700],
                        ),
                      ),
                      const Spacer(),
                      _buildStatusChip(order['status']),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(Icons.person, order['customer_name']),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.phone, order['customer_phone']),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.location_on, order['address']),
                      const Divider(height: 24),
                      ...items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Text(
                                  '- ${item['food_name']} x${item['quantity']} từ ${item['store_name']}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
                OverflowBar(
                  children: [
                    if (order['status'] == 'preparing')
                      ElevatedButton.icon(
                        icon: const Icon(Icons.delivery_dining),
                        label: const Text('Đã nhận hàng giao'),
                        onPressed: () => _startDelivery(order),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 168, 255, 197),
                        ),
                      ),
                    if (order['status'] == 'delivering')
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Đã giao hàng'),
                        onPressed: () => _completeDelivery(order),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    if (order['status'] == 'delivering')
                      ElevatedButton.icon(
                        icon: const Icon(Icons.chat),
                        label: const Text('Nhắn tin'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                orderId: order['id'],
                                currentUserId: int.parse(userId!), // Add userId as class field
                                otherUserId: order['user_id'],
                                otherUserName: order['customer_name'],
                              ),
                            ),
                          );
                        },
                      ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.navigation),
                      label: const Text('Chỉ đường'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DeliveryNavigationPage(
                              order: order,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case 'preparing':
        color = Colors.blue;
        text = 'Đang chuẩn bị';
        break;
      case 'delivering':
        color = Colors.green;
        text = 'Đang giao';
        break;
      default:
        color = Colors.grey;
        text = 'Không xác định';
    }

    return Chip(
      label: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
