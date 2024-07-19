import 'package:flutter/material.dart';
import 'package:system_auth/trialpages/apply.dart';

class NotificationsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(),
                ),);
              // Navigate to notifications settings
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text(
            'You have 3 notifications today.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 10),
          _buildSectionTitle('Today'),
          _buildNotificationItem(
            context,
            avatarUrl: 'https://via.placeholder.com/150',
            username: 'Elayamani',
            message: 'Liked your DailyUI 045 - Favourites',
            timeAgo: '2 h ago',
            icon: Icons.favorite,
          ),
          _buildNotificationItem(
            context,
            avatarUrl: 'https://via.placeholder.com/150',
            username: 'Arslan Ali',
            message: 'Liked your DailyUI 044 - Food menu',
            timeAgo: '6 h ago',
            icon: Icons.favorite,
          ),
          // _buildNotificationItem(
          //   context,
          //   avatarUrl: 'https://via.placeholder.com/150',
          //   username: 'Johny Vino',
          //   message: 'Mentioned you in a comment',
          //   timeAgo: '8 h ago',
          //   icon: Icons.comment,
          // ),
          _buildSectionTitle('This Week'),
          _buildNotificationItem(
            context,
            avatarUrl: 'https://via.placeholder.com/150',
            username: 'Brice Seraphin',
            message: 'Liked your DailyUI 044 - Food menu',
            timeAgo: '6 June',
            icon: Icons.favorite,
          ),
          _buildNotificationItem(
            context,
            avatarUrl: 'https://via.placeholder.com/150',
            username: 'Best UI Design',
            message: 'Started Following your work',
            timeAgo: '5 June',
            icon: Icons.person_add,
          ),
          // _buildNotificationItem(
          //   context,
          //   avatarUrl: 'https://via.placeholder.com/150',
          //   username: 'Kumar MA',
          //   message: 'Mentioned you in a comment',
          //   timeAgo: '5 June',
          //   icon: Icons.comment,
          // ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context,
      {required String avatarUrl,
      required String username,
      required String message,
      required String timeAgo,
      required IconData icon}) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(avatarUrl),
      ),
      title: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: username,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            TextSpan(
              text: ' $message',
              style: TextStyle(color: Colors.black),
            ),
          ],
        ),
      ),
      subtitle: Text(timeAgo),
      trailing: Icon(icon, color: Colors.grey),
      onTap: () {
        // Handle notification item tap
      },
    );
  }
}

// void main() {
//   runApp(MaterialApp(
//     home: NotificationsPage(),
//   ));
// }
