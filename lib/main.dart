import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_admin_screen.dart';
import 'screens/home_user_screen.dart';
import 'screens/home_shipper_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/admin': (context) => const HomeAdminScreen(),
        '/shipper': (context) => const HomeShipperScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/user') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => HomeUserScreen(userId: args['userId']),
          );
        }
        return null;
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}
