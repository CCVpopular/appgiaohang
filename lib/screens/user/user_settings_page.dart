import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/app_bar/custom_app_bar.dart';
import '../../components/switch_list_tile/custom_switch_list_tile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class UserSettingsPage extends StatefulWidget {
  const UserSettingsPage({super.key});

  @override
  State<UserSettingsPage> createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  bool notificationsEnabled = true;
  // bool darkModeEnabled = false;
  String selectedLanguage = 'English';
  bool showLogout = false;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    final userId = await AuthProvider.getUserId();
    final userRole = await AuthProvider.getUserRole();
    setState(() {
      showLogout = userId != null;
      isAdmin = userRole == 'admin';
    });
  }

  Future<void> _showLogoutDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () async {
                await AuthProvider.logout();
                if (!mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil('/user_home', (route) => false);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Settings',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          CustomSwitchListTile(
            title: 'Push Notifications',
            subtitle: 'Enable or disable notifications',
            value: notificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                notificationsEnabled = value;
              });
            },
          ),
          const Divider(),
          CustomSwitchListTile(
            title: 'Dark Mode',
            subtitle: 'Enable or disable dark theme',
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Language'),
            subtitle: Text(selectedLanguage),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Add language selection functionality
            },
          ),
          const Divider(),
          ListTile(title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to privacy policy
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to terms of service
            },
          ),
          if (isAdmin) ...[
            const Divider(),
            ListTile(
              title: const Text('Switch to Admin View'),
              leading: const Icon(Icons.admin_panel_settings),
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(context, '/admin', (route) => false);
              },
            ),
          ],
          const Divider(),
          ListTile(
            title: const Text('My Store'),
            leading: const Icon(Icons.store),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/my-store');
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Become a Shipper'),
            leading: const Icon(Icons.delivery_dining),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/shipper-registration');
            },
          ),
          if (showLogout) ...[
            const Divider(),
            ListTile(
              title: const Text('Logout'),
              leading: const Icon(Icons.logout, color: Colors.red),
              onTap: _showLogoutDialog,
            ),
          ],
        ],
      ),
    );
  }
}