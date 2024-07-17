import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:system_auth/screens/authenticate/log_in.dart';
import 'package:system_auth/screens/authenticate/sign_in.dart';

class Middlepage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDF7F2),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(),
              SizedBox(
                height: 200,
                child: Lottie.asset(
                  'assets/caterpillar.json',
                  repeat: true,
                  width: 200,
                  height: 200,
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Color(0xFF3E81F3), // Blue color
                        padding: EdgeInsets.symmetric(horizontal: 64, vertical: 16),
                        textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LogIn()),
                        );
                        // Navigate to Login Screen
                      },
                      child: Text('Login'),
                    ),
                    SizedBox(height: 20),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFF3E81F3), // Blue color
                        side: BorderSide(color: Color(0xFF3E81F3), width: 2), // Blue border color
                        padding: EdgeInsets.symmetric(horizontal: 64, vertical: 16),
                        textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const SignIn()),
                        );
                        // Navigate to Signup Screen
                      },
                      child: Text('Sign Up'),
                    ),
                  ],
                ),
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
