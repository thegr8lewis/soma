import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:system_auth/screens/authenticate/log_in.dart';
import 'package:system_auth/screens/authenticate/sign_in.dart';
import 'package:system_auth/screens/onboarding/middlepage.dart';

class OnboardingScreen11 extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen11> {
  PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F2),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              IntroPage1(
                onNext: () {
                  // Navigate to the login page
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Middlepage()));
                },
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: List.generate(1, (index) {
                //     return Container(
                //       margin: EdgeInsets.symmetric(horizontal: 5),
                //       width: 10,
                //       height: 10,
                //       decoration: BoxDecoration(
                //         color:
                //             _currentPage == index ? Colors.black : Colors.grey,
                //         shape: BoxShape.circle,
                //       ),
                //     );
                //   }),
                // ),
                SizedBox(height: 10),
                // GestureDetector(
                //   onTap: () {
                //     // Navigate to sign-in page
                //     Navigator.push(context,
                //         MaterialPageRoute(builder: (context) => SignIn()));
                //   },
                //   child: Text(
                //     "Already have an account? Sign In",
                //     style: GoogleFonts.poppins(
                //       textStyle: TextStyle(
                //         fontSize: 16,
                //         color: Colors.black,
                //         decoration: TextDecoration.underline,
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class IntroPage1 extends StatelessWidget {
  final VoidCallback onNext;

  IntroPage1({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/caterpillar.json',
              repeat: true,
              width: 200,
              height: 200,
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                'Hello Smartypants and welcome to Soma App',
                style: GoogleFonts.poppins(
                  textStyle: TextStyle(
                    fontSize:23,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Unlock the world of knowledge and excel in your studies with Soma App',
              style: GoogleFonts.poppins(
                textStyle: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(400, 50),
                backgroundColor: Color(0xFF3E81F3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                "Let's Get Started",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}