import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IntroPage5 extends StatelessWidget {
  const IntroPage5({super.key});

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
                Column(
                  children: [
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      'assets/rightcelebrate.gif',
                                      width: 200,
                                      height: 200,
                                    ),
                                    Image.asset(
                                      'assets/celebr.gif',
                                      width: 200,
                                      height: 200,
                                    ),
                                  ],
                                ),
                                Align(
                                  alignment: Alignment.center,
                                  child: Image.asset(
                                    'assets/welcome.gif',
                                    width: 200,
                                    height: 200,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),

                Text(
                  'Welcome to Our Learning Community!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                  textStyle: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                ),
                const SizedBox(height: 20),
                // Subtitle
                Text(
                  'We’re thrilled to have you join us! Dive in, explore, and enjoy your learning journey with Soma App',
                  textAlign: TextAlign.center,
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
                //   'Join groups and communities to see events, share tasks, and collaborate with others. Connect with friends, family, and colleagues.',
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
