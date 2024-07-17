import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'dart:convert';
// import 'package:flutter_tts/flutter_tts.dart';

import '../../config.dart';
import 'congratulations.dart';

class QuestionsPage extends StatefulWidget {
  final int topicId;
  final String topicName;
  final String subjectName;

  QuestionsPage({
    required this.topicId,
    required this.topicName,
    required this.subjectName,
  });

  @override
  _QuestionsPageState createState() => _QuestionsPageState();
}

class _QuestionsPageState extends State<QuestionsPage> {
  List<dynamic> questions = [];
  bool isLoading = true;
  String? errorMessage;
  int currentQuestionIndex = 0;
  String? selectedChoice;
  int score = 0;
  int questionsAttempted = 0;
  // FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    try {
      final response = await http.get(Uri.parse('$BASE_URL/questions/${widget.subjectName}/${widget.topicId}'));
      if (response.statusCode == 200) {
        setState(() {
          questions = json.decode(response.body) as List<dynamic>;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load questions';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void checkAnswer() {
    if (selectedChoice == null) return;

    String correctAnswer = questions[currentQuestionIndex]['correct_answer'];
    bool isCorrect = selectedChoice == correctAnswer;

    if (isCorrect) {
      score++;
    }

    questionsAttempted++;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      builder: (BuildContext context) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          color: const Color(0xFF212121), // Dark background color
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect ? Colors.green : Colors.red,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isCorrect ? 'Great job!' : 'Incorrect',
                    style: TextStyle(
                      color: isCorrect ? Colors.green : Colors.red,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (!isCorrect) ...[
                const SizedBox(height: 10),
                const Text(
                  'Correct Answer:',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 18,
                  ),
                ),
                Text(
                  correctAnswer,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (currentQuestionIndex + 1 < questions.length) {
                    setState(() {
                      currentQuestionIndex++;
                      selectedChoice = null;
                    });
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CongratulationsPage(
                          score: score,
                          totalQuestions: questionsAttempted,
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCorrect ? Colors.green : Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 64),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isCorrect ? 'CONTINUE' : 'GOT IT',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void skipQuestion() {
    setState(() {
      currentQuestionIndex++;
      selectedChoice = null;
      if (currentQuestionIndex >= questions.length) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CongratulationsPage(
              score: score,
              totalQuestions: questionsAttempted,
            ),
          ),
        );
      }
    });
  }

  // Future<void> speak(String text) async {
  //   await flutterTts.setLanguage("en-US");
  //   await flutterTts.setPitch(1.0);
  //   await flutterTts.speak(text);
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.topicName} Questions'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : questions.isEmpty
          ? const Center(child: Text('No questions available'))
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: questionsAttempted / questions.length,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${questionsAttempted}/${questions.length}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: currentQuestionIndex >= questions.length - 1 ? null : skipQuestion,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.orange[800],
                      ),
                      child: const Text('Skip'),
                    ),
                    ElevatedButton(
                      onPressed: questionsAttempted == 0 ? null : () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CongratulationsPage(
                              score: score,
                              totalQuestions: questionsAttempted,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: questionsAttempted == 0 ? Colors.grey : Colors.blue[800],
                      ),
                      child: const Text('Results'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: currentQuestionIndex < questions.length
                ? buildQuestion()
                : const Center(child: Text('You have completed the quiz!')),
          ),
        ],
      ),
    );
  }

  Widget buildQuestion() {
    var question = questions[currentQuestionIndex];
    var options = question['options'] as List<dynamic>;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 150, // Set the desired width
                height: 150, // Set the desired height
                child: Lottie.network('https://lottie.host/c4d75a88-82d9-460a-910a-7757db3c3d3d/lJiU0DGYeW.json'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      question['question'],
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: options
                .map((option) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedChoice = option;
                  });
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: selectedChoice == option ? Colors.green[700] : Colors.orange[400],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    option,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ))
                .toList(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: checkAnswer,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue[800],
            ),
            child: const Text('Check Answer'),
          ),
        ],
      ),
    );
  }
}
