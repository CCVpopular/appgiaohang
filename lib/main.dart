import 'package:appgiaohang/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'providers/theme_provider.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_admin_screen.dart';
import 'screens/home_user_screen.dart';
import 'screens/home_shipper_screen.dart';
import 'screens/user/active_orders_screen.dart';
import 'screens/user/add_address_page.dart';
import 'screens/user/add_food_page.dart';
import 'screens/user/cart_page.dart';
import 'screens/user/checkout_page.dart';
import 'screens/shipper/shipper_registration_screen.dart';
import 'screens/user/delivery_tracking_page.dart';
import 'screens/user/store_detail_info.dart';
import 'screens/user/store_detail_page.dart';
import 'screens/user/store_food_management.dart';
import 'screens/user/store_registration_page.dart';
import 'screens/user/user_settings_page.dart';
import 'screens/admin/settings_admin_screen.dart';
import 'providers/auth_provider.dart';
import 'screens/user/user_store_page.dart';
import 'screens/admin/store_approval_screen.dart';
import 'screens/user/food_store_page.dart';
import 'screens/user/address_list_page.dart';
import 'screens/user/store_orders_screen.dart';
import 'screens/user/store_address_map_page.dart';
import 'package:provider/provider.dart';

import 'theme/themes.dart';

void main() async {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
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
        '/store-orders': (context) => const UserStorePage(),
        '/register-store': (context) => const StoreRegistrationPage(),
        '/shipper-registration': (context) => const ShipperRegistrationScreen(),
        '/store-detail': (context) {
          final store = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return StoreDetailPage(store: store);
        },
        '/store-detail-info': (context) {
          final store = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
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
          final store = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return FoodStorePage(store: store);
        },
        '/cart': (context) => const CartPage(),
        '/checkout': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return CheckoutPage(
            cartItems: args['cartItems'],
            total: args['total'],
          );
        },
        '/address-list': (context) => const AddressListPage(),
        '/add-address': (context) => const AddAddressPage(),
        '/store-orders': (context) {
          final storeId = ModalRoute.of(context)!.settings.arguments as int;
          return StoreOrdersScreen(storeId: storeId);
        },
        '/store-address-map': (context) => const StoreAddressMapPage(),
        '/active-orders': (context) => const ActiveOrdersScreen(),
        '/user-delivery-tracking': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return UserDeliveryTrackingPage(order: args);
        },
      },
    );
  }
}
