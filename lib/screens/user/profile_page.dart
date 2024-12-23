import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'user_settings_page.dart';

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
    final response = await http.get(
      Uri.parse('http://localhost:3000/auth/user/$userId'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user data');
    }
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
                  onPressed: () {
                    // Add edit profile functionality
                  },
                  child: const Text('Edit Profile'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    // Add logout functionality
                  },
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