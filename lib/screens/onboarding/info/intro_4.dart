import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IntroPage4 extends StatelessWidget {
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
                Image.asset(
                  'assets/niceprogress.gif',
                  width: 200,
                  height: 200,
                ),
                Text(
                  'Track Your Progress',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                        color: Colors.black
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // Subtitle
                // Text(
                //   'Monitor your progress with our easy-to-use tracking features. See your improvements and stay motivated',
                //   textAlign: TextAlign.center,
                //   style: TextStyle(
                //     fontSize: 24,
                //     color: Colors.blueGrey,
                //   ),
                // ),
                SizedBox(height: 40),
                // Description
                Text(
                  'Join groups and communities to see events, share tasks, and collaborate with others. Connect with friends, family, and colleagues.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
