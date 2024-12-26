import 'package:flutter/material.dart';

class AddressListPage extends StatefulWidget {
  const AddressListPage({super.key});

  @override
  State<AddressListPage> createState() => _AddressListPageState();
}

class _AddressListPageState extends State<AddressListPage> {
  String _selectedAddress = ''; // Temporarily store dummy data

  // Dummy data - replace with actual address data from your backend
  final List<Map<String, String>> addresses = [
    {'id': '1', 'address': '123 Main St, City'},
    {'id': '2', 'address': '456 Park Ave, Town'},
    {'id': '3', 'address': '789 Oak Rd, Village'},
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _selectedAddress);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chọn Địa Chỉ Giao Hàng'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _selectedAddress),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.add_circle, color: Colors.blue),
                title: const Text('Thêm Địa Chỉ Mới'),
                onTap: () async {
                  final result = await Navigator.pushNamed(context, '/add-address');
                  if (result != null && result is String) {
                    setState(() {
                      addresses.add({
                        'id': (addresses.length + 1).toString(),
                        'address': result
                      });
                      _selectedAddress = result;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            ...addresses.map((address) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: RadioListTile<String>(
                title: Text(address['address']!),
                value: address['address']!,
                groupValue: _selectedAddress,
                onChanged: (value) {
                  setState(() => _selectedAddress = value!);
                },
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
}