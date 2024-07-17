import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:system_auth/config.dart'; // Make sure your BASE_URL is defined here
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:system_auth/screens/authenticate/grade.dart';
import 'package:system_auth/screens/authenticate/log_in.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:system_auth/screens/home/home.dart';

class SignIn extends StatefulWidget {
  const SignIn({Key? key}) : super(key: key);

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final _storage = const FlutterSecureStorage(); // Initialize the secure storage

  bool _obscureText = true;
  bool _isSignUpButtonEnabled = false;
  bool _isLoading = false;
  bool _passwordsMatch = true;
  bool _passwordWeak = false;
  bool _passwordStarted = false;
  bool _confirmPasswordStarted = false;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _validateForm() {
    setState(() {
      _passwordWeak = _passwordStarted && _passwordController.text.length < 6;
      _passwordsMatch = _confirmPasswordStarted &&
          _passwordController.text == _confirmPasswordController.text;
      _isSignUpButtonEnabled = _emailController.text.contains('@gmail.com') &&
          !_passwordWeak &&
          _passwordsMatch;
    });
  }

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true; // Show the loader
    });

    final String username = _nameController.text;
    final String email = _emailController.text;
    final String password = _passwordController.text;

    final response = await http.post(
      Uri.parse('$BASE_URL/register'), // Adjust the URL as needed
      headers: {'Content-Type': 'application/json'},
      body: json.encode(
          {'username': username, 'email': email, 'password': password}),
    );

    setState(() {
      _isLoading = false; // Hide the loader
    });

    if (response.statusCode == 201) {
      final data = json.decode(response.body);

      // Clear any existing session data
      await _storage.deleteAll();

      // Store new session data
      await _storage.write(key: 'access_token', value: data['access_token']);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LogIn()),
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Sign Up Failed'),
            content: const Text('Failed to create account. Please try again.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
    _passwordController.addListener(() {
      if (!_passwordStarted) {
        setState(() {
          _passwordStarted = true;
        });
      }
      _validateForm();
    });
    _confirmPasswordController.addListener(() {
      if (!_confirmPasswordStarted) {
        setState(() {
          _confirmPasswordStarted = true;
        });
      }
      _validateForm();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: screenWidth,
        height: screenHeight,
        color: const Color(0xFFFDF7F2),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: screenHeight * 0.05,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: screenHeight * 0.07),
                    Align(
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/soma3.png',
                        height: screenHeight * 0.15,
                        width: screenWidth * 0.3,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Text(
                      'Enter the details to continue',
                      style: GoogleFonts.poppins(
                        textStyle: TextStyle(
                          fontSize: screenHeight * 0.025,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Container(
                      width: screenWidth * 0.9,
                      height: screenHeight * 0.08,
                      child: TextField(
                        controller: _nameController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.person, color: Colors.white),
                          hintText: 'Name',
                          hintStyle: const TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: Colors.grey[600],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.green),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.012),
                    Container(
                      width: screenWidth * 0.9,
                      height: screenHeight * 0.08,
                      child: TextField(
                        controller: _emailController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.email, color: Colors.white),
                          hintText: 'Email: xyz123@mail.com',
                          hintStyle: const TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: Colors.grey[600],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.green),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.012),
                    Container(
                      width: screenWidth * 0.9,
                      height: screenHeight * 0.08,
                      child: TextField(
                        controller: _passwordController,
                        style: TextStyle(color: Colors.white),
                        obscureText: _obscureText,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.lock, color: Colors.white),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText ? Icons.visibility_outlined : Icons.visibility_off,
                              color: Colors.white,
                            ),
                            onPressed: _togglePasswordVisibility,
                          ),
                          hintText: 'Password',
                          hintStyle: const TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: Colors.grey[600],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.green),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.012),
                    Container(
                      width: screenWidth * 0.9,
                      height: screenHeight * 0.08,
                      child: TextField(
                        controller: _confirmPasswordController,
                        style: TextStyle(
                          color: _passwordsMatch ? Colors.white : Colors.red,
                        ),
                        obscureText: _obscureText,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.lock, color: Colors.white),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText ? Icons.visibility_outlined : Icons.visibility_off,
                              color: Colors.white,
                            ),
                            onPressed: _togglePasswordVisibility,
                          ),
                          hintText: 'Confirm Password',
                          hintStyle: const TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: Colors.grey[600],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: _passwordsMatch ? Colors.green : Colors.red,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    if (_confirmPasswordStarted && !_passwordsMatch)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          "password don't match",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    if (_passwordStarted && _passwordWeak)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          "password weak",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    SizedBox(height: screenHeight * 0.012),
                    ElevatedButton(
                      onPressed: _isSignUpButtonEnabled ? _signUp : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[500],
                        textStyle: TextStyle(fontSize: screenHeight * 0.02),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.015,
                          horizontal: screenWidth * 0.3,
                        ),
                      ),
                      child: Text(
                        'Sign up',
                        style: GoogleFonts.poppins(
                          textStyle: TextStyle(
                            fontSize: screenHeight * 0.02,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.12),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account?',
                              style: GoogleFonts.poppins(
                                textStyle: TextStyle(
                                  fontSize: screenHeight * 0.02,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LogIn()),
                                );
                              },
                              child: Text(
                                'Sign In',
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: screenHeight * 0.02,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.02),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Container(
                width: screenWidth,
                height: screenHeight,
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: LoadingAnimationWidget.staggeredDotsWave(
                    color: Colors.teal,
                    size: screenHeight * 0.1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}