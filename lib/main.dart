import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_auth/screens/authenticate/forgot_pass.dart';
import 'package:system_auth/screens/authenticate/grade.dart';
import 'package:system_auth/screens/authenticate/log_in.dart';
import 'package:system_auth/screens/home/profile/userprofile.dart';
import 'package:system_auth/screens/onboarding/middlepage.dart';
import 'package:system_auth/screens/onboarding/splashscreen.dart';
import 'package:system_auth/themes/theme_provider.dart';
import 'package:system_auth/trialpages/apply.dart';
import 'package:system_auth/trialpages/settings.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  static const String LAST_USED_KEY = 'last_used';

  @override
  void initState() {
    super.initState();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    initializeNotifications();
    sendWelcomeNotification(); // Call sendWelcomeNotification in initState
    checkLastUsed();
  }

  void initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) async {
        await selectNotification(details.payload);
      },
    );
  }

  Future<void> checkLastUsed() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? lastUsed = prefs.getInt(LAST_USED_KEY);
    int now = DateTime.now().millisecondsSinceEpoch;

    // Check if the app hasn't been used for more than a day
    if (lastUsed != null && now - lastUsed > 24 * 60 * 60 * 1000) {
      sendMissYouNotification();
    }

    // Update the last used time
    prefs.setInt(LAST_USED_KEY, now);
  }

  void sendWelcomeNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'welcome_channel_id',
      'welcome_channel_name',
      channelDescription: 'Channel for welcome notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Soma App',
      'Hello,welcome to Soma App!',
      platformChannelSpecifics,
      payload: 'welcome_payload',
    );
  }

  void sendMissYouNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'miss_you_channel_id',
      'miss_you_channel_name',
      channelDescription: 'Channel for miss you notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      1,
      'We Miss You!',
      'It\'s been a while since you last visited our app.',
      platformChannelSpecifics,
      payload: 'miss_you_payload',
    );
  }

  Future<void> selectNotification(String? payload) async {
    // Handle the notification tapped logic here
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      // home: const Homepage(),
    );
  }
}
