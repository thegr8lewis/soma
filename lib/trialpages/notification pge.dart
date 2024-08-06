import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  final List<String> notifications = [
    'You have a new friend request',
    'Your order has been shipped',
    'You have a new message',
    'Your password was changed successfully',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ListTile(
              leading: Icon(Icons.notifications),
              title: Text(notifications[index]),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                // Handle notification tap
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tapped on: ${notifications[index]}'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}