import 'package:flutter/material.dart';
import '../../providers/auth_provider.dart';

class SettingsAdminScreen extends StatefulWidget {
  const SettingsAdminScreen({super.key});

  @override
  State<SettingsAdminScreen> createState() => _SettingsAdminScreenState();
}

class _SettingsAdminScreenState extends State<SettingsAdminScreen> {
  bool _darkMode = false;
  bool _notifications = true;

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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Admin Profile'),
              subtitle: const Text('Manage your profile information'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Navigate to profile management
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  secondary: const Icon(Icons.dark_mode),
                  value: _darkMode,
                  onChanged: (value) {
                    setState(() {
                      _darkMode = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Notifications'),
                  secondary: const Icon(Icons.notifications),
                  value: _notifications,
                  onChanged: (value) {
                    setState(() {
                      _notifications = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Security Settings'),
              subtitle: const Text('Password and authentication'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Navigate to security settings
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.switch_account),
              title: const Text('Switch to User View'),
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(context, '/user_home', (route) => false);
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: _showLogoutDialog,
            ),
          ),
        ],
      ),
    );
  }
}