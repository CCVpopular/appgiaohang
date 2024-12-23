import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Mock user data - in real app, this would come from your backend
  final Map<String, String> userData = {
    'name': 'John Doe',
    'email': 'john.doe@example.com',
    'phone': '+84 123 456 789',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Profile Picture
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 20),
          // User Info List
          Card(
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Full Name'),
                  subtitle: Text(userData['name'] ?? ''),
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
                  subtitle: Text(userData['phone'] ?? ''),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Actions
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
  }
}