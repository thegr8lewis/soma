import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:system_auth/models/modelquestions.dart';
import 'package:system_auth/screens/home/interim.dart';
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
  List<Question> allQuestions = [];
  List<Question> currentBatchQuestions = [];
  List<Question> wrongQuestions = [];
  bool isReviewingWrongAnswers = false;
  bool isLoading = true;
  String? errorMessage;
  int currentQuestionIndex = 0;
  String? selectedChoice;
  int score = 0;
  int questionsAttempted = 0;
  int originalQuestionCount = 0; // Add variable to track original questions
  int totalAttempted = 0; // Add variable to track total attempts
  int currentBatch = 1;
  int batchSize = 10;
  AudioPlayer audioPlayer = AudioPlayer();
  String? currentSessionId;

  final String apiKey = 'e4e855cee27d4bba9b9f70391fc7ef33'; // Replace with your Voice RSS API key
  final String correctSound = 'correct.mp3'; // Path to correct answer sound
  final String wrongSound = 'wrong.mp3'; // Path to wrong answer sound

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

  @override
  void initState() {
    super.initState();
    startNewSession();
    fetchQuestions();
    // Preload audio files
    try {
      audioPlayer.setSource(AssetSource(correctSound));
      audioPlayer.setSource(AssetSource(wrongSound));
    } catch (e) {
      print('Error initializing audio: $e');
    }
  }

  void startNewSession() {
    setState(() {
      wrongQuestions = [];
      isReviewingWrongAnswers = false;
      currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      currentQuestionIndex = 0;
      score = 0;
      questionsAttempted = 0;
      selectedChoice = null;
    });
  }

  Future<void> loadProgress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedSessionId = prefs.getString('sessionId_${widget.topicId}');
    
    if (savedSessionId != currentSessionId) {
      startNewSession();
      return;
    }

    setState(() {
      currentQuestionIndex = prefs.getInt('currentQuestionIndex_${widget.topicId}_$currentSessionId') ?? 0;
      score = prefs.getInt('score_${widget.topicId}_$currentSessionId') ?? 0;
      questionsAttempted = prefs.getInt('questionsAttempted_${widget.topicId}_$currentSessionId') ?? 0;
    });
  }

  Future<void> saveProgress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('sessionId_${widget.topicId}', currentSessionId!);
    await prefs.setInt('currentQuestionIndex_${widget.topicId}_$currentSessionId', currentQuestionIndex);
    await prefs.setInt('score_${widget.topicId}_$currentSessionId', score);
    await prefs.setInt('questionsAttempted_${widget.topicId}_$currentSessionId', questionsAttempted);
  }

  Future<void> fetchQuestions() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/questions/${widget.subjectName}/${widget.topicId}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> decodedResponse = json.decode(response.body);
        setState(() {
          allQuestions = decodedResponse.map((item) {
            return Question(
              id: int.parse(item['id'].toString()),
              grade: item['grade'].toString(),
              subject: item['subject'].toString(),
              topicId: int.parse(item['topic_id'].toString()),
              question: item['question'].toString(),
              imageUrl: item['image_url']?.toString(),
              options: Map<String, dynamic>.from(item['options']),
              correctAnswer: item['correct_answer'].toString(),
            );
          }).toList();
          originalQuestionCount = allQuestions.length; // Store original count
          isLoading = false;
          prepareBatch(); // Prepare the first batch of questions
        });

        if (currentQuestionIndex < currentBatchQuestions.length) {
          speak(currentBatchQuestions[currentQuestionIndex].question);
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
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching questions: $e';
        isLoading = false;
      });
    }
  }

  void prepareBatch() {
    int startIndex = (currentBatch - 1) * batchSize;
    int availableQuestions = allQuestions.length - startIndex;
    
    if (availableQuestions <= 0) {
      // No more questions available
      showCongratulations();
      return;
    }

    int newQuestionsNeeded = batchSize - wrongQuestions.length;
    List<Question> newQuestions = [];
    
    if (availableQuestions > 0) {
      newQuestions = allQuestions.skip(startIndex).take(newQuestionsNeeded).toList();
    }
    
    currentBatchQuestions = [...wrongQuestions, ...newQuestions];
    currentBatchQuestions.shuffle(); // Randomize order
    
    if (currentBatchQuestions.length < batchSize && wrongQuestions.isEmpty) {
      // Less than 10 questions remaining and no wrong questions to add
      // This is the final batch
    }
    
    setState(() {
      currentQuestionIndex = 0;
      wrongQuestions = [];
    });
  }

  void showInterimResults() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InterimResultsPage(
          score: score,
          wrongQuestions: wrongQuestions,
          batchNumber: currentBatch,
          totalQuestions: allQuestions.length,
          onContinue: () {
            currentBatch++;
            prepareBatch();
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void checkAnswer() async {
    if (selectedChoice == null) return;

    String correctAnswer = currentBatchQuestions[currentQuestionIndex].correctAnswer;
    bool isCorrect = selectedChoice == correctAnswer;

    try {
      if (isCorrect) {
        score += 10;
        await playSound(correctSound);
        await saveTotalPoints(10);
      } else {
        await playSound(wrongSound);
        // Add wrong question to list
        if (!isReviewingWrongAnswers) {
          wrongQuestions.add(currentBatchQuestions[currentQuestionIndex]);
        }
      }
    } catch (e) {
      print('Error playing answer sound: $e');
    }

    questionsAttempted++;
    totalAttempted++; // Track total attempts including retries
    saveProgress();

    showModalBottomSheet(
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
                  if (currentQuestionIndex + 1 < currentBatchQuestions.length) {
                    setState(() {
                      currentQuestionIndex++;
                      selectedChoice = null;
                    });
                    saveProgress();
                  } else {
                    showInterimResults();
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

  Future<void> saveTotalPoints(int points) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int sessionScore = prefs.getInt('session_score_${widget.topicId}_$currentSessionId') ?? 0;
    sessionScore += points;
    await prefs.setInt('session_score_${widget.topicId}_$currentSessionId', sessionScore);
  }

  void skipQuestion() {
    setState(() {
      currentQuestionIndex++;
      selectedChoice = null;
      if (currentQuestionIndex >= currentBatchQuestions.length) {
        showInterimResults();
      }
    });
    saveProgress();
  }

  void showCongratulations() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CongratulationsPage(
          score: score,
          totalQuestions: originalQuestionCount, // Use original count
          questionsAttempted: totalAttempted, // Use total attempts
          originalQuestionCount: originalQuestionCount,
        ),
      ),
    );
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.topicName} Questions'), // Always show topic name
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.volumeUp),
            onPressed: () {
              if (currentBatchQuestions.isNotEmpty) {
                speak(currentBatchQuestions[currentQuestionIndex].question);
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : currentBatchQuestions.isEmpty
                  ? const Center(child: Text('No questions available'))
                  : Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
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
                                              value: questionsAttempted / (currentBatchQuestions.isNotEmpty ? currentBatchQuestions.length : 1),
                                              backgroundColor: Colors.grey[300],
                                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${questionsAttempted}/${currentBatchQuestions.length}',
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          ElevatedButton(
                                            onPressed: currentQuestionIndex >= currentBatchQuestions.length - 1 ? null : skipQuestion,
                                            style: ElevatedButton.styleFrom(
                                              foregroundColor: Colors.white,
                                              backgroundColor: Colors.orange[800],
                                            ),
                                            child: const Text('Skip'),
                                          ),
                                          ElevatedButton(
                                            onPressed: questionsAttempted == 0
                                                ? null
                                                : () {
                                                    showCongratulations();
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
                                currentQuestionIndex < currentBatchQuestions.length
                                    ? buildQuestion()
                                    : const Center(child: Text('You have completed the quiz!')),
                              ],
                            ),
                          ),
                        ),
                        buildBottomButtons(),
                      ],
                    ),
    );
  }

  Widget buildQuestion() {
    var question = currentBatchQuestions[currentQuestionIndex];

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
                      question.question,
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
    var question = currentBatchQuestions[currentQuestionIndex];
    var options = question.options.entries.toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: options.map((option) => Padding(
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