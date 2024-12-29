import 'package:flutter/material.dart';
import '../../components/app_bar/custom_app_bar.dart';
import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<CartItem> cartItems = [];

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final items = await CartProvider.getCart();
    setState(() {
      cartItems = items;
    });
  }

  double get total => cartItems.fold(
      0, (sum, item) => sum + (item.price * item.quantity));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Giỏ hàng',
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                await CartProvider.clearCart();
                _loadCart();
              },
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? const Center(child: Text('Giỏ hàng trống'))
          : ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text('Từ: ${item.storeName}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () async {
                          await CartProvider.updateQuantity(
                              item.foodId, item.quantity - 1);
                          _loadCart();
                        },
                      ),
                      Text('${item.quantity}'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () async {
                          await CartProvider.updateQuantity(
                              item.foodId, item.quantity + 1);
                          _loadCart();
                        },
                      ),
                      Text('\$${(item.price * item.quantity).toStringAsFixed(2)}'),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: cartItems.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: \$${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/checkout',
                        arguments: {
                          'cartItems': cartItems,
                          'total': total,
                        },
                      );
                    },
                    child: const Text('Thanh toán'),
                  ),
                ],
              ),
            ),
    );
  }
}