import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:system_auth/trialpages/apply.dart';

class CongratulationsPage extends StatelessWidget {
  final int score;
  final int totalQuestions;
  final int questionsAttempted;
  final int originalQuestionCount;

  const CongratulationsPage({
    super.key, 
    required this.score,
    required this.totalQuestions,
    required this.questionsAttempted,
    required this.originalQuestionCount,
  });

  double calculatePercentage() {
    if (questionsAttempted == 0) return 0;
    return (score / (originalQuestionCount * 10)) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final percentage = calculatePercentage();
    final String message = percentage >= 80 
      ? 'Excellent Work!' 
      : percentage >= 60 
        ? 'Good Job!' 
        : percentage >= 40 
          ? 'Nice Effort!' 
          : 'Keep Practicing!';
          
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8C9EFF), // Light indigo
              Color(0xFFE8EAF6), // Very light indigo
            ],
          ),
        ),
        // Wrap the content in a SingleChildScrollView to prevent overflow
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animation and title section - no changes needed
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.indigo.withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                      Lottie.asset(
                        'assets/congratulations.json',
                        repeat: true,
                        width: 250,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade400,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      'Congratulations!',
                      style: GoogleFonts.fredoka(
                        textStyle: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    message,
                    style: GoogleFonts.fredoka(
                      textStyle: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3F51B5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Score container - no changes needed
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Final Score:',
                              style: GoogleFonts.fredoka(
                                textStyle: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: percentage >= 80 
                                    ? [const Color(0xFF4CAF50), const Color(0xFF8BC34A)] // Green gradient for high scores
                                    : percentage >= 60 
                                      ? [const Color(0xFF8BC34A), const Color(0xFFCDDC39)] // Light green for good scores
                                      : percentage >= 40 
                                        ? [const Color(0xFFFFC107), const Color(0xFFFFEB3B)] // Yellow for average
                                        : [const Color(0xFFFF9800), const Color(0xFFFFEB3B)], // Orange for low scores
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: GoogleFonts.fredoka(
                                  textStyle: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        buildScoreRow('Questions Attempted', '$questionsAttempted', Colors.indigo.shade100),
                        const SizedBox(height: 8),
                        buildScoreRow('Total Questions', '$originalQuestionCount', Colors.blue.shade100),
                        const SizedBox(height: 8),
                        buildScoreRow('Points Earned', '$score', Colors.amber.shade100),
                      ],
                    ),
                  ),
                  // Add more padding before the button to ensure it's visible
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                     Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Homepage()),
        );  
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, 
                      backgroundColor: const Color(0xFF3F51B5),
                      shadowColor: Colors.black.withOpacity(0.3),
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: Text(
                      'Back to Home',
                      style: GoogleFonts.fredoka(
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Add additional padding at the bottom to avoid any issues
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget buildScoreRow(String label, String value, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.fredoka(
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.fredoka(
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3F51B5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
