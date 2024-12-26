import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;

  Future<void> _sendOTP() async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.10.120:3000/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailController.text}),
      );

      if (response.statusCode == 200) {
        setState(() => _otpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent to your email')),
        );
      } else {
        throw Exception('Failed to send OTP');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      print('Sending reset password request...'); // Debug log
      final response = await http.post(
        Uri.parse('http://192.168.10.120:3000/auth/password/reset'), // Updated path
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'otp': _otpController.text,
          'newPassword': _newPasswordController.text,
        }),
      );

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (!mounted) return;

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successfully')),
        );
      } else {
        throw Exception(responseData['error'] ?? 'Failed to reset password');
      }
    } catch (e) {
      print('Error resetting password: $e'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception:', ''))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                enabled: !_otpSent,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter email' : null,
              ),
              if (_otpSent) ...[
                TextFormField(
                  controller: _otpController,
                  decoration: const InputDecoration(labelText: 'Enter OTP'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter OTP' : null,
                ),
                TextFormField(
                  controller: _newPasswordController,
                  decoration: const InputDecoration(labelText: 'New Password'),
                  obscureText: true,
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter new password'
                      : null,
                ),
              ],
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (!_otpSent) {
                        _sendOTP();
                      } else {
                        _resetPassword();
                      }
                    }
                  },
                  child: Text(_otpSent ? 'Reset Password' : 'Send OTP'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
