import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../components/app_bar/custom_app_bar.dart';
import '../components/buttons/custom_elevated_button.dart';
import '../config/config.dart';
import '../main.dart';
import '../providers/auth_provider.dart';
import '../utils/shared_prefs.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _requestNotificationPermission() async {
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('Notification permission status: ${settings.authorizationStatus}');
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        String? fcmToken = await FirebaseMessaging.instance.getToken();

        final response = await http.post(
          Uri.parse('${Config.baseurl}/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': _emailController.text,
            'password': _passwordController.text,
            'fcmToken': fcmToken,
          }),
        );

        print(response.statusCode);
        if (response.statusCode == 200) {
          final userData = jsonDecode(response.body);
          await SharedPrefs.saveUserId(userData['id']); // Add this line

          // Save user data
          await AuthProvider.saveUserData(userData);
          
          // Check and request notification permissions after login
          await checkAndRequestNotificationPermissions(context);

          if (!mounted) return;

          // Check if we can pop back to previous screen

          // If no previous screen, navigate based on role
          switch (userData['role']) {
            case 'admin':
              Navigator.pushNamedAndRemoveUntil(
                  context, '/admin', (route) => false);
              break;
            case 'user':
              if (Navigator.canPop(context)) {
                Navigator.pop(context, true);
              } else {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/user_home', (route) => false);
              }
              break;
            case 'shipper':
              Navigator.pushNamedAndRemoveUntil(
                  context, '/shipper', (route) => false);
              break;
            default:
              throw Exception('Invalid role');
          }
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.body),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        print(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Đăng nhập'),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Vui lòng nhập email' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Mật khẩu'),
                obscureText: true,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Vui lòng nhập mật khẩu' : null,
              ),
              SizedBox(height: 10),
              CustomElevatedButton(
                onPressed: _login,
                text: 'Đăng nhập',
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: Text('Chưa có tài khoản? Đăng ký'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/forgot-password');
                },
                child: Text('Quên mật khẩu?'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
