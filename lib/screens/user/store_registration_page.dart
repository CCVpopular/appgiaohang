import 'package:flutter/material.dart';
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
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitStore() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = await AuthProvider.getUserId();
      if (userId == null) {
      throw Exception('User not logged in');
      }

      final storeData = {
      'name': _nameController.text,
      'address': _addressController.text,
      'phone_number': _phoneController.text,
      'owner_id': userId,
      };

      print(storeData);

      await StoreProvider.registerStore(storeData);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Store registered successfully')),
      );
      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to register store: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register New Store')),
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
                    TextFormField(
                      controller: _addressController,
                      decoration:
                          const InputDecoration(labelText: 'Store Address'),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter address'
                          : null,
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
