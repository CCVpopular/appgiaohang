import 'package:appgiaohang/config/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../components/app_bar/custom_app_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> stores = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStores();
  }

  Future<void> fetchStores() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseurl}/stores/user'),
      );

      if (response.statusCode == 200) {
        setState(() {
          stores = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:const CustomAppBar(
        title: 'Danh sách cửa hàng', // Thay "Danh sách cửa hàng" vào đây
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20), // Thêm khoảng cách nếu cần
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (stores.isEmpty)
              const Center(child: Text('Không có cửa hàng nào'))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: stores.length,
                  itemBuilder: (context, index) {
                    final store = stores[index];
                    return Card(
                      child: ListTile(
                        title: Text(store['name']),
                        subtitle: Text(store['address']),
                        trailing: const Icon(Icons.storefront),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/food-store',
                            arguments: store,
                          );
                        },
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
