import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CongratulationsPage extends StatelessWidget {
  final int score;
  final int totalQuestions;
  final int questionsAttempted;
  final int originalQuestionCount; // Add this

  CongratulationsPage({
    required this.score,
    required this.totalQuestions,
    required this.questionsAttempted,
    required this.originalQuestionCount, // Add this
  });

  double calculatePercentage() {
    if (questionsAttempted == 0) return 0;
    return (score / (originalQuestionCount * 10)) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                child: Lottie.asset(
                  'assets/congratulations.json',
                  repeat: true,
                  width: 180,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Congratulations!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'You scored ${calculatePercentage().toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                // 'Original Questions: $originalQuestionCount\n'
                'Total Attempts: $questionsAttempted',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 30),
          Text(
              'Final Score: ${calculatePercentage().toStringAsFixed(1)}%\n'
              'Questions Attempted: $questionsAttempted\n'
              'Total Questions: $originalQuestionCount',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),

              ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.blue, // Text color
                  shadowColor: Colors.black, // Shadow color
                  elevation: 5, // Elevation of the button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // Rounded corners
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15), // Padding inside the button
                ),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(
                    fontSize: 18, // Font size of the text
                    fontWeight: FontWeight.bold, // Font weight of the text
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}