import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:system_auth/config.dart';
import 'package:system_auth/screens/authenticate/log_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class ForgotPass extends StatefulWidget {
  const ForgotPass({super.key});

  @override
  State<ForgotPass> createState() => _ForgotPassState();
}

class _ForgotPassState extends State<ForgotPass> {
  bool isEmailSelected = true;
  final TextEditingController _emailController = TextEditingController();
  bool isButtonEnabled = false;
  bool _isLoading = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateInput);
  }

  void _validateInput() {
    setState(() {
      isButtonEnabled = _emailController.text.isNotEmpty && _isValidEmail(_emailController.text);
    });
  }

  bool _isValidEmail(String email) {
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegExp.hasMatch(email);
  }

  Future<void> _sendOTP() async {
    setState(() {
      _isLoading = true;
      _message = null; // Clear previous message
    });

    final String email = _emailController.text;

    final response = await http.post(
      Uri.parse('$BASE_URL/forgot'), // Adjust the URL as needed
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    setState(() {
      _isLoading = false; // Hide the loader
    });

    if (response.statusCode == 200) {
      setState(() {
        _message = 'Check your email for the reset link';
      });
    } else {
      setState(() {
        _message = 'Failed to reset password. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF7F2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LogIn()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          width: screenWidth,
          height: screenHeight,
          color: const Color(0xFFFDF7F2),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Container(
                width: screenWidth * 0.9,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.06,
                  vertical: screenHeight * 0.045,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF7F2),
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      child: Lottie.asset(
                        'assets/books.json',
                        repeat: true,
                        width: screenWidth * 0.3,
                      ),
                    ),
                    Text(
                      'Forgot Password!',
                      style: TextStyle(
                        fontSize: screenHeight * 0.03,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Enter yor Email to get the reset link',
                        style: TextStyle(
                          fontSize: screenHeight * 0.018,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    Container(
                      width: screenWidth * 0.9,
                      height: screenHeight * 0.08,
                      child: TextField(
                        controller: _emailController,
                        style: TextStyle(color: Colors.black),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.email, color: Colors.grey),
                          hintText: 'Email',
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.green),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    if (_message != null)
                      Text(
                        _message!,
                        style: TextStyle(
                          fontSize: screenHeight * 0.018,
                          fontWeight: FontWeight.w500,
                          color: _message == 'Check your email for the reset link'
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    SizedBox(height: screenHeight * 0.02),
                    ElevatedButton(
                      onPressed: isButtonEnabled ? _sendOTP : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[500],
                        textStyle: TextStyle(fontSize: screenHeight * 0.02),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.015,
                          horizontal: screenWidth * 0.2,
                        ),
                      ),
                      child: _isLoading
                          ? LoadingAnimationWidget.staggeredDotsWave(
                        color: Colors.white,
                        size: screenHeight * 0.02,
                      )
                          : Text(
                        'Refactor',
                        style: TextStyle(
                          fontSize: screenHeight * 0.02,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
