import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'user_settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  final int userId;
  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<Map<String, dynamic>> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = getUserById(widget.userId);
  }

  Future<Map<String, dynamic>> getUserById(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('http://26.24.143.103:3000/auth/user/$userId'),
        headers: {
          'Accept': 'application/json',
        },
      );

      print('Get user response: ${response.body}'); // Debug log
      return json.decode(response.body);
    } catch (e) {
      print('Get user error: $e'); // Debug log
      throw Exception('Failed to load user data');
    }
  }

  Future<void> _editProfile() async {
    final userData = await _userFuture;
    final TextEditingController nameController =
        TextEditingController(text: userData['fullName'] ?? '');
    final TextEditingController phoneController =
        TextEditingController(text: userData['phoneNumber'] ?? '');
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
                enabled: !isLoading,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Name cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                enabled: !isLoading,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Phone number cannot be empty';
                  }
                  if (!RegExp(r'^\d{10}$').hasMatch(value!)) {
                    return 'Enter valid 10-digit phone number';
                  }
                  return null;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nameController.text.isEmpty ||
                          phoneController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please fill all fields')),
                        );
                        return;
                      }

                      setState(() => isLoading = true);

                      try {
                        final url = Uri.parse(
                            'http://26.24.143.103:3000/auth/user/${widget.userId}');
                        print('Sending PUT request to: $url'); // Debug log

                        final response = await http.put(
                          url,
                          headers: {
                            'Content-Type': 'application/json',
                            'Accept': 'application/json',
                          },
                          body: json.encode({
                            'fullName': nameController.text.trim(),
                            'phoneNumber': phoneController.text.trim(),
                          }),
                        );

                        print(
                            'Response headers: ${response.headers}'); // Debug log
                        print('Response status: ${response.statusCode}');
                        print('Response body: ${response.body}');

                        if (response.statusCode == 200) {
                          if (!mounted) return;
                          Navigator.pop(context);
                          setState(() {
                            _userFuture = getUserById(widget.userId);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile updated successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          var errorMessage = 'Failed to update profile';
                          try {
                            final errorData = json.decode(response.body);
                            errorMessage = errorData['error'] ?? errorMessage;
                          } catch (e) {
                            print('Error parsing response: $e');
                          }
                          throw Exception(errorMessage);
                        }
                      } catch (e) {
                        print('Update error: $e'); // Debug log
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Error: ${e.toString().replaceAll('Exception:', '')}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        if (mounted) {
                          setState(() => isLoading = false);
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserSettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final userData = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Card(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('Full Name'),
                        subtitle: Text(userData['fullName'] ?? ''),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: const Text('Email'),
                        subtitle: Text(userData['email'] ?? ''),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.phone),
                        title: const Text('Phone'),
                        subtitle: Text(userData['phoneNumber'] ?? ''),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _editProfile,
                  child: const Text('Edit Profile'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Logout'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
