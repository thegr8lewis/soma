import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart'; // Add this import for Lottie animations

import '../../config.dart';

class DailyQuizScreen extends StatefulWidget {
  @override
  _DailyQuizScreenState createState() => _DailyQuizScreenState();
}

class _DailyQuizScreenState extends State<DailyQuizScreen> {
  final _storage = const FlutterSecureStorage();

  List<dynamic> questions = [];
  bool isLoading = true;
  String errorMessage = '';
  int currentQuestionIndex = 0;
  String? selectedAnswer;
  String? selectedChoice; // Add this field
  String? correctAnswer;
  int score = 0;
  int questionsAttempted = 0;

  late PageController _pageController;
  int _currentPage = 0;
  final List<String> _animations = [
    'assets/jumps.json',
    'assets/books.json',
    'assets/tree.json',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
    _startAutoSlide();
    _fetchDailyQuiz();
  }

  void _startAutoSlide() {
    Future.delayed(Duration(seconds: 3), () {
      if (_pageController.hasClients) {
        int nextPage = (_currentPage + 1) % _animations.length;
        _pageController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
        setState(() {
          _currentPage = nextPage;
        });
        _startAutoSlide();
      }
    });
  }

  Future<void> _fetchDailyQuiz() async {
    try {
      List<Subject> subjects = await _retry(() => _fetchSubjects(), retries: 3);
      if (subjects.isEmpty) {
        SizedBox(
          child: Lottie.asset(
            'assets/nosubjects.json',
            repeat: true,
            width: 110,
          ),
        );
        throw Exception('No subjects available');
      }

      Subject selectedSubject = subjects[Random().nextInt(subjects.length)];
      List<Map<String, dynamic>> topics = await _retry(() =>
          fetchTopics(selectedSubject.id), retries: 3);
      if (topics.isEmpty) {
        throw Exception('No topics available for the selected subject');
      }

      Map<String, dynamic> selectedTopic = topics[Random().nextInt(
          topics.length)];
      await _retry(() =>
          fetchQuestions(selectedSubject.name, selectedTopic['id'].toString()),
          retries: 3);

      if (questions.isNotEmpty) {
        await _retry(() =>
            fetchOptionsAndAnswer(
                questions[currentQuestionIndex]['id'].toString()), retries: 3);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoading = false;
        });
      }
    }
  }

  Future<List<Subject>> _fetchSubjects() async {
    try {
      final sessionCookie = await _storage.read(key: 'session_cookie');
      if (sessionCookie == null) {
        throw Exception('No session cookie found');
      }

      final response = await http.get(
        Uri.parse('$BASE_URL/subjects'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': sessionCookie,
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        return body.map((dynamic item) => Subject.fromJson(item)).toList();
      } else {
        throw Exception(
            'Failed to load subjects. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching subjects: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchTopics(String subjectId) async {
    final url = '$BASE_URL/$subjectId/topics';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> parsedTopics = json.decode(response.body);
        for (var topic in parsedTopics) {
          final totalQuestions = await fetchTotalQuestions(
              topic['id'].toString());
          topic['total_questions'] = totalQuestions;
        }
        return parsedTopics.cast<Map<String, dynamic>>();
      } else {
        SizedBox(
          child: Lottie.asset(
            'assets/nosubjects.json',
            repeat: true,
            width: 110,
          ),
        );
        throw Exception('Failed to load topics');
      }
    } catch (e) {
      throw e;
    }
  }

  Future<int> fetchTotalQuestions(String topicId) async {
    // Implement this method according to your backend API to get the total questions for a topic
    return 0;
  }

  Future<void> fetchQuestions(String subjectName, String topicId) async {
    final url = '$BASE_URL/questions/$subjectName/$topicId';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            questions = json.decode(response.body) as List<dynamic>;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = 'Failed to load questions';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoading = false;
        });
      }
    }
  }

  Future<void> fetchOptionsAndAnswer(String questionId) async {
    final url = '$BASE_URL/questions/$questionId/options';
    print('Fetching options and answer from: $url'); // Debugging

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final responseBody = response.body;
        print('Response Body: $responseBody'); // Debugging

        final responseData = json.decode(responseBody);
        print('Decoded Response Data: $responseData'); // Debugging

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('correct_answer') &&
              responseData.containsKey('options')) {
            setState(() {
              questions[currentQuestionIndex]['options'] =
              responseData['options'];
              correctAnswer = responseData['correct_answer'];
              print('Correct Answer: $correctAnswer'); // Debugging
            });
          } else {
            throw Exception('Missing keys in response data');
          }
        }
      } else {
        print('Failed to load options. Status code: ${response
            .statusCode}'); // Debugging
        print('Response body: ${response.body}'); // Debugging
        if (mounted) {
          setState(() {
            errorMessage = 'Failed to load options';
          });
        }
      }
    } catch (e) {
      print('Error fetching options: $e'); // Debugging
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
        });
      }
    }
  }

  Future<T> _retry<T>(Future<T> Function() action,
      {int retries = 3, Duration delay = const Duration(seconds: 1)}) async {
    int attempt = 0;
    while (true) {
      try {
        return await action();
      } catch (e) {
        attempt++;
        if (attempt >= retries) {
          rethrow;
        }
        await Future.delayed(delay * attempt);
      }
    }
  }

  void _nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswer = null;
        selectedChoice = null; // Reset selected choice
        fetchOptionsAndAnswer(questions[currentQuestionIndex]['id'].toString());
      });
    } else {
      setState(() {
        errorMessage = 'Quiz completed!';
      });
    }
  }

  void _skipQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswer = null;
        selectedChoice = null; // Reset selected choice
        fetchOptionsAndAnswer(questions[currentQuestionIndex]['id'].toString());
      });
    } else {
      setState(() {
        errorMessage = 'Quiz completed!';
      });
    }
  }

  void _showResults() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CongratulationsPage(
              score: score,
              totalQuestions: questionsAttempted,
            ),
      ),
    );
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
                      selectedAnswer = null;
                      selectedChoice = null; // Reset selected choice
                      fetchOptionsAndAnswer(
                          questions[currentQuestionIndex]['id'].toString());
                    });
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CongratulationsPage(
                              score: score,
                              totalQuestions: questionsAttempted,
                            ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCorrect ? Colors.green : Colors.red,
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 64),
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
              SizedBox(
                width: 150,
                height: 150,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _animations.length,
                  itemBuilder: (context, index) {
                    return Lottie.asset(
                      _animations[index],
                      repeat: true,
                      width: 150,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      question['question'],
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
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
                .map((option) =>
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedChoice = option;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: selectedChoice == option
                          ? Colors.green[700]
                          : Colors.orange[400],
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Daily Quiz')),
        body: const Center(child: CircularProgressIndicator()),
      );
    } else if (errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Daily Quiz')),
        body: Center(child: Text(errorMessage)),
      );
    } else if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Daily Quiz')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                child: Lottie.asset(
                  'assets/nosubjects.json',
                  repeat: true,
                  width: 110,
                ),
              ),
              const Text('No questions available'),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(title: const Text('Daily Quiz')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _skipQuestion,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.orange[400],
                    ),
                    child: const Text('Skip'),
                  ),
                  ElevatedButton(
                    onPressed: _showResults,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue[800],
                    ),
                    child: const Text('Results'),
                  ),
                ],
              ),
            ),
            Expanded(child: buildQuestion()),
          ],
        ),
      );
    }
  }

}

class Subject {
  final String id;
  final String name;

  Subject({required this.id, required this.name});

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'].toString(),
      name: json['name'] as String,
    );
  }
}

class CongratulationsPage extends StatelessWidget {
  final int score;
  final int totalQuestions;

  CongratulationsPage({required this.score, required this.totalQuestions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Congratulations')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              child: Lottie.asset(
                'assets/welldone.json',
                repeat: true,
                width: 200,

              ),
            ),
            const Text(
              'You completed the quiz!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              'Score: $score / $totalQuestions',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 64),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Back to Quiz',
                  style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
