import 'package:flutter/material.dart';
import '../../providers/auth_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../login_screen.dart';
import '../../utils/shared_prefs.dart';

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
  int? userId; // Add this line

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
    // Get userId from shared preferences or your auth state management
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final id = await SharedPrefs.getUserId();
    setState(() {
      userId = id;
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

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                ),
              ),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Change'),
              onPressed: () async {
                if (userId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User not authenticated')),
                  );
                  return;
                }
                
                try {
                  final response = await http.post(
                    Uri.parse('http://192.168.10.120:3000/auth/change-password'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'userId': userId,
                      'currentPassword': currentPasswordController.text,
                      'newPassword': newPasswordController.text,
                    }),
                  );

                  if (response.statusCode == 200) {
                    if (!mounted) return;
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password changed successfully')),
                    );
                  } else {
                    final errorData = jsonDecode(response.body);
                    throw Exception(errorData['error'] ?? 'Failed to change password');
                  }
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
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
          const Divider(),
          ListTile(
            title: const Text('My Store'),
            leading: const Icon(Icons.store),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/my-store');
            },
            title: const Text('Change Password'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showChangePasswordDialog(),
          ),
          const Divider(),
          ListTile(
            title: const Text('Logout'),
            leading: const Icon(Icons.logout, color: Colors.red),
            onTap: _showLogoutDialog,
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
