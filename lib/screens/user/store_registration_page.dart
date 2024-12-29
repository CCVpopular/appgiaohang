import 'package:flutter/material.dart';
import '../../components/app_bar/custom_app_bar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_provider.dart';

class StoreRegistrationPage extends StatefulWidget {
  const StoreRegistrationPage({super.key});

  @override
  State<StoreRegistrationPage> createState() => _StoreRegistrationPageState();
}

class _StoreRegistrationPageState extends State<StoreRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? selectedAddress;
  double? latitude;
  double? longitude;

  Future<void> _submitStore() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a store address')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = await AuthProvider.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final storeData = {
        'name': _nameController.text,
        'address': selectedAddress,
        'phone_number': _phoneController.text,
        'owner_id': userId,
        'latitude': latitude,
        'longitude': longitude,
      };

      await StoreProvider.registerStore(storeData);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store registered successfully')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to register store: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectAddress() async {
    final result = await Navigator.pushNamed(
      context, 
      '/store-address-map'
    ) as Map<String, dynamic>?;
    
    if (result != null) {
      setState(() {
        selectedAddress = result['address'];
        latitude = result['latitude'];
        longitude = result['longitude'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:const CustomAppBar(title:'Register New Store'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration:
                          const InputDecoration(labelText: 'Store Name'),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter store name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: InkWell(
                        onTap: _selectAddress,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.location_on, 
                                    color: Theme.of(context).primaryColor),
                                  const SizedBox(width: 8),
                                  Text('Store Address',
                                    style: Theme.of(context).textTheme.titleMedium),
                                ],
                              ),
                              if (selectedAddress != null) ...[
                                const SizedBox(height: 8),
                                Text(selectedAddress!,
                                  style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration:
                          const InputDecoration(labelText: 'Phone Number'),
                      keyboardType: TextInputType.phone,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter phone number'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitStore,
                      child: const Text('Register Store'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
