import 'package:flutter/material.dart';
import '../screens/home/activity_tracker.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final ActivityTracker _activityTracker = ActivityTracker();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _activityTracker.startTracking();
    _activityTracker.addListener(_showSnackBar);
  }

  @override
  void dispose() {
    _activityTracker.removeListener(_showSnackBar);
    super.dispose();
  }

  void _showSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notification received!'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'DISMISS',
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('E-Learning Platform'),
        backgroundColor: Colors.white,
      ),
      body: GestureDetector(
        onTap: _activityTracker.userActivity,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school,
                size: 100,
                color: Colors.blueAccent,
              ),
              SizedBox(height: 20),
              Text(
                'Tap to simulate activity',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                'Stay active to receive notifications!',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}