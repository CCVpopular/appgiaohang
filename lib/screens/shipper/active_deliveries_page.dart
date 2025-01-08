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
      return const Center(child: Text('Không có đơn hàng đang giao'));
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
            child: Column(
              children: [
                ListTile(
                  title: Text('Order #${order['id']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Trạng thái: ${order['status']}'),
                      Text('Khách hàng: ${order['customer_name']}'),
                      Text('Số điện thoại: ${order['customer_phone']}'),
                      Text('Địa chỉ: ${order['address']}'),
                      const SizedBox(height: 8),
                      Text('Món ăn:'),
                      ...items.map((item) => Text(
                          '- ${item['food_name']} x${item['quantity']} từ ${item['store_name']}')),
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
}
