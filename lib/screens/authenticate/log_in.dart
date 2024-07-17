import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:system_auth/screens/authenticate/forgot_pass.dart';
import 'package:system_auth/screens/authenticate/grade.dart';
import 'package:system_auth/screens/authenticate/sign_in.dart';
import 'package:system_auth/screens/home/home.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:system_auth/trialpages/apply.dart';
import 'package:system_auth/trialpages/trial2.dart';

import '../../config.dart';

class LogIn extends StatefulWidget {
  const LogIn({Key? key}) : super(key: key);

  @override
  State<LogIn> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LogIn> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ValueNotifier<bool> _isButtonEnabled = ValueNotifier(false);

  bool _obscureText = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  String? _sessionCookie;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _checkFields() {
    _isButtonEnabled.value =
        _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty;
    _rememberMe;
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_checkFields);
    _passwordController.addListener(_checkFields);
    _loadRememberMe();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _animation = Tween<double>(begin: 1.0, end: 0.95).animate(_animationController);
  }

  @override
  void dispose() {
    _emailController.removeListener(_checkFields);
    _passwordController.removeListener(_checkFields);
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRememberMe() async {
    bool rememberMe = (await _storage.read(key: 'remember_me')) == 'true';
    if (rememberMe) {
      String? email = await _storage.read(key: 'email');
      if (email != null) {
        _emailController.text = email;
      }
    }
    setState(() {
      _rememberMe = rememberMe;
    });
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    final String email = _emailController.text;
    final String password = _passwordController.text;

    final response = await http.post(
      Uri.parse('$BASE_URL/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        'remember': _rememberMe,
      }),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Extract the session cookie from the response headers if remember me is true
      if (_rememberMe) {
        final cookies = response.headers['set-cookie'];
        if (cookies != null) {
          _sessionCookie = cookies;
          await _storage.write(key: 'session_cookie', value: cookies);
        }

        await _storage.write(key: 'remember_me', value: 'true');
        await _storage.write(key: 'email', value: email);
      } else {
        await _storage.delete(key: 'remember_me');
        await _storage.delete(key: 'email');
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) =>  const GradePage()),
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Login Failed'),
            content: const Text('Invalid email or password'),
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
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: screenWidth,
        height: screenHeight,
        // color: const Color(0xFF00072D),
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
                    SizedBox(height: screenHeight * 0.05),
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
                      'Enter your email and Password',
                      style: GoogleFonts.poppins(
                        textStyle: TextStyle(
                          fontSize: screenHeight * 0.025,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    TextField(
                      controller: _emailController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.email, color: Colors.white),
                        hintText: 'Email: brian@gmail.com',
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
                        contentPadding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.02,
                          horizontal: screenWidth * 0.04,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    TextField(
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
                        contentPadding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.02,
                          horizontal: screenWidth * 0.04,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            ValueListenableBuilder<bool>(
                              valueListenable: _isButtonEnabled,
                              builder: (context, value, child) {
                                return Switch(
                                  value: _rememberMe,
                                  onChanged: value
                                      ? (bool newValue) {
                                    setState(() {
                                      _rememberMe = newValue;
                                    });
                                  }
                                      : null,
                                  activeColor: Colors.green,
                                );
                              },
                            ),
                            Text(
                              'Remember me',
                              style: GoogleFonts.poppins(
                                textStyle: TextStyle(
                                  fontSize: screenHeight * 0.014,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ForgotPass()),
                            );
                          },
                          child: Text(
                            'Forgot password?',
                            style: GoogleFonts.poppins(
                              textStyle: TextStyle(
                                fontSize: screenHeight * 0.015,
                                // fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    ValueListenableBuilder<bool>(
                      valueListenable: _isButtonEnabled,
                      builder: (context, value, child) {
                        return ScaleTransition(
                          scale: _animation,
                          child: ElevatedButton(
                            onPressed: value
                                ? () {
                              _animationController.forward().then((_) {
                                _animationController.reverse();
                                _login();
                              });
                            }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[500],
                              textStyle: TextStyle(fontSize: screenHeight * 0.025),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.010,
                                horizontal: screenWidth * 0.3,
                              ),
                            ),
                            child: Text(
                              'Login',
                              style: GoogleFonts.poppins(
                                textStyle: TextStyle(
                                  fontSize: screenHeight * 0.025,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: screenHeight * 0.1),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: GoogleFonts.poppins(
                                textStyle: TextStyle(
                                  fontSize: screenHeight * 0.019,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SignIn()),
                                );
                              },
                              child: Text(
                                'Create new one',
                                style: GoogleFonts.poppins(
                                  textStyle: TextStyle(
                                    fontSize: screenHeight * 0.015,
                                    color: Colors.blueAccent,
                                  ),
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