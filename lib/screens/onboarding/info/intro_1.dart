import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IntroPage1 extends StatelessWidget {
  const IntroPage1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo or icon
                Image.asset(
                  'assets/welcome.gif', // Replace with your app logo path
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 20),
                // Title
                Center(
                  child: Text(
                    'Hello Smartypants and welcome to Soma App',
                    style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  ),
                ),
                const SizedBox(height: 20),
                // Subtitle
                Text(
                  'Unlock the world of knowledge and excel in your studies with Soma App',
                 style: GoogleFonts.poppins(
                  textStyle: const TextStyle(
                    fontSize: 20,

                    color: Colors.black,
                  ),
                ),
                ),
                const SizedBox(height: 40),
                // Description
                // Text(
                //   'Organize your tasks, track your goals, and manage your meals with ease.',
                //   textAlign: TextAlign.center,
                //   style: TextStyle(
                //     fontSize: 18,
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
