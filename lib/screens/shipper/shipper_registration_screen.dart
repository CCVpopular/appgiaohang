import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../components/app_bar/custom_app_bar.dart';
import '../../components/buttons/custom_elevated_button.dart';
import '../../config/config.dart';

class ShipperRegistrationScreen extends StatefulWidget {
  const ShipperRegistrationScreen({super.key});

  @override
  State<ShipperRegistrationScreen> createState() => _ShipperRegistrationScreenState();
}

class _ShipperRegistrationScreenState extends State<ShipperRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _licensePlateController = TextEditingController();

  Future<void> _registerShipper() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await http.post(
          Uri.parse('${Config.baseurl}/auth/shipper/register'), // Remove 'api' prefix
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user': {
              'name': _nameController.text,
              'email': _emailController.text,
              'password': _passwordController.text,
              'role': 'shipper',
            },
            'shipper': {
              'phone': _phoneController.text,
              'vehicleType': _vehicleTypeController.text,
              'licensePlate': _licensePlateController.text,
              'status': 'pending' // Add status for admin approval
            }
          }),
        );

        if (!mounted) return;

        if (response.statusCode == 201) { // Changed to 201 for created
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Registration Submitted'),
              content: const Text('Your registration request has been submitted. You will receive an email when the admin reviews your application.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.body}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:const CustomAppBar(
        title: 'Shipper Registration',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _vehicleTypeController,
                decoration: const InputDecoration(labelText: 'Vehicle Type'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _licensePlateController,
                decoration: const InputDecoration(labelText: 'License Plate'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              CustomElevatedButton(
                onPressed: _registerShipper,
                text: 'Submit Registration',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
