import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:system_auth/trialpages/apply.dart';

class CongratulationsPage extends StatelessWidget {
  final int score;
  final int totalQuestions;
  final int questionsAttempted;
  final int originalQuestionCount;
  final List<dynamic> wrongQuestions;
  final VoidCallback? onReviewWrongAnswers;

  const CongratulationsPage({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.questionsAttempted,
    required this.originalQuestionCount,
    this.wrongQuestions = const [],
    this.onReviewWrongAnswers,
  });

  double calculatePercentage() {
    if (questionsAttempted == 0) return 0;
    // Calculate the raw percentage and ensure it doesn't exceed 100%
    double rawPercentage = (score / (originalQuestionCount * 10)) * 100;
    return rawPercentage > 100 ? 100 : rawPercentage;
  }

  @override
  Widget build(BuildContext context) {
    final percentage = calculatePercentage();

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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animation section
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 160, // Further reduced size
                          height: 160, // Further reduced size
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
                          wrongQuestions.isEmpty && onReviewWrongAnswers == null
                              ? 'assets/celebr.gif'
                              : 'assets/congratulations.json',
                          repeat: true,
                          width: 200, // Further reduced size
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Congratulations Title
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade400,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        wrongQuestions.isEmpty && onReviewWrongAnswers == null
                            ? 'All Corrected!'
                            : 'Congratulations!',
                        style: GoogleFonts.fredoka(
                          textStyle: const TextStyle(
                            fontSize: 24, // Smaller text
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Percentage display with reduced size
                    Container(
                      width: 120, // Further reduced size
                      height: 120, // Further reduced size
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: percentage >= 80
                              ? [
                                  const Color(0xFF4CAF50),
                                  const Color(0xFF8BC34A)
                                ]
                              : percentage >= 60
                                  ? [
                                      const Color(0xFF8BC34A),
                                      const Color(0xFFCDDC39)
                                    ]
                                  : percentage >= 40
                                      ? [
                                          const Color(0xFFFFC107),
                                          const Color(0xFFFFEB3B)
                                        ]
                                      : [
                                          const Color(0xFFFF9800),
                                          const Color(0xFFFFEB3B)
                                        ],
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
                              fontSize: 30, // Smaller font
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      '$score pts',
                      style: GoogleFonts.fredoka(
                        textStyle: const TextStyle(
                          fontSize: 22, // Smaller text
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3F51B5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // "Back to Home" button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Homepage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF3F51B5),
                          shadowColor: Colors.black.withOpacity(0.3),
                          elevation: 5, // Less elevation
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 10), // Further reduced padding
                        ),
                        child: Text(
                          'Back to Home',
                          style: GoogleFonts.fredoka(
                            textStyle: const TextStyle(
                              fontSize: 18, // Smaller text
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // "Review Wrong Questions" button - only show if there are wrong questions and callback is provided
                    if (wrongQuestions.isNotEmpty &&
                        onReviewWrongAnswers != null) ...[
                      const SizedBox(height: 12), // Reduced spacing
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: onReviewWrongAnswers,
                          icon: const Icon(Icons.refresh,
                              color: Colors.white, size: 18), // Smaller icon
                          label: Text(
                            'Review Wrong Answers (${wrongQuestions.length})',
                            style: GoogleFonts.fredoka(
                              textStyle: const TextStyle(
                                fontSize: 14, // Smaller text
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 10), // Further reduced padding
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 3, // Less elevation
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 10), // Further reduced final spacing
                  ],
                ),
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
