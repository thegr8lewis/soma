import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IntroPage3 extends StatelessWidget {
  const IntroPage3({super.key});

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
                Image.asset(
                  'assets/instantanswers.gif', 
                  width: 200,
                  height: 200,
                ),
                Center(
                  child: Text(
                    'Instant Answers & Detailed Explanations',
                    style: GoogleFonts.poppins(
                  textStyle: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                      color: Colors.black
                  ),
                ),
                  ),
                ),
                const SizedBox(height: 20),
                // Subtitle
                Text(
                  'Get instant answers with detailed explanations to help you understand better and learn faster',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                  textStyle: const TextStyle(
                    fontSize: 20,

                      color: Colors.black
                  ),
                ),
                ),
                const SizedBox(height: 40),
                // Description
                // Text(
                //   'Track your goals, tasks, and meals with interactive dashboards, graphs, and charts. See your progress visually and make informed decisions.',
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
