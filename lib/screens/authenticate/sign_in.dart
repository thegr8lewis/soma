import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:system_auth/config.dart'; // Make sure your BASE_URL is defined here
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:system_auth/screens/authenticate/log_in.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final _storage =
      const FlutterSecureStorage(); // Initialize the secure storage

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
      } else if (response.statusCode == 409) {
        // Assuming 409 is the status code for email already exists
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF81C784),
              Color(0xFF4CAF50),
              Color(0xFF2E7D32),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative elements
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: screenHeight * 0.05,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: screenHeight * 0.05),
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
                      Icons.person_outlined,
                    ),
                    SizedBox(height: screenHeight * 0.012),
                    _buildTextField(
                      screenHeight,
                      screenWidth,
                      _emailController,
                      'Email',
                      Icons.email_outlined,
                    ),
                    SizedBox(height: screenHeight * 0.012),
                    _buildPasswordTextField(screenHeight, screenWidth),
                    SizedBox(height: screenHeight * 0.012),
                    _buildConfirmPasswordTextField(screenHeight, screenWidth),
                    if (_confirmPasswordStarted && !_passwordsMatch)
                      _buildErrorMessage("Passwords don't match"),
                    if (_passwordStarted && _passwordWeak)
                      _buildErrorMessage("Password is weak"),
                    if (_emailExists)
                      _buildErrorMessage("The email already exists"),
                    if (_errorMessage != null)
                      _buildErrorMessage(_errorMessage!),
                    SizedBox(height: screenHeight * 0.05),
                    _buildSignUpButton(screenHeight, screenWidth),
                    SizedBox(height: screenHeight * 0.04),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/soma3.png',
            height: screenHeight * 0.12,
            width: screenWidth * 0.25,
            color: const Color(0xFF2E7D32),
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            'SOMA',
            style: GoogleFonts.poppins(
              textStyle: TextStyle(
                fontSize: screenHeight * 0.035,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E7D32),
                letterSpacing: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(double screenHeight) {
    return const Center(
        // child: Text(
        //   'Access Education under the dollar',
        //   style: GoogleFonts.poppins(
        //     textStyle: TextStyle(
        //       fontSize: screenHeight * 0.025,
        //       fontWeight: FontWeight.w100,
        //       color: Colors.black,
        //     ),
        //   ),
        // ),
        );
  }

  Widget _buildSubtitle(double screenHeight) {
    return Text(
      'Create Your Account',
      style: GoogleFonts.poppins(
        textStyle: TextStyle(
          fontSize: screenHeight * 0.035,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(
          color: Colors.black87,
          fontSize: screenHeight * 0.022,
        ),
        decoration: InputDecoration(
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF2E7D32)),
          ),
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.black54,
            fontSize: screenHeight * 0.02,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordTextField(double screenHeight, double screenWidth) {
    return Container(
      width: screenWidth * 0.9,
      height: screenHeight * 0.08,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _passwordController,
        style: TextStyle(
          color: Colors.black87,
          fontSize: screenHeight * 0.022,
        ),
        obscureText: _obscureText,
        decoration: InputDecoration(
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lock_outlined, color: Color(0xFF2E7D32)),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility_outlined : Icons.visibility_off,
              color: const Color(0xFF2E7D32),
            ),
            onPressed: _togglePasswordVisibility,
          ),
          hintText: 'Password',
          hintStyle: TextStyle(
            color: Colors.black54,
            fontSize: screenHeight * 0.02,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmPasswordTextField(
      double screenHeight, double screenWidth) {
    return Container(
      width: screenWidth * 0.9,
      height: screenHeight * 0.08,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _confirmPasswordController,
        style: TextStyle(
          color: _passwordsMatch ? Colors.black87 : Colors.red,
          fontSize: screenHeight * 0.022,
        ),
        obscureText: _obscureText,
        decoration: InputDecoration(
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lock_outlined, color: Color(0xFF2E7D32)),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility_outlined : Icons.visibility_off,
              color: const Color(0xFF2E7D32),
            ),
            onPressed: _togglePasswordVisibility,
          ),
          hintText: 'Confirm Password',
          hintStyle: TextStyle(
            color: Colors.black54,
            fontSize: screenHeight * 0.02,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpButton(double screenHeight, double screenWidth) {
    return Container(
      width: double.infinity,
      height: screenHeight * 0.07,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: _isSignUpButtonEnabled
            ? const LinearGradient(
                colors: [
                  Color(0xFF66BB6A),
                  Color(0xFF4CAF50),
                  Color(0xFF388E3C)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Colors.grey.shade400, Colors.grey.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: _isSignUpButtonEnabled
            ? [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: _isSignUpButtonEnabled ? _signUp : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Visibility(
              visible: !_isLoading,
              child: Text(
                'Create Account',
                style: GoogleFonts.poppins(
                  textStyle: TextStyle(
                    fontSize: screenHeight * 0.025,
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
      ),
    );
  }

  Widget _buildSignInOption(double screenHeight) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have an account?',
            style: GoogleFonts.poppins(
              textStyle: TextStyle(
                fontSize: screenHeight * 0.022,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LogIn()),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF4CAF50), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            child: Text(
              'Sign In',
              style: GoogleFonts.poppins(
                textStyle: TextStyle(
                  color: const Color(0xFF2E7D32),
                  fontSize: screenHeight * 0.022,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 8.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
