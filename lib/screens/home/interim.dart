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
    return (score / (batchNumber * 100)) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final percentage = calculatePercentage();
    final bool hasMoreQuestions = batchNumber * 10 < totalQuestions || wrongQuestions.isNotEmpty;
    final String progressMessage = percentage >= 80 
      ? 'Excellent Progress!' 
      : percentage >= 60 
        ? 'Good Progress!' 
        : percentage >= 40 
          ? 'Nice Effort!' 
          : 'Keep Going!';
          
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
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animation and title section
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
                        'assets/loader.json', // Use a progress or ongoing animation
                        repeat: true,
                        width: 220,
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
                      'Batch $batchNumber Results',
                      style: GoogleFonts.fredoka(
                        textStyle: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    progressMessage,
                    style: GoogleFonts.fredoka(
                      textStyle: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3F51B5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Score container
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
                              'Current Score:',
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
                                '$score pts',
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
                        buildScoreRow('Batch Progress', '$batchNumber / ${(totalQuestions / 10).ceil()}', Colors.indigo.shade100),
                        const SizedBox(height: 8),
                        buildScoreRow('Questions Remaining', '${totalQuestions - (batchNumber * 10) > 0 ? totalQuestions - (batchNumber * 10) : 0}', Colors.blue.shade100),
                        const SizedBox(height: 8),
                        buildScoreRow('Wrong Answers', '${wrongQuestions.length}', 
                          wrongQuestions.isEmpty ? Colors.green.shade100 : Colors.amber.shade100),
                      ],
                    ),
                  ),
                  
                  // Progress visualization
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Progress',
                          style: GoogleFonts.fredoka(
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3F51B5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: batchNumber * 10 / totalQuestions,
                            backgroundColor: Colors.grey.shade200,
                            color: determineProgressColor(percentage),
                            minHeight: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(batchNumber * 10 / totalQuestions * 100).toStringAsFixed(0)}% Complete',
                          style: GoogleFonts.fredoka(
                            textStyle: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
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
                            batchNumber * 10 >= totalQuestions && wrongQuestions.isNotEmpty 
                                ? Icons.refresh : Icons.arrow_forward,
                          ),
                          label: Text(
                            batchNumber * 10 >= totalQuestions && wrongQuestions.isNotEmpty 
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
                  
                  // If we have wrong questions, show some details
                  if (wrongQuestions.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade200, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.red.shade400),
                              const SizedBox(width: 8),
                              Text(
                                'Review These Questions',
                                style: GoogleFonts.fredoka(
                                  textStyle: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You\'ll see ${wrongQuestions.length} question(s) you missed in the next batch.',
                            style: GoogleFonts.fredoka(
                              textStyle: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // Add bottom padding
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