import 'package:flutter/material.dart';
import 'package:system_auth/trialpages/notification.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildSectionTitle('GENERAL'),
          _buildListTile(
            context,
            icon: Icons.person,
            title: 'Account',
            onTap: () {
              // Navigate to Account settings
            },
          ),
          _buildListTile(
            context,
            icon: Icons.notifications,
            title: 'Notifications',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationsPage(),
                ),);
              // Navigate to Notifications settings
            },
          ),
          _buildListTile(
            context,
            icon: Icons.card_giftcard,
            title: 'Coupons',
            onTap: () {
              // Navigate to Coupons settings
            },
          ),
          _buildListTile(
            context,
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {
              // Perform logout action
            },
          ),
          _buildListTile(
            context,
            icon: Icons.delete,
            title: 'Delete account',
            onTap: () {
              // Navigate to Delete account settings
            },
          ),
          SizedBox(height: 16),
          _buildSectionTitle('FEEDBACK'),
          _buildListTile(
            context,
            icon: Icons.bug_report,
            title: 'Report a bug',
            onTap: () {
              // Navigate to Report a bug page
            },
          ),
          _buildListTile(
            context,
            icon: Icons.feedback,
            title: 'Send feedback',
            onTap: () {
              // Navigate to Send feedback page
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: 1, // Set the selected index to Settings
        selectedItemColor: Colors.blue,
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

  Widget _buildListTile(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: SettingsPage(),
  ));
}
