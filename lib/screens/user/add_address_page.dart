import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class AddAddressPage extends StatefulWidget {
  const AddAddressPage({super.key});

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _detailsController = TextEditingController();
  bool _isLoading = false;

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      // Request permission
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Convert position to address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        List<String> addressParts = [];
        
        // Add street name first (tên đường)
        if (place.street?.isNotEmpty == true) {
          addressParts.add(place.street!);
        }
        // Add ward/commune (phường/xã)
        if (place.subLocality?.isNotEmpty == true) {
          addressParts.add("${place.subLocality}");
        }
        // Add district (quận/huyện)
        if (place.subAdministrativeArea?.isNotEmpty == true) {
          addressParts.add("${place.subAdministrativeArea}");
        }
        // Add city/province (tỉnh/thành phố)
        if (place.administrativeArea?.isNotEmpty == true) {
          addressParts.add(place.administrativeArea!);
        }

        String address = addressParts.join(', ');
        _addressController.text = address;
        // Clear details field since street is now in main address
        _detailsController.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm Địa Chỉ Mới'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Tỉnh/Thành Phố, Quận/Huyện, Phường/Xã',
                      hintText: '',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập địa chỉ';
                      }
                      return null;
                    },
                  ),
                ),
                IconButton(
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  onPressed: _isLoading ? null : _getCurrentLocation,
                  tooltip: 'Lấy vị trí hiện tại',
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _detailsController,
              decoration: const InputDecoration(
                labelText: 'Thông tin bổ sung',
                hintText: '',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  String fullAddress = _addressController.text;
                  if (_detailsController.text.isNotEmpty) {
                    fullAddress += ', ${_detailsController.text}';
                  }
                  Navigator.pop(context, fullAddress);
                }
              },
              child: const Text('Lưu Địa Chỉ'),
            ),
          ],
        ),
      ),
    );
  }
}