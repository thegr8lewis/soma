import 'package:flutter/material.dart';
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
  bool _isLoading = false; // Add this line

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
      _isLoading = true; // Show the loader
    });

    final String email = _emailController.text;

    final response = await http.post(
      Uri.parse('$BASE_URL/forgot'), // Adjust the URL as needed
      headers: {'Content-Type': 'application/json'},
      body: json.encode({ 'email': email}),
    );

    setState(() {
      _isLoading = false; // Hide the loader
    });

    if (response.statusCode == 200) {
      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Password reset Successful'),
              content: const Text('Check your email for the reset link'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LogIn()), // Assuming 'HomePage' is the home page widget
                    );
                  },
                ),
              ],
            );
          },
        );
      }

    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Password reset failed'),
            content: const Text('Failed to reset password. Please try again.'),
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor:const Color(0xFF00072D),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LogIn()),
            );
          },
        ),
      ),
     body: Container(
       color: const Color(0xFF00072D),
       child: Stack(
         children: [
           Center(
             child: Padding(
               padding: const EdgeInsets.all(16.0),
               child: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
                 decoration: BoxDecoration(
                   color: const Color(0xFF00072D),
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
                     const Text(
                       'Forgot Password!',
                       style: TextStyle(
                         fontSize: 24,
                         fontWeight: FontWeight.bold,
                         color: Colors.white,
                       ),
                     ),
                     const SizedBox(height: 16),
                     Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         _buildOptionButton('Email ID', isEmailSelected),
                       ],
                     ),
                     const SizedBox(height: 16),
                     const Align(
                       alignment: Alignment.centerLeft,
                       child: Text(
                         'Enter the Registered Mail ID to get OTP',
                         style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white,),
                       ),
                     ),
                     const SizedBox(height: 8),
                     TextField(
                       controller: _emailController,
                       style: TextStyle(color: Colors.white),
                       keyboardType: TextInputType.emailAddress,
                       decoration: InputDecoration(
                         prefixIcon: Icon(Icons.email, color: Colors.white),
                         hintText: 'Email',
                         hintStyle: const TextStyle(color: Colors.white),
                         border: OutlineInputBorder(
                           borderRadius: BorderRadius.circular(10.0),
                         ),
                         focusedBorder: OutlineInputBorder(
                           borderSide: const BorderSide(color: Colors.green),
                           borderRadius: BorderRadius.circular(10),
                         ),
                       ),
                     ),
                     const SizedBox(height: 24),
                     ElevatedButton(
                       onPressed: isButtonEnabled ? _sendOTP : null,
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.green[500],
                         padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(10.0),
                         ),
                       ),
                       child: const Text('Send OTP',
                         style: TextStyle(
                           fontSize: 16,
                           color: Colors.white, // Grey color for the text
                         ),
                       ),
                     ),
                   ],
                 ),
               ),
             ),
           ),
           if (_isLoading)
             Scaffold(
               backgroundColor: Colors.black.withOpacity(0.5),
               body: Center(
                 child: LoadingAnimationWidget.staggeredDotsWave(
                   color: const Color(0xFF00796B),
                   size: 100,
                 ),
               ),
             ),
         ],
       ),
     ),
    );
  }

  Widget _buildOptionButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isEmailSelected = text == 'Email ID';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE0F2F1) : Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: isSelected ? const Color(0xFF00796B) : Colors.grey,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            color: isSelected ? const Color(0xFF00796B) : Colors.black,
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