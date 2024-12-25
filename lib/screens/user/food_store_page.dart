import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/config.dart';
import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';

class FoodStorePage extends StatefulWidget {
  final Map<String, dynamic> store;

  const FoodStorePage({super.key, required this.store});

  @override
  State<FoodStorePage> createState() => _FoodStorePageState();
}

class _FoodStorePageState extends State<FoodStorePage> {
  List<dynamic> foods = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFoods();
  }

  Future<void> fetchFoods() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseurl}/foods/store/${widget.store['id']}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          foods = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.store['name']),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Menu',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (foods.isEmpty)
              const Center(child: Text('No foods available'))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: foods.length,
                  itemBuilder: (context, index) {
                    final food = foods[index];
                    return Card(
                      child: ListTile(
                        title: Text(food['name']),
                        subtitle: Text(food['description'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('\$${food['price']}'),
                            IconButton(
                              icon: const Icon(Icons.add_shopping_cart),
                              onPressed: () async {
                                final cartItem = CartItem(
                                  foodId: food['id'],
                                  name: food['name'],
                                  price: double.parse(food['price'].toString()),
                                  storeId: widget.store['id'],
                                  storeName: widget.store['name'],
                                );
                                await CartProvider.addToCart(cartItem);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Added to cart')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}