import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10, // Replace with actual notifications count
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.notifications, color: Colors.white),
            ),
            title: Text('Notification ${index + 1}'),
            subtitle: Text('This is a notification message for item $index'),
            trailing: Text('${DateTime.now().hour}:${DateTime.now().minute}'),
            onTap: () {
              // Handle notification tap
            },
          ),
        );
      },
    );
  }
}