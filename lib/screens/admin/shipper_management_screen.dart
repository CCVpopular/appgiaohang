import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/config.dart';

class ShipperManagementScreen extends StatefulWidget {
  const ShipperManagementScreen({super.key});

  @override
  State<ShipperManagementScreen> createState() => _ShipperManagementScreenState();
}

class _ShipperManagementScreenState extends State<ShipperManagementScreen> {
  List<Map<String, dynamic>> _pendingShippers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingShippers();
  }

  Future<void> _loadPendingShippers() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseurl}/auth/shippers/pending'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _pendingShippers = List<Map<String, dynamic>>.from(
            jsonDecode(response.body)['shippers']
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading shippers: $e')),
      );
    }
  }

  Future<void> _updateShipperStatus(int userId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('${Config.baseurl}/auth/shipper/$userId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        _loadPendingShippers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Shipper $status successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: _pendingShippers.length,
      itemBuilder: (context, index) {
        final shipper = _pendingShippers[index];
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            title: Text(shipper['full_name'] ?? 'Unknown'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${shipper['email']}'),
                Text('Phone: ${shipper['phone_number']}'),
                Text('Vehicle: ${shipper['vehicle_type']}'),
                Text('License: ${shipper['license_plate']}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => _updateShipperStatus(shipper['id'], 'approved'),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _updateShipperStatus(shipper['id'], 'rejected'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
