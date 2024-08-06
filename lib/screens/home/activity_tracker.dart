import 'dart:async';
import 'package:flutter/material.dart';
import 'notification_service.dart';

class ActivityTracker extends ChangeNotifier {
  Timer? _activityTimer;
  Timer? _inactivityTimer;
  int _activeMinutes = 0;

  void startTracking() {
    _resetTimers();
  }

  void userActivity() {
    _activeMinutes += 1;
    _resetTimers();
  }

  void _resetTimers() {
    _activityTimer?.cancel();
    _inactivityTimer?.cancel();

    _activityTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _activeMinutes += 1;
      if (_activeMinutes == 1) {
        NotificationService.showNotification(1, 'Good work', 'Keep working!');
        notifyListeners();
      } else if (_activeMinutes == 10) {
        NotificationService.showNotification(2, 'Keep going', 'You are doing great!');
        notifyListeners();
      }
    });

    _inactivityTimer = Timer(Duration(hours: 5), () {
      NotificationService.showNotification(3, 'We have missed you', 'Come back and keep learning!');
      _activeMinutes = 0;
      notifyListeners();
    });
  }
}