import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
  AudioPlayer audioPlayer = AudioPlayer();

  final String apiKey = 'e4e855cee27d4bba9b9f70391fc7ef33'; // Replace with your Voice RSS API key
  final String correctAnswerSound = 'assets/correct.mp3'; // Path to correct answer sound
  final String wrongAnswerSound = 'assets/wrong.mp3'; // Path to wrong answer sound

  @override
  void initState() {
    super.initState();
    loadProgress();
    fetchQuestions();
  }

  Future<void> loadProgress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currentQuestionIndex = prefs.getInt('currentQuestionIndex') ?? 0;
      score = prefs.getInt('score') ?? 0;
      questionsAttempted = prefs.getInt('questionsAttempted') ?? 0;
    });
  }

  Future<void> saveProgress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentQuestionIndex', currentQuestionIndex);
    await prefs.setInt('score', score);
    await prefs.setInt('questionsAttempted', questionsAttempted);
  }

  Future<void> fetchQuestions() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/questions/${widget.subjectName}/${widget.topicId}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          questions = json.decode(response.body) as List<dynamic>;
          isLoading = false;
        });
        // Speak the first question
        if (currentQuestionIndex < questions.length) {
          speak(questions[currentQuestionIndex]['question']);
        }
      } else if (response.statusCode == 401) {
        setState(() {
          errorMessage = 'Unauthorized request. Please check your credentials.';
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load questions. Status code: ${response.statusCode}';
          isLoading = false;
        });
      }
    } on SocketException catch (_) {
      SizedBox(
        child: Lottie.asset(
          'assets/network.json',
          repeat: true,
          width: 110,
        ),
      );
      setState(() {
        errorMessage = 'No Internet connection. Please check your network.';
        isLoading = false;
      });
    } on HttpException catch (_) {
      setState(() {
        errorMessage = 'Could not find the requested resource.';
        isLoading = false;
      });
    } on FormatException catch (_) {
      setState(() {
        errorMessage = 'Bad response format. Unable to parse the data.';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching questions: $e';
        isLoading = false;
      });
    }
  }


  Future<void> speak(String text) async {
    final url = Uri.parse('https://api.voicerss.org/');
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
      // Use setSourceBytes method to play audio from byte array
      await audioPlayer.play(BytesSource(audioContent));
    } else {
      print('Failed to synthesize speech: ${response.body}');
    }
  }

  void playSound(String soundPath) async {
    await audioPlayer.play(AssetSource(soundPath));
  }

  void checkAnswer() {
    if (selectedChoice == null) return;

    String correctAnswer = questions[currentQuestionIndex]['correct_answer'];
    bool isCorrect = selectedChoice == correctAnswer;

    if (isCorrect) {
      score++;
      playSound(correctAnswerSound);
    } else {
      playSound(wrongAnswerSound);
    }

    questionsAttempted++;
    saveProgress();

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
                    saveProgress();
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
    saveProgress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.topicName} Questions'),
        actions: [
          IconButton(
            icon: Icon(Icons.volume_up),
            onPressed: () {
              if (questions.isNotEmpty) {
                speak(questions[currentQuestionIndex]['question']);
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : questions.isEmpty
          ? const Center(child: Text('No questions available'))
          : SingleChildScrollView(
        child: Column(
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
            currentQuestionIndex < questions.length
                ? buildQuestion()
                : const Center(child: Text('You have completed the quiz!')),
          ],
        ),
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
              SizedBox(
                child: Lottie.asset(
                  'assets/books.json',
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
          const SizedBox(height: 20),
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

void main() {
  runApp(MaterialApp(
    home: QuestionsPage(
      topicId: 1,
      topicName: 'Sample Topic',
      subjectName: 'Sample Subject',
    ),
  ));
}
