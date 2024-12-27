import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_zalopay_sdk/flutter_zalopay_sdk.dart';
import '../../config/config.dart';
import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/shared_prefs.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartItem> cartItems;
  final double total;

  const CheckoutPage({
    super.key,
    required this.cartItems,
    required this.total,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _selectedAddress = '';
  double? _latitude;
  double? _longitude;
  final _noteController = TextEditingController();
  String _paymentMethod = 'cash';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSelectedAddress();
    _loadPaymentMethod();
  }

  Future<void> _loadSelectedAddress() async {
    try {
      final userId = await SharedPrefs.getUserId();
      if (userId == null) return;

      final response = await http.get(
        Uri.parse('${Config.baseurl}/addresses/user/$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> addresses = json.decode(response.body);
        final selectedAddress = addresses.firstWhere(
          (addr) => addr['is_selected'] == 1,
          orElse: () => {'address': '', 'latitude': null, 'longitude': null},
        );
        
        setState(() {
          _selectedAddress = selectedAddress['address'];
          _latitude = selectedAddress['latitude'];
          _longitude = selectedAddress['longitude'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading address: $e')),
      );
    }
  }

  Future<void> _loadPaymentMethod() async {
    _paymentMethod = await SharedPrefs.getPaymentMethod();
    setState(() {});
  }

  Future<void> _handleZaloPayment() async {
    try {
      // Get ZaloPay token from backend
      final response = await http.post(
        Uri.parse('${Config.baseurl}/orders/create-zalopay-order'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'amount': widget.total.round(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get ZaloPay token');
      }

      final paymentData = json.decode(response.body);
      
      // ZaloPay SDK returns:
      // 1: Success
      // -1: Failure
      // 2: User canceled
      final zpResult = await FlutterZaloPaySdk.payOrder(
        zpToken: paymentData['zp_trans_token'],
      );
      
      if (zpResult == 1) { // Payment successful
        await _placeOrder();
      } else {
        if (!mounted) return;
        String message = zpResult == 2 
          ? 'Thanh toán đã bị hủy'
          : 'Thanh toán thất bại';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi thanh toán: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Địa chỉ giao hàng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                title: Text(_selectedAddress.isEmpty 
                  ? 'Chọn địa chỉ giao hàng' 
                  : _selectedAddress),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  final result = await Navigator.pushNamed(
                    context, 
                    '/address-list'
                  );
                  if (result != null && result is String) {
                    setState(() => _selectedAddress = result);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ghi chú',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: 'Thêm ghi chú cho đơn hàng (không bắt buộc)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            const Text(
              'Phương thức thanh toán',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            RadioListTile(
              title: const Text('Thanh toán khi nhận hàng'),
              value: 'cash',
              groupValue: _paymentMethod,
              onChanged: (value) => setState(() {
                _paymentMethod = value!;
                SharedPrefs.savePaymentMethod(value);
              }),
            ),
            RadioListTile(
              title: const Text('ZaloPay'),
              value: 'zalopay',
              groupValue: _paymentMethod,
              onChanged: (value) => setState(() {
                _paymentMethod = value!;
                SharedPrefs.savePaymentMethod(value);
              }),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tổng quan đơn hàng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.cartItems.length,
              itemBuilder: (context, index) {
                final item = widget.cartItems[index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text('${item.quantity}x \$${item.price}'),
                  trailing: Text('\$${(item.price * item.quantity).toStringAsFixed(2)}'),
                );
              },
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${widget.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
            if (_paymentMethod == 'zalopay') {
              _handleZaloPayment();
            } else {
              _placeOrder();
            }
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Đặt hàng'),
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn địa chỉ giao hàng')),
      );
      return;
    }

    try {
      final userId = await SharedPrefs.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final orderData = {
        'userId': userId,
        'address': _selectedAddress,
        'latitude': _latitude,
        'longitude': _longitude,
        'items': widget.cartItems.map((item) => {
          'foodId': item.foodId,
          'quantity': item.quantity,
          'price': item.price,
          'storeId': item.storeId,
        }).toList(),
        'totalAmount': widget.total,
        'paymentMethod': _paymentMethod,
        'note': _noteController.text,
      };

      final response = await http.post(
        Uri.parse('${Config.baseurl}/orders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(orderData),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to create order');
      }

      await CartProvider.clearCart();
      if (!mounted) return;
      
      Navigator.popUntil(context, (route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đặt hàng thành công!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đặt hàng: $e')),
      );
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}