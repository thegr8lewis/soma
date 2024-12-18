import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
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
      setState(() {
        isLoading = false;
        errorMessage = 'No subjects available';
      });
      return;
    }

    Subject selectedSubject = subjects[Random().nextInt(subjects.length)];
    List<Map<String, dynamic>> topics = await _retry(() => fetchTopics(selectedSubject.id), retries: 3);
    
    if (topics.isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage = 'No topics available for the selected subject';
      });
      return;
    }

    Map<String, dynamic> selectedTopic = topics[Random().nextInt(topics.length)];
    await _retry(() => fetchQuestions(selectedSubject.name, selectedTopic['id'].toString()), retries: 3);

    if (questions.isNotEmpty) {
      await _retry(() => fetchOptionsAndAnswer(questions[currentQuestionIndex]['id'].toString()), retries: 3);
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
      setState(() {
        errorMessage = 'Please login first';
        isLoading = false;
      });
      return [];
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
    } else if (response.statusCode == 401) {
      throw Exception('Session expired. Please login again.');
    } else {
      throw Exception('Failed to load subjects. Status code: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching subjects: ${e.toString()}');
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
        throw Exception('No topics available');
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
  
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Handle empty array response
        if (responseData is List && responseData.isEmpty) {
          setState(() {
            // Set default options for testing
            questions[currentQuestionIndex]['options'] = {
              'A': 'Option A',
              'B': 'Option B',
              'C': 'Option C',
              'D': 'Option D'
            };
            correctAnswer = 'A'; // Default correct answer
          });
          return;
        }
  
        setState(() {
          if (currentQuestionIndex < questions.length) {
            questions[currentQuestionIndex]['options'] = 
              responseData is Map ? responseData['options'] : 
              responseData.asMap().map((k,v) => MapEntry('option_${k+1}', v));
            correctAnswer = responseData is Map ? 
              responseData['correct_answer']?.toString() : 
              'option_1';
          }
        });
      } else {
        throw Exception('Failed to load options (${response.statusCode})');
      }
    } catch (e) {
      print('Error fetching options: $e');
      // Don't set error message for empty options
      if (e.toString() != 'Exception: Empty options list') {
        setState(() {
          errorMessage = 'Error loading options: $e';
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
  if (currentQuestionIndex >= questions.length) {
    return const Center(child: Text('No questions available'));
  }

  var question = questions[currentQuestionIndex];
  Map<String, dynamic> options = {};
  
  try {
    var rawOptions = question['options'];
    if (rawOptions is Map<String, dynamic>) {
      options = rawOptions;
    } else if (rawOptions is List) {
      // Convert list to map if needed
      for (var i = 0; i < rawOptions.length; i++) {
        options['option_${i + 1}'] = rawOptions[i];
      }
    }
  } catch (e) {
    print('Error processing options: $e');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Error loading question options'),
          ElevatedButton(
            onPressed: () {
              fetchOptionsAndAnswer(question['id'].toString());
            },
            child: const Text('Retry loading options'),
          ),
        ],
      ),
    );
  }

  if (options.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('No options available for this question'),
          ElevatedButton(
            onPressed: () {
              fetchOptionsAndAnswer(question['id'].toString());
            },
            child: const Text('Retry loading options'),
          ),
        ],
      ),
    );
  }

  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          question['question'] ?? 'Question not available',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        ...options.entries.map((option) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                selectedChoice = option.key;
              });
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: selectedChoice == option.key 
                ? Colors.green[700] 
                : Colors.orange[400],
            ),
            child: Text(option.value.toString()),
          ),
        )).toList(),
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
              Lottie.asset(
                'assets/error.json',
                width: 200,
                repeat: true,
              ),
              const SizedBox(height: 20),
              Text(errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    errorMessage = '';
                    isLoading = true;
                  });
                  _fetchDailyQuiz();
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
              appBar: AppBar(
                title: Text(
                  'Daily Quiz',
                  style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                      fontSize: 25,
                      
                      color: Colors.black,
                    ),
                  ),
                ),
              ),        body: Column(
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
                'assets/books.json',
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