import 'package:flutter/material.dart';
import '../../providers/auth_provider.dart';

class UserSettingsPage extends StatefulWidget {
  const UserSettingsPage({super.key});

  @override
  State<UserSettingsPage> createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  bool notificationsEnabled = true;
  bool darkModeEnabled = false;
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
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Enable or disable notifications'),
            value: notificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                notificationsEnabled = value;
              });
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Enable or disable dark theme'),
            value: darkModeEnabled,
            onChanged: (bool value) {
              setState(() {
                darkModeEnabled = value;
              });
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
          ListTile(
            title: const Text('Privacy Policy'),
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