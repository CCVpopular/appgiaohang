import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/config.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<dynamic> users = [];
  bool isLoading = true;
  String? filterRole;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      final response = await http.get(Uri.parse('${Config.baseurl}/users'));
      if (response.statusCode == 200) {
        setState(() {
          users = json.decode(response.body)['users'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  Future<void> updateUserStatus(int userId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('${Config.baseurl}/users/$userId/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status}),
      );

      if (response.statusCode == 200) {
        fetchUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating user status: $e')),
        );
      }
    }
  }

  Future<void> toggleUserActive(int userId, bool isActive) async {
    try {
      final response = await http.put(
        Uri.parse('${Config.baseurl}/users/$userId/active'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'isActive': isActive}),
      );

      if (response.statusCode == 200) {
        fetchUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating user active status: $e')),
        );
      }
    }
  }

  Future<void> _createUser(
    String email,
    String password,
    String fullName,
    String phoneNumber,
    String role,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.baseurl}/users'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'role': role,
        }),
      );

      if (response.statusCode == 201) {
        fetchUsers();
      } else {
        throw Exception(json.decode(response.body)['error']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating user: $e')),
        );
      }
    }
  }

  Future<void> _updateUser(
    int userId,
    String fullName,
    String phoneNumber,
    String role,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('${Config.baseurl}/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'role': role,
        }),
      );

      if (response.statusCode == 200) {
        fetchUsers();
      } else {
        throw Exception(json.decode(response.body)['error']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating user: $e')),
        );
      }
    }
  }

  void _showUserDialog([Map<String, dynamic>? user]) {
    final isEditing = user != null;
    final emailController = TextEditingController(text: user?['email'] ?? '');
    final nameController = TextEditingController(text: user?['full_name'] ?? '');
    final phoneController = TextEditingController(text: user?['phone_number'] ?? '');
    final passwordController = TextEditingController();
    String selectedRole = user?['role'] ?? 'user';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit User' : 'Create User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isEditing)
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              if (!isEditing)
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('User')),
                  DropdownMenuItem(value: 'shipper', child: Text('Shipper')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) => selectedRole = value!,
                decoration: const InputDecoration(labelText: 'Role'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (isEditing) {
                await _updateUser(
                  user['id'],
                  nameController.text,
                  phoneController.text,
                  selectedRole,
                );
              } else {
                await _createUser(
                  emailController.text,
                  passwordController.text,
                  nameController.text,
                  phoneController.text,
                  selectedRole,
                );
              }
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(isEditing ? 'Save' : 'Create'),
          ),
        ],
      ),
    );
  }

  List<dynamic> getFilteredUsers() {
    return users.where((user) {
      final matchesSearch = user['full_name'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
                          user['email'].toString().toLowerCase().contains(searchQuery.toLowerCase());
      final matchesRole = filterRole == null || user['role'] == filterRole;
      return matchesSearch && matchesRole;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredUsers = getFilteredUsers();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => searchQuery = value),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: filterRole,
                hint: const Text('Role'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: 'user', child: Text('User')),
                  DropdownMenuItem(value: 'shipper', child: Text('Shipper')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) => setState(() => filterRole = value),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showUserDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add User'),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: fetchUsers,
            child: ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        user['full_name']?[0]?.toUpperCase() ?? 'U',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(user['full_name'] ?? 'N/A'),
                    subtitle: Text(user['email']),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Role: ${user['role']}'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Active Status:'),
                                Switch(
                                  value: user['is_active'] == 1,
                                  onChanged: (value) => 
                                      toggleUserActive(user['id'], value),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _showUserDialog(user),
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Edit'),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => 
                                      toggleUserActive(user['id'], !user['is_active']),
                                  icon: Icon(user['is_active'] == 1 
                                      ? Icons.lock 
                                      : Icons.lock_open),
                                  label: Text(user['is_active'] == 1 
                                      ? 'Lock' 
                                      : 'Unlock'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: user['is_active'] == 1 
                                        ? Colors.red 
                                        : Colors.green,
                                  ),
                                ),
                                // const SizedBox(width: 8),
                                // TextButton(
                                //   onPressed: () => 
                                //       updateUserStatus(user['id'], 'approved'),
                                //   child: const Text('Approve'),
                                // ),
                                // const SizedBox(width: 8),
                                // TextButton(
                                //   onPressed: () => 
                                //       updateUserStatus(user['id'], 'rejected'),
                                //   style: TextButton.styleFrom(
                                //     foregroundColor: Colors.red,
                                //   ),
                                //   child: const Text('Reject'),
                                // ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
