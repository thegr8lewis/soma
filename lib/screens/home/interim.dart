import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:system_auth/models/modelquestions.dart';
import 'package:system_auth/trialpages/apply.dart';

class InterimResultsPage extends StatelessWidget {
  final int score;
  final List<Question> wrongQuestions;
  final int batchNumber;
  final Function() onContinue;
  final int totalQuestions;

  const InterimResultsPage({
    super.key,
    required this.score,
    required this.wrongQuestions,
    required this.batchNumber,
    required this.onContinue,
    required this.totalQuestions,
  });

  double calculatePercentage() {
    if (batchNumber == 0) return 0;
    // Calculate raw percentage based on score and questions attempted
    double rawPercentage = (score / (batchNumber * 10)) * 100;
    // Ensure percentage doesn't exceed 100%
    return rawPercentage > 100 ? 100 : rawPercentage;
  }

  @override
  Widget build(BuildContext context) {
    final percentage = calculatePercentage();
    final bool hasMoreQuestions =
        batchNumber * 10 < totalQuestions || wrongQuestions.isNotEmpty;

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
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animation section
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 180,
                        height: 180,
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
                        'assets/loader.json',
                        repeat: true,
                        width: 220,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Percentage display
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
                        Text(
                          'Your Score',
                          style: GoogleFonts.fredoka(
                            textStyle: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3F51B5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: percentage >= 80
                                  ? [
                                      const Color(0xFF4CAF50),
                                      const Color(0xFF8BC34A)
                                    ] // Green gradient for high scores
                                  : percentage >= 60
                                      ? [
                                          const Color(0xFF8BC34A),
                                          const Color(0xFFCDDC39)
                                        ] // Light green for good scores
                                      : percentage >= 40
                                          ? [
                                              const Color(0xFFFFC107),
                                              const Color(0xFFFFEB3B)
                                            ] // Yellow for average
                                          : [
                                              const Color(0xFFFF9800),
                                              const Color(0xFFFFEB3B)
                                            ], // Orange for low scores
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${percentage.toStringAsFixed(0)}%',
                              style: GoogleFonts.fredoka(
                                textStyle: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '$score pts',
                          style: GoogleFonts.fredoka(
                            textStyle: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3F51B5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),
                  // Action buttons
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Homepage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: const Color(0xFF7986CB),
                            shadowColor: Colors.black.withOpacity(0.3),
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.home),
                          label: Text(
                            'Home',
                            style: GoogleFonts.fredoka(
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: hasMoreQuestions ? onContinue : null,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: const Color(0xFF3F51B5),
                            disabledBackgroundColor: Colors.grey.shade400,
                            shadowColor: Colors.black.withOpacity(0.3),
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: Icon(
                            batchNumber * 10 >= totalQuestions &&
                                    wrongQuestions.isNotEmpty
                                ? Icons.refresh
                                : Icons.arrow_forward,
                          ),
                          label: Text(
                            batchNumber * 10 >= totalQuestions &&
                                    wrongQuestions.isNotEmpty
                                ? 'Review Wrong Answers'
                                : 'Continue Learning',
                            style: GoogleFonts.fredoka(
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color determineProgressColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.lightGreen;
    if (percentage >= 40) return Colors.amber;
    return Colors.orange;
  }
}
