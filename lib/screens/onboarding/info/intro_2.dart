import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IntroPage2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo or icon
                Image.asset(
                  'assets/realquestions.gif', // Replace with your app logo path
                  width: 200,
                  height: 200,
                ),
                SizedBox(height: 20),
                // Title
                Text(
                  'Thousands of Questions',
                  style: GoogleFonts.poppins(
                  textStyle: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                ),
                SizedBox(height: 20),
                // Subtitle
                Text(
                  ' Access a vast collection of questions tailored for junior school students across various subjects',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                  textStyle: TextStyle(
                    fontSize: 20,

                    color: Colors.black,
                  ),
                ),
                ),
                SizedBox(height: 40),
                // Description
                // Text(
                //   'Easily set personal goals and track your progress. Log your meals and monitor your nutrition.',
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
