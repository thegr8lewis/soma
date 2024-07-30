import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:system_auth/config.dart'; // Make sure your BASE_URL is defined here
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  bool _emailExists = false;
  String? _errorMessage;

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
      _errorMessage = null; // Clear previous error messages
    });

    final String username = _nameController.text;
    final String email = _emailController.text;
    final String password = _passwordController.text;

    try {
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
      } else if (response.statusCode == 409) { // Assuming 409 is the status code for email already exists
        setState(() {
          _emailExists = true;
          _errorMessage = 'The email already exists';
        });
      } else {
        setState(() {
          _errorMessage = 'Sign Up Failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please check your internet connection and try again.';
      });
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
                    _buildLogo(screenHeight, screenWidth),
                    SizedBox(height: screenHeight * 0.03),
                    _buildTitle(screenHeight),
                    SizedBox(height: screenHeight * 0.01),
                    _buildSubtitle(screenHeight),
                    SizedBox(height: screenHeight * 0.03),
                    _buildTextField(
                      screenHeight,
                      screenWidth,
                      _nameController,
                      'Name',
                      Icons.person,
                    ),
                    SizedBox(height: screenHeight * 0.012),
                    _buildTextField(
                      screenHeight,
                      screenWidth,
                      _emailController,
                      'Email: xyz123@mail.com',
                      Icons.email,
                    ),
                    SizedBox(height: screenHeight * 0.012),
                    _buildPasswordTextField(screenHeight, screenWidth),
                    SizedBox(height: screenHeight * 0.012),
                    _buildConfirmPasswordTextField(screenHeight, screenWidth),
                    if (_confirmPasswordStarted && !_passwordsMatch)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Passwords don't match",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    if (_passwordStarted && _passwordWeak)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Password is weak",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    if (_emailExists)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          "The email already exists",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    SizedBox(height: screenHeight * 0.012),
                    _buildSignUpButton(screenHeight, screenWidth),
                    SizedBox(height: screenHeight * 0.09),
                    _buildSignInOption(screenHeight),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(double screenHeight, double screenWidth) {
    return Align(
      alignment: Alignment.center,
      child: Image.asset(
        'assets/soma3.png',
        height: screenHeight * 0.15,
        width: screenWidth * 0.3,
        color: Colors.black,
      ),
    );
  }

  Widget _buildTitle(double screenHeight) {
    return Center(
      child: Text(
        'Access Education under the dollar',
        style: GoogleFonts.poppins(
          textStyle: TextStyle(
            fontSize: screenHeight * 0.025,
            fontWeight: FontWeight.w100,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle(double screenHeight) {
    return Text(
      'Enter the details to continue',
      style: GoogleFonts.poppins(
        textStyle: TextStyle(
          fontSize: screenHeight * 0.025,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildTextField(double screenHeight, double screenWidth,
      TextEditingController controller, String hintText, IconData icon) {
    return Container(
      width: screenWidth * 0.9,
      height: screenHeight * 0.08,
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white),
          hintText: hintText,
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
    );
  }

  Widget _buildPasswordTextField(double screenHeight, double screenWidth) {
    return Container(
      width: screenWidth * 0.9,
      height: screenHeight * 0.08,
      child: TextField(
        controller: _passwordController,
        style: const TextStyle(color: Colors.white),
        obscureText: _obscureText,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock, color: Colors.white),
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
    );
  }

  Widget _buildConfirmPasswordTextField(double screenHeight, double screenWidth) {
    return Container(
      width: screenWidth * 0.9,
      height: screenHeight * 0.08,
      child: TextField(
        controller: _confirmPasswordController,
        style: TextStyle(
          color: _passwordsMatch ? Colors.white : Colors.red,
        ),
        obscureText: _obscureText,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock, color: Colors.white),
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
    );
  }

  Widget _buildSignUpButton(double screenHeight, double screenWidth) {
    return ElevatedButton(
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          Visibility(
            visible: !_isLoading,
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
          Visibility(
            visible: _isLoading,
            child: LoadingAnimationWidget.staggeredDotsWave(
              color: Colors.white,
              size: screenHeight * 0.04,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInOption(double screenHeight) {
    return Column(
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
    );
  }
}
