import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../config.dart';
import 'congratulations.dart';

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
  String? selectedChoice;
  String? correctAnswer;
  int score = 0;
  int questionsAttempted = 0;
  AudioPlayer audioPlayer = AudioPlayer();
  final String apiKey = 'e4e855cee27d4bba9b9f70391fc7ef33';
  final String correctSound = 'correct.mp3';
  final String wrongSound = 'wrong.mp3';

  @override
  void initState() {
    super.initState();
    _fetchDailyQuiz();
    _preloadAudio();
  }

  Future<void> _preloadAudio() async {
    try {
      await audioPlayer.setSource(AssetSource(correctSound));
      await audioPlayer.setSource(AssetSource(wrongSound));
    } catch (e) {
      print('Error initializing audio: $e');
    }
  }

  Future<void> speak(String text) async {
    final url = Uri.parse('https://api.voicerss.org/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'key': apiKey,
          'hl': 'en-us',
          'src': text,
          'c': 'MP3',
          'f': '16khz_16bit_mono',
        },
      );

      if (response.statusCode == 200) {
        final audioContent = response.bodyBytes;
        await audioPlayer.play(BytesSource(audioContent));
      } else {
        print('Failed to synthesize speech: ${response.body}');
      }
    } catch (e) {
      print('Error with text-to-speech: $e');
    }
  }

  Future<void> playSound(String soundFile) async {
    try {
      await audioPlayer.play(AssetSource(soundFile));
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  Future<void> _fetchDailyQuiz() async {
    try {
      List<Subject> subjects = await _retry(() => _fetchSubjects(), retries: 3);
      if (subjects.isEmpty) {
        throw Exception('No subjects available');
      }

      Subject selectedSubject = subjects[Random().nextInt(subjects.length)];
      List<Map<String, dynamic>> topics =
          await _retry(() => fetchTopics(selectedSubject.id), retries: 3);
      if (topics.isEmpty) {
        throw Exception('No topics available for the selected subject');
      }

      Map<String, dynamic> selectedTopic =
          topics[Random().nextInt(topics.length)];
      await _retry(
          () => fetchQuestions(
              selectedSubject.name, selectedTopic['id'].toString()),
          retries: 3);
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
        throw Exception('Failed to load subjects. Status code: ${response.statusCode}');
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
        return parsedTopics.cast<Map<String, dynamic>>();
      } else {
        throw Exception('No topics available');
      }
    } catch (e) {
      throw e;
    }
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
        selectedChoice = null;
        speak(questions[currentQuestionIndex]['question']);
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
        selectedChoice = null;
        speak(questions[currentQuestionIndex]['question']);
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
        builder: (context) => CongratulationsPage(
          score: score,
          totalQuestions: questionsAttempted,
        ),
      ),
    );
  }

  void checkAnswer() async {
    if (selectedChoice == null) return;

    String correctAnswer = questions[currentQuestionIndex]['correct_answer'];
    bool isCorrect = selectedChoice == correctAnswer;

    try {
      if (isCorrect) {
        score++;
        await playSound(correctSound);
      } else {
        await playSound(wrongSound);
      }
    } catch (e) {
      print('Error playing answer sound: $e');
    }

    questionsAttempted++;

    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      builder: (BuildContext context) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          color: const Color(0xFF212121),
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
                    speak(questions[currentQuestionIndex]['question']);
                  } else {
                    _showResults();
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

  Widget buildQuestion() {
    if (currentQuestionIndex >= questions.length) {
      return const Center(child: Text('No questions available'));
    }

    var question = questions[currentQuestionIndex];
    var options = question['options'].entries.toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                child: Lottie.asset(
                  'assets/jumps.json',
                  repeat: true,
                  width: 110,
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
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

   Widget buildBottomButtons() {
    if (currentQuestionIndex >= questions.length) {
      return Container(); // Return empty container if no questions
    }
  
    var question = questions[currentQuestionIndex];
    // Safely handle options map
    Map<String, dynamic> optionsMap = {};
    if (question['options'] is Map) {
      optionsMap = Map<String, dynamic>.from(question['options']);
    }
  
    List<MapEntry<String, dynamic>> options = optionsMap.entries.toList();
  
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: options.map<Widget>((option) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedChoice = option.key;
                  });
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: selectedChoice == option.key ? Colors.blue[700] : Colors.orange[400],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    option.value.toString(),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
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
              Lottie.asset(
                'assets/error.json',
                width: 200,
                repeat: true,
              ),
              const SizedBox(height: 20),
              Text(
                errorMessage,
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
        ),
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
            buildBottomButtons(),
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