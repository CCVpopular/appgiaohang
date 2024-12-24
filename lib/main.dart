import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_admin_screen.dart';
import 'screens/home_user_screen.dart';
import 'screens/home_shipper_screen.dart';
import 'providers/auth_provider.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder<bool>(
        future: AuthProvider.isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.data == true) {
            return FutureBuilder<String?>(
              future: AuthProvider.getUserRole(),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                switch (roleSnapshot.data) {
                  case 'admin':
                    return const HomeAdminScreen();
                  case 'user':
                    return const HomeUserScreen();
                  case 'shipper':
                    return const HomeShipperScreen();
                  default:
                    return const LoginScreen();
                }
              },
            );
          }

          return const HomeUserScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/admin': (context) => const HomeAdminScreen(),
        '/shipper': (context) => const HomeShipperScreen(),
        '/user_home': (context) => const HomeUserScreen(),
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}

