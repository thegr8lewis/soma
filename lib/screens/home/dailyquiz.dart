import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../config.dart';
import '../../utils/fun_facts_config.dart';

class DailyQuizScreen extends StatefulWidget {
  const DailyQuizScreen({super.key});

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

  // Fun Facts variables
  String? currentFunFact;
  String? currentCityFact;
  String? currentCityImage;
  bool isLoadingFacts = false;
  @override
  void initState() {
    super.initState();
    _fetchDailyQuiz();
    _preloadAudio();
    _loadFunFacts();
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
      final authToken = await _storage.read(key: 'auth_token');
      if (authToken == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$BASE_URL/subjects'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
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
      final authToken = await _storage.read(key: 'auth_token');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> parsedTopics = json.decode(response.body);
        return parsedTopics.cast<Map<String, dynamic>>();
      } else {
        throw Exception('No topics available');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> fetchQuestions(String subjectName, String topicId) async {
    final url = '$BASE_URL/questions/$subjectName/$topicId';

    try {
      final authToken = await _storage.read(key: 'auth_token');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );
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
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 64),
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

  Future<void> _loadFunFacts() async {
    setState(() {
      isLoadingFacts = true;
    });

    try {
      await Future.wait([
        _fetchRandomFact(),
        _fetchCityFact(),
      ]);
    } catch (e) {
      print('Error loading fun facts: $e');
    } finally {
      setState(() {
        isLoadingFacts = false;
      });
    }
  }

  Future<void> _fetchRandomFact() async {
    try {
      // Try multiple APIs for variety
      final apis = ['useless_facts', 'cat_facts', 'numbers_api'];
      final selectedAPI = apis[Random().nextInt(apis.length)];

      String fact = '';

      switch (selectedAPI) {
        case 'useless_facts':
          fact = await _fetchFromUselessFacts();
          break;
        case 'cat_facts':
          fact = await _fetchFromCatFacts();
          break;
        case 'numbers_api':
          fact = await _fetchFromNumbersAPI();
          break;
      }

      setState(() {
        currentFunFact = fact.isNotEmpty ? fact : _getBackupFact();
      });
    } catch (e) {
      setState(() {
        currentFunFact = _getBackupFact();
      });
    }
  }

  Future<String> _fetchFromUselessFacts() async {
    final response = await http.get(
      Uri.parse('https://uselessfacts.jsph.pl/random.json?language=en'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return '🤓 ${data['text'] ?? ''}';
    }
    throw Exception('Failed to fetch');
  }

  Future<String> _fetchFromCatFacts() async {
    final response = await http.get(
      Uri.parse('https://catfact.ninja/fact'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return '🐱 Did you know? ${data['fact'] ?? ''}';
    }
    throw Exception('Failed to fetch');
  }

  Future<String> _fetchFromNumbersAPI() async {
    final response = await http.get(
      Uri.parse('http://numbersapi.com/random/trivia'),
      headers: {'Accept': 'text/plain'},
    );

    if (response.statusCode == 200) {
      return '🔢 ${response.body}';
    }
    throw Exception('Failed to fetch');
  }

  Future<void> _fetchCityFact() async {
    try {
      // Using REST Countries API - free, no API key needed
      final response = await http.get(
        Uri.parse(
            'https://restcountries.com/v3.1/all?fields=name,capital,flag,population,region'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> countries = json.decode(response.body);
        if (countries.isNotEmpty) {
          final randomCountry = countries[Random().nextInt(countries.length)];
          final countryName = randomCountry['name']['common'];
          final capital = randomCountry['capital']?[0] ?? 'Unknown';
          final population =
              randomCountry['population']?.toString() ?? 'Unknown';
          final region = randomCountry['region'] ?? 'Unknown';
          final flag = randomCountry['flag'] ?? '🌍';

          setState(() {
            currentCityFact =
                'Did you know? $flag The capital of $countryName is $capital! It\'s located in $region and has a population of approximately $population people.';
            currentCityImage =
                randomCountry['flag']; // This is actually an emoji flag
          });
        }
      } else {
        setState(() {
          currentCityFact = _getBackupCityFact();
        });
      }
    } catch (e) {
      setState(() {
        currentCityFact = _getBackupCityFact();
      });
    }
  }

  String _getBackupFact() {
    return FunFactsConfig
        .backupFacts[Random().nextInt(FunFactsConfig.backupFacts.length)];
  }

  String _getBackupCityFact() {
    return FunFactsConfig.backupCityFacts[
        Random().nextInt(FunFactsConfig.backupCityFacts.length)];
  }

  void _showAPISettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.settings, color: Colors.purple),
                  const SizedBox(width: 10),
                  Text(
                    'Fun Facts APIs',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[700],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Available Free APIs:',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: [
                    ...FunFactsConfig.availableAPIs.entries.map((api) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: Icon(
                            api.value['requiresKey']
                                ? Icons.lock
                                : Icons.lock_open,
                            color: api.value['requiresKey']
                                ? Colors.orange
                                : Colors.green,
                          ),
                          title: Text(
                            api.value['name'],
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            api.value['description'],
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          trailing: api.value['requiresKey']
                              ? const Icon(Icons.key, color: Colors.orange)
                              : const Icon(Icons.check_circle,
                                  color: Colors.green),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 20),
                    Text(
                      'Premium APIs (Require API Key):',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...FunFactsConfig.premiumAPIs.entries.map((api) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: Colors.orange[50],
                        child: ListTile(
                          leading:
                              const Icon(Icons.vpn_key, color: Colors.orange),
                          title: Text(
                            api.value['name'],
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            api.value['description'],
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.open_in_new,
                              color: Colors.orange),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'How to Add Your API:',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Choose a free API from the list above\n2. For premium APIs, get your free API key\n3. Contact the developer to integrate your chosen API\n4. All APIs are filtered for kid-friendly content!',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
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
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
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
            children: options
                .map<Widget>((option) => Padding(
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
                              ? Colors.blue[700]
                              : Colors.orange[400],
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
                    ))
                .toList(),
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

  Widget _buildFunFactsSection() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFF3E5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              Text(
                'Fun Facts! 🎯',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.purple),
                onPressed: _showAPISettings,
                tooltip: 'API Settings',
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.purple),
                onPressed: _loadFunFacts,
                tooltip: 'Refresh Facts',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoadingFacts)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
              ),
            )
          else ...[
            if (currentFunFact != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Text(
                  currentFunFact!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (currentCityFact != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Text(
                  currentCityFact!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
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
              textStyle: const TextStyle(
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
            // Add Fun Facts Section at the top
            _buildFunFactsSection(),
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

  const CongratulationsPage(
      {super.key, required this.score, required this.totalQuestions});

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
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 64),
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
