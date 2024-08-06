import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:system_auth/screens/onboarding/info/on.dart';
import 'package:system_auth/trialpages/apply.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _startSplashScreen();
  }

  Future<void> _startSplashScreen() async {
    await Future.delayed(Duration(seconds: 3));
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final sessionCookie = await _storage.read(key: 'session_cookie');
    if (sessionCookie != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => Homepage()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => OnboardingScreen11()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 300,
              width: 300,
              child: Image.asset('assets/soma2.png'),
            ),
            SizedBox(height: 30),
            Center(
              child: Text(
                ' S O M A  A P P ',
                style: GoogleFonts.pacifico(
                  textStyle: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        blurRadius: 5,
                        color: Colors.yellow.withOpacity(0.5),
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}