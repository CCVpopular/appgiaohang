import 'package:flutter/material.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_admin_screen.dart';
import 'screens/home_user_screen.dart';
import 'screens/home_shipper_screen.dart';
import 'screens/user/add_food_page.dart';
import 'screens/user/store_detail_info.dart';
import 'screens/user/store_detail_page.dart';
import 'screens/user/store_food_management.dart';
import 'screens/user/store_registration_page.dart';
import 'screens/user/user_settings_page.dart';
import 'screens/settings_admin_screen.dart';
import 'providers/auth_provider.dart';
import 'screens/user/user_store_page.dart';
import 'screens/store_approval_screen.dart';
import 'screens/user/food_store_page.dart';

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
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/admin': (context) => const HomeAdminScreen(),
        '/shipper': (context) => const HomeShipperScreen(),
        '/user_home': (context) => const HomeUserScreen(),
        '/user_settings': (context) => const UserSettingsPage(),
        '/admin_settings': (context) => const SettingsAdminScreen(),
        '/my-store': (context) => const UserStorePage(),
        '/register-store': (context) => const StoreRegistrationPage(),
        '/store-detail': (context) {
          final store = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return StoreDetailPage(store: store);
        },
        '/store-detail-info': (context) {
          final store = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return StoreDetailInfo(store: store);
        },
        '/store-approval': (context) => const StoreApprovalScreen(),
        '/add-food': (context) {
          final storeId = ModalRoute.of(context)!.settings.arguments as int;
          return AddFoodPage(storeId: storeId);
        },
        '/food-management': (context) {
          final storeId = ModalRoute.of(context)!.settings.arguments as int;
          return StoreFoodManagement(storeId: storeId);
        },
        '/food-store': (context) {
          final store = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return FoodStorePage(store: store);
        },
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}

