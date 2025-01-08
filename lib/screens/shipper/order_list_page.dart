import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/config.dart';
import '../../providers/auth_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class OrderListPage extends StatefulWidget {
    const OrderListPage({super.key});
  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadOrders();
  }
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = position);
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${Config.baseurl}/orders/confirmed'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _orders = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        print('Error: ${response.body}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading orders: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptOrder(int orderId) async {
    try {
      final userId = await AuthProvider.getUserId();
      if (userId == null) return;

      final response = await http.post(
        Uri.parse('${Config.baseurl}/orders/$orderId/accept'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'shipperId': userId}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order accepted successfully')),
        );
        _loadOrders(); // Refresh the list
      } else {
        throw Exception('Failed to accept order');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting order: $e')),
      );
    }
  }

  double calculateTotalDistance(double storeLat, double storeLng, double customerLat, double customerLng) {
    if (_currentPosition == null) return 0;
    
    // Calculate distance from current location to store
    double toStoreDistance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      storeLat,
      storeLng
    );

    // Calculate distance from store to customer
    double toCustomerDistance = Geolocator.distanceBetween(
      storeLat,
      storeLng,
      customerLat,
      customerLng
    );

    // Return total distance in kilometers
    return (toStoreDistance + toCustomerDistance) / 1000;
  }

  // Add this helper method for VND formatting
  String formatVND(dynamic amount) {
    if (amount == null) return '0 ₫';
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ₫';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_orders.isEmpty) {
      return const Center(child: Text('Không có đơn hàng nào'));
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          // Fix: items is already a List<dynamic>, no need to decode
          final items = order['items'] as List<dynamic>;
          
          // Calculate total distance
          double totalDistance = calculateTotalDistance(
            order['store_latitude'] ?? 0,
            order['store_longitude'] ?? 0,
            order['latitude'] ?? 0,
            order['longitude'] ?? 0
          );

          return Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    title: Text('Đơn hàng #${order['id']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Địa chỉ: ${order['address']}'),
                        Text('Tổng tiền: ${formatVND(order['total_amount'])}'),
                        Text('Phí vận chuyển: ${formatVND(order['shipping_fee'])}'),
                        Text('Tổng khoảng cách: ${totalDistance.toStringAsFixed(2)} km'),
                        const SizedBox(height: 8),
                        const Text('Danh sách món:'),
                        ...items.map((item) => Text(
                          '- ${item['food_name']} x${item['quantity']} từ ${item['store_name']}'
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _acceptOrder(order['id']),
                    child: const Text('Nhận đơn'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}