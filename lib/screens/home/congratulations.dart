import 'package:flutter/material.dart';

import '../../trialpages/apply.dart';

class CongratulationsPage extends StatelessWidget {
  final int score;
  final int totalQuestions;

  CongratulationsPage({required this.score, required this.totalQuestions});

  @override
  Widget build(BuildContext context) {
    double percentage = (score / totalQuestions) * 100;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: Colors.orange[300],
                    size: 200,
                  ),
                  const Positioned(
                    bottom: 40,
                    child: Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                  const Positioned(
                    bottom: 0,
                    child: Icon(
                      Icons.emoji_events,
                      color: Colors.blue,
                      size: 50,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Congratulations',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'You did a great job in the test!',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Text(
                'Your Score: ${percentage.toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const Homepage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 64),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
