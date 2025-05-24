import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:system_auth/models/modelquestions.dart';
import 'package:system_auth/screens/home/interim.dart';
import 'package:system_auth/screens/home/motivation_quotes.dart';
import 'package:system_auth/utils/audio_helpers.dart';
import '../../config.dart';
import 'congratulations.dart';

class QuestionsPage extends StatefulWidget {
  final int topicId;
  final String topicName;
  final String subjectName;
  final String topicMongoId; // MongoDB ID for topic
  final String subjectMongoId; // MongoDB ID for subject
  final String
      topicOriginalName; // Original topic_name from API for direct API calls

  const QuestionsPage({
    super.key,
    required this.topicId,
    required this.topicName,
    required this.subjectName,
    this.topicMongoId = '', // Default to empty string if not provided
    this.subjectMongoId = '', // Default to empty string if not provided
    this.topicOriginalName = '', // Default to empty string if not provided
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
  int lastInterimMilestone =
      0; // Track the last milestone where interim results were shown
  String? currentSessionId;
  final String apiKey =
      'e4e855cee27d4bba9b9f70391fc7ef33'; // Replace with your Voice RSS API key
  final String correctSound = 'correct.mp3'; // Path to correct answer sound
  final String wrongSound = 'wrong.mp3'; // Path to wrong answer sound

  // List of available animations
  final List<String> availableAnimations = [
    'assets/new animations/Animation - 1720516117842.json',
    'assets/new animations/Animation - 1748106511073.json',
    'assets/new animations/Animation - 1748106814060.json',
    'assets/new animations/Animation - 1748106837136.json',
    'assets/new animations/Animation - 1748110777888.json',
    'assets/new animations/Animation - 1748110841169.json',
    'assets/new animations/Animation - 1748110879509.json',
    'assets/new animations/Animation - 1748110974416.json',
    'assets/new animations/Animation - 1748111072025.json',
    'assets/new animations/Animation - 1748111118338.json',
    'assets/new animations/Animation - 1748111194249.json',
    'assets/new animations/Animation - 1748111571198.json',
    'assets/new animations/Animation - 1748111597439.json',
    'assets/new animations/Animation - 1748111658955.json',
    'assets/new animations/Animation - 1748111692882.json',
    'assets/new animations/Animation - 1748111731781.json',
    'assets/new animations/Animation - 1748111772188.json',
  ];

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
        final player = AudioPlayer();
        try {
          await player.play(BytesSource(audioContent));
          debugPrint('Text-to-speech played successfully');
        } catch (e) {
          debugPrint('Error playing TTS audio: $e');
        }
      } else {
        debugPrint('Failed to synthesize speech: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error with text-to-speech: $e');
    }
  }

  Future<void> playSound(String soundFile) async {
    // Use the new AudioHelper class for robust sound playback
    await AudioHelper.playSound(soundFile);
  }

  @override
  void initState() {
    super.initState();
    startNewSession();
    fetchQuestions();
    // We don't need to initialize AudioHelper, it's self-initializing
  }

  void startNewSession() {
    setState(() {
      wrongQuestions = [];
      isReviewingWrongAnswers = false;
      currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      currentQuestionIndex = 0;
      score = 0;
      questionsAttempted = 0;
      totalAttempted = 0;
      lastInterimMilestone = 0;
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
      currentQuestionIndex = prefs.getInt(
              'currentQuestionIndex_${widget.topicId}_$currentSessionId') ??
          0;
      score = prefs.getInt('score_${widget.topicId}_$currentSessionId') ?? 0;
      questionsAttempted = prefs.getInt(
              'questionsAttempted_${widget.topicId}_$currentSessionId') ??
          0;
      totalAttempted =
          prefs.getInt('totalAttempted_${widget.topicId}_$currentSessionId') ??
              0;
      lastInterimMilestone = prefs.getInt(
              'lastInterimMilestone_${widget.topicId}_$currentSessionId') ??
          0;
    });
  }

  Future<void> saveProgress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('sessionId_${widget.topicId}', currentSessionId!);
    await prefs.setInt(
        'currentQuestionIndex_${widget.topicId}_$currentSessionId',
        currentQuestionIndex);
    await prefs.setInt('score_${widget.topicId}_$currentSessionId', score);
    await prefs.setInt('questionsAttempted_${widget.topicId}_$currentSessionId',
        questionsAttempted);
    await prefs.setInt(
        'totalAttempted_${widget.topicId}_$currentSessionId', totalAttempted);
    await prefs.setInt(
        'lastInterimMilestone_${widget.topicId}_$currentSessionId',
        lastInterimMilestone);
  }

  Future<void> fetchQuestions() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final authToken =
          await const FlutterSecureStorage().read(key: 'auth_token');

      if (authToken == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'Authentication token not found. Please log in again.';
        });
        return;
      }

      // Use the MongoDB ID passed from topics list when available
      String idToUse = widget.topicMongoId.isNotEmpty
          ? widget.topicMongoId
          : widget.topicId.toString();
      debugPrint(
          'Starting question fetch for topic: ${widget.topicName} (ID: ${widget.topicId})');
      if (widget.topicMongoId.isNotEmpty) {
        debugPrint('Using MongoDB ID for API calls: ${widget.topicMongoId}');
      }

      // First try the direct approach with the API format: /questions/:subject/:topic_id
      final String directUrl =
          '$BASE_URL/questions/${Uri.encodeComponent(widget.subjectName)}/$idToUse';
      debugPrint(
          'Primary attempt: Fetching questions with direct URL: $directUrl');

      try {
        final directResponse = await http.get(
          Uri.parse(directUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
        );

        debugPrint(
            'Direct topic endpoint response code: ${directResponse.statusCode}');

        if (directResponse.statusCode == 200) {
          bool success = await _processQuestionsResponse(directResponse.body);
          if (success) return;
        } else {
          debugPrint(
              'Failed with direct topic endpoint. Status code: ${directResponse.statusCode}');
          if (directResponse.statusCode == 400 ||
              directResponse.statusCode == 404) {
            debugPrint('Response body: ${directResponse.body}');
          }
        }
      } catch (e) {
        debugPrint('Error in direct topic endpoint attempt: $e');
      } // Try multiple URL formats to find one that works
      bool success = await _tryFetchQuestionsWithNames(authToken);

      if (!success && !isLoading) {
        // First attempt failed, try with MongoDB IDs
        success = await _tryFetchQuestionsWithMongoIds(authToken);
      }

      if (!success && !isLoading) {
        // Both attempts failed, try with numeric IDs
        success = await _tryFetchQuestionsWithNumericIds(authToken);
      }

      // Try the all questions endpoint and filter locally as a last resort
      if (!success && !isLoading) {
        debugPrint('Attempting to fetch all questions and filter locally');
        const String allQuestionsUrl = '$BASE_URL/questions';

        try {
          final allResponse = await http.get(
            Uri.parse(allQuestionsUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
          );

          debugPrint(
              'All questions endpoint response code: ${allResponse.statusCode}');

          if (allResponse.statusCode == 200) {
            // Process all questions and filter for just this topic
            success = await _processAndFilterQuestions(allResponse.body);
          }
        } catch (e) {
          debugPrint('Error in all questions attempt: $e');
        }
      }
      if (!success && isLoading) {
        // All attempts failed
        setState(() {
          isLoading = false;
          errorMessage =
              'Could not find questions for "${widget.topicName}". This topic may not have any questions yet. Try another topic or try again later.';
        });
      }
    } catch (e) {
      debugPrint('Error details: $e');
      setState(() {
        errorMessage = 'Error fetching questions: $e';
        isLoading = false;
      });
    }
  } // This method has been removed as it was handling a special case we no longer need

  // Process all questions and filter locally for this topic
  Future<bool> _processAndFilterQuestions(String rawResponse) async {
    try {
      List<dynamic> allQuestionsList = [];

      if (rawResponse.trim().startsWith('{')) {
        Map<String, dynamic> jsonObj = json.decode(rawResponse);
        // Find questions array in response
        for (var key in jsonObj.keys) {
          if (jsonObj[key] is List) {
            allQuestionsList = jsonObj[key];
            break;
          }
        }
      } else if (rawResponse.trim().startsWith('[')) {
        allQuestionsList = json.decode(rawResponse);
      }

      if (allQuestionsList.isEmpty) {
        return false;
      }

      // Filter questions for this topic
      List<dynamic> filteredQuestions = [];

      for (var question in allQuestionsList) {
        // Try to match by topic ID
        if (question['topic_id'] != null &&
            question['topic_id'].toString() == widget.topicId.toString()) {
          filteredQuestions.add(question);
        }
        // Try to match by topic name
        else if (question['topic'] != null &&
            question['topic'].toString().toLowerCase() ==
                widget.topicName.toLowerCase()) {
          filteredQuestions.add(question);
        }
        // Try to match by MongoDB ID
        else if (question['topic_id'] != null &&
            widget.topicMongoId.isNotEmpty &&
            question['topic_id'].toString() == widget.topicMongoId) {
          filteredQuestions.add(question);
        }
      }

      if (filteredQuestions.isEmpty) {
        debugPrint('No questions found for this topic in all questions');
        return false;
      }

      debugPrint(
          'Filtered ${filteredQuestions.length} questions for topic ${widget.topicName}');
      return _processQuestionsResponse(json.encode(filteredQuestions));
    } catch (e) {
      debugPrint('Error filtering questions: $e');
      return false;
    }
  } // Try fetching questions using names and MongoDB IDs

  Future<bool> _tryFetchQuestionsWithNames(String authToken) async {
    try {
      // For the API, always use the subject name
      String subjectIdToUse = widget.subjectName;
      String idToUse;

      // Use MongoDB ID if it's valid, otherwise fall back to topic name
      if (widget.topicMongoId.isNotEmpty &&
          isValidMongoId(widget.topicMongoId)) {
        idToUse = widget.topicMongoId;
        debugPrint('Using valid MongoDB ID: $idToUse for API call');
      } else if (widget.topicOriginalName.isNotEmpty) {
        idToUse = widget.topicOriginalName;
        debugPrint('Using original topic name: $idToUse for API call');
      } else {
        idToUse = widget.topicName;
        debugPrint('Using display topic name: $idToUse for API call');
      }

      // Use the standard API structure: /questions/:subject/:topic_id
      final String url =
          '$BASE_URL/questions/${Uri.encodeComponent(subjectIdToUse)}/${Uri.encodeComponent(idToUse)}';
      debugPrint('Attempt 1: Fetching questions with name/ID from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      debugPrint('Questions API response code: ${response.statusCode}');

      if (response.statusCode == 200) {
        return await _processQuestionsResponse(response.body);
      } else {
        debugPrint(
            'Failed to load questions. Status code: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error in API attempt: $e');
      return false;
    }
  } // Try fetching questions using MongoDB IDs

  Future<bool> _tryFetchQuestionsWithMongoIds(String authToken) async {
    try {
      // Check if we have the required IDs
      if (widget.subjectMongoId.isEmpty || widget.topicMongoId.isEmpty) {
        debugPrint('Cannot try MongoDB IDs approach - missing IDs');
        return false;
      }

      // Clean MongoDB IDs by removing any special characters that might cause API issues
      String cleanSubjectId = widget.subjectMongoId.trim();
      String cleanTopicId = widget.topicMongoId.trim();

      // First, try the most reliable API structure: /questions/:subject/:topic_id
      final String subjectNameUrl =
          '$BASE_URL/questions/${Uri.encodeComponent(widget.subjectName)}/$cleanTopicId';
      debugPrint(
          'Attempt 2a: Fetching questions with subject name and MongoDB ID: $subjectNameUrl');

      final subjectNameResponse = await http.get(
        Uri.parse(subjectNameUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      debugPrint(
          'Questions API response code (subject name + MongoDB ID): ${subjectNameResponse.statusCode}');

      if (subjectNameResponse.statusCode == 200) {
        return await _processQuestionsResponse(subjectNameResponse.body);
      }

      // If that failed, try the approach with MongoDB IDs for both subject and topic
      final String mongoIdsUrl =
          '$BASE_URL/questions/$cleanSubjectId/$cleanTopicId';
      debugPrint(
          'Attempt 2b: Fetching questions with both MongoDB IDs: $mongoIdsUrl');

      final mongoIdsResponse = await http.get(
        Uri.parse(mongoIdsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      debugPrint(
          'Questions API response code (both MongoDB IDs): ${mongoIdsResponse.statusCode}');

      if (mongoIdsResponse.statusCode == 200) {
        return await _processQuestionsResponse(mongoIdsResponse.body);
      }
      // Try with topic ID in different format
      final String topicIdUrl = '$BASE_URL/topics/$cleanTopicId/questions';
      debugPrint(
          'Attempt 2c: Fetching questions from topics endpoint: $topicIdUrl');

      final topicIdResponse = await http.get(
        Uri.parse(topicIdUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      debugPrint(
          'Questions API response code (topics endpoint attempt): ${topicIdResponse.statusCode}');

      if (topicIdResponse.statusCode == 200) {
        return await _processQuestionsResponse(topicIdResponse.body);
      } else {
        debugPrint(
            'Failed to load questions with MongoDB IDs. Status code: ${topicIdResponse.statusCode}');
        if (topicIdResponse.statusCode == 400 ||
            topicIdResponse.statusCode == 404) {
          debugPrint('Response body: ${topicIdResponse.body}');
        }
        return false;
      }
    } catch (e) {
      debugPrint('Error in MongoDB IDs attempt: $e');
      return false;
    }
  }

  // Try fetching questions using numeric IDs
  Future<bool> _tryFetchQuestionsWithNumericIds(String authToken) async {
    try {
      // First try the topic ID alone approach
      final String topicOnlyUrl = '$BASE_URL/questions/id/${widget.topicId}';
      debugPrint(
          'Attempt 3a: Fetching questions with just topic ID from: $topicOnlyUrl');
      debugPrint('Using just Topic ID: ${widget.topicId}');

      final topicOnlyResponse = await http.get(
        Uri.parse(topicOnlyUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      debugPrint(
          'Questions API response code (topic ID only attempt): ${topicOnlyResponse.statusCode}');

      if (topicOnlyResponse.statusCode == 200) {
        return await _processQuestionsResponse(topicOnlyResponse.body);
      }

      // If that failed, try the standard format
      final String url =
          '$BASE_URL/questions/${widget.subjectName}/${widget.topicId}';
      debugPrint('Attempt 3b: Fetching questions with numeric IDs from: $url');
      debugPrint(
          'Using Subject Name: ${widget.subjectName} and Topic ID: ${widget.topicId}');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      debugPrint(
          'Questions API response code (numeric IDs attempt): ${response.statusCode}');

      if (response.statusCode == 200) {
        return await _processQuestionsResponse(response.body);
      } else {
        debugPrint(
            'Failed to load questions with numeric IDs. Status code: ${response.statusCode}');
        if (response.statusCode == 400 || response.statusCode == 404) {
          debugPrint('Response body: ${response.body}');
        }

        // Try one more approach - with just the topic name
        final String topicNameUrl =
            '$BASE_URL/questions/topic/name/${Uri.encodeComponent(widget.topicName)}';
        debugPrint(
            'Attempt 3c: Fetching questions with topic name only from: $topicNameUrl');

        final topicNameResponse = await http.get(
          Uri.parse(topicNameUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
        );

        debugPrint(
            'Questions API response code (topic name only attempt): ${topicNameResponse.statusCode}');

        if (topicNameResponse.statusCode == 200) {
          return await _processQuestionsResponse(topicNameResponse.body);
        }

        // All attempts have failed, set error message
        setState(() {
          errorMessage =
              'Could not find questions for "${widget.topicName}". The topic may not have any questions yet.';
          isLoading = false;
        });

        return false;
      }
    } catch (e) {
      debugPrint('Error in numeric IDs attempt: $e');
      return false;
    }
  } // Process the questions response

  Future<bool> _processQuestionsResponse(String rawResponse) async {
    try {
      if (rawResponse.isEmpty) {
        debugPrint('Empty response received');
        setState(() {
          isLoading = false;
          errorMessage = 'Empty response from server.';
        });
        return false;
      }

      debugPrint('Raw API Response length: ${rawResponse.length}');
      if (rawResponse.length > 200) {
        debugPrint(
            'Response (first 200 chars): ${rawResponse.substring(0, 200)}...');
      } else {
        debugPrint('Response: $rawResponse');
      }

      // Try to parse the response
      List<dynamic> questionsList = [];

      // Handle JSON object wrapper or direct array
      if (rawResponse.trim().startsWith('{')) {
        // Response is a JSON object, try to find an array inside it
        Map<String, dynamic> jsonObj = json.decode(rawResponse);
        debugPrint('Questions response appears to be a JSON object');

        // Handle nested data structures
        if (jsonObj.containsKey('data') && jsonObj['data'] is Map) {
          // Handle case where data is an object that contains an array
          Map<String, dynamic> dataObj = jsonObj['data'];
          for (var key in dataObj.keys) {
            if (dataObj[key] is List) {
              debugPrint('Found questions in nested data.$key field');
              questionsList = dataObj[key];
              break;
            }
          }
        }
        // Check common field names that might contain the questions
        else if (jsonObj.containsKey('data') && jsonObj['data'] is List) {
          debugPrint('Found questions in "data" field');
          questionsList = jsonObj['data'];
        } else if (jsonObj.containsKey('questions') &&
            jsonObj['questions'] is List) {
          debugPrint('Found questions in "questions" field');
          questionsList = jsonObj['questions'];
        } else if (jsonObj.containsKey('results') &&
            jsonObj['results'] is List) {
          debugPrint('Found questions in "results" field');
          questionsList = jsonObj['results'];
        } else if (jsonObj.containsKey('items') && jsonObj['items'] is List) {
          debugPrint('Found questions in "items" field');
          questionsList = jsonObj['items'];
        } else {
          // Look for any array in the response
          bool foundArray = false;
          for (var key in jsonObj.keys) {
            if (jsonObj[key] is List) {
              debugPrint('Found possible questions array in field: $key');
              questionsList = jsonObj[key];
              foundArray = true;
              break;
            }
          }

          if (!foundArray) {
            // If no array was found, check if the object itself looks like a question
            debugPrint('No arrays found in response');
            if (jsonObj.containsKey('question') || jsonObj.containsKey('id')) {
              debugPrint('The object itself appears to be a single question');
              questionsList = [jsonObj];
            } else {
              debugPrint('Could not find questions data in response');
              debugPrint('Response keys: ${jsonObj.keys.toList()}');
              setState(() {
                isLoading = false;
                errorMessage = 'No questions found for this topic.';
              });
              return false;
            }
          }
        }
      } else if (rawResponse.trim().startsWith('[')) {
        // Response is already an array
        questionsList = json.decode(rawResponse);
        debugPrint('Response is a direct JSON array');
      } else {
        debugPrint(
            'Response is not a valid JSON format. First chars: ${rawResponse.substring(0, min(30, rawResponse.length))}');
        setState(() {
          isLoading = false;
          errorMessage = 'Invalid response format from server.';
        });
        return false;
      }

      if (questionsList.isEmpty) {
        debugPrint('No questions found for this topic');
        setState(() {
          isLoading = false;
          errorMessage = 'No questions available for this topic.';
        });
        return false;
      }

      debugPrint('Found ${questionsList.length} questions');

      // Process the questions
      List<Question> parsedQuestions = [];

      for (var item in questionsList) {
        try {
          if (item is Map<String, dynamic>) {
            // Convert the options to a standardized format
            Map<String, dynamic> optionsMap = {};

            // Handle options in different formats
            if (item.containsKey('options')) {
              var options = item['options'];

              if (options is List) {
                // Convert list to map with letter keys
                List<dynamic> optionsList = options;
                for (int i = 0; i < optionsList.length; i++) {
                  // Use letters as keys: A, B, C, D, etc.
                  String key =
                      String.fromCharCode(65 + i); // 65 is ASCII for 'A'
                  optionsMap[key] = optionsList[i];
                }
              } else if (options is Map) {
                // Use the map directly, possibly after normalization
                optionsMap = Map<String, dynamic>.from(options);
              }
            } else {
              // Try to find option fields (like option_a, option_b, etc.)
              for (var key in item.keys) {
                if (key.startsWith('option_') && key.length > 7) {
                  String optionKey =
                      key.substring(7).toUpperCase(); // Extract the letter part
                  optionsMap[optionKey] = item[key];
                }
              }

              // If still no options found, look for fields like A, B, C, D directly
              if (optionsMap.isEmpty) {
                for (var key in ['A', 'B', 'C', 'D', 'E', 'F']) {
                  if (item.containsKey(key)) {
                    optionsMap[key] = item[key];
                  }
                }
              }

              // If still no options, try looking for choice1, choice2, etc.
              if (optionsMap.isEmpty) {
                for (var key in item.keys) {
                  if (key.startsWith('choice') || key.startsWith('option')) {
                    // Use A, B, C, etc. for the keys
                    int index =
                        int.tryParse(key.replaceAll(RegExp(r'[^0-9]'), '')) ??
                            0;
                    if (index > 0) {
                      String optionKey = String.fromCharCode(
                          64 + index); // 65 is ASCII for 'A'
                      optionsMap[optionKey] = item[key];
                    }
                  }
                }
              }
            }

            // Handle different formats of correct_answer
            String correctAnswer = '';
            if (item.containsKey('correct_answer')) {
              if (item['correct_answer'] is String) {
                correctAnswer = item['correct_answer'];
              } else if (item['correct_answer'] is int) {
                // Convert numeric index to letter (0 -> A, 1 -> B, etc.)
                int index = item['correct_answer'];
                correctAnswer = String.fromCharCode(65 + index);
              }
            } else if (item.containsKey('answer')) {
              correctAnswer = item['answer'].toString();
            } else if (item.containsKey('correct')) {
              correctAnswer = item['correct'].toString();
            }

            // Create the question object
            Question question = Question(
              id: int.tryParse(item['id']?.toString() ?? '0') ?? 0,
              mongoId: item['_id']?.toString() ??
                  item['id']?.toString() ??
                  '0', // Try both _id and id for MongoDB
              grade: item['grade']?.toString() ?? '',
              subject: item['subject']?.toString() ?? widget.subjectName,
              topicId: int.tryParse(item['topic_id']?.toString() ?? '0') ??
                  widget.topicId,
              question: item['question']?.toString() ??
                  item['text']?.toString() ??
                  'Question not available',
              imageUrl: item['image_url']?.toString() ??
                  item['imageUrl']?.toString() ??
                  item['image']?.toString(),
              options: optionsMap,
              correctAnswer: correctAnswer,
            );

            // Only add the question if it has some options
            if (question.options.isNotEmpty) {
              parsedQuestions.add(question);
              debugPrint(
                  'Processed question #${question.id}: ${question.question.substring(0, min(30, question.question.length))}...');
            } else {
              debugPrint(
                  'Skipping question without options: ${question.question.substring(0, min(30, question.question.length))}...');
            }
          }
        } catch (e) {
          debugPrint('Error processing question: $e');
          debugPrint('Problem data: $item');
        }
      }

      if (parsedQuestions.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'Could not process any questions from the data.';
        });
        return false;
      }

      setState(() {
        allQuestions = parsedQuestions;
        originalQuestionCount = allQuestions.length;
        isLoading = false;
        prepareBatch();
      });

      if (currentBatchQuestions.isNotEmpty) {
        speak(currentBatchQuestions[currentQuestionIndex].question);
      }

      return true;
    } catch (e) {
      debugPrint('Error parsing questions response: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Error parsing questions: $e';
      });
      return false;
    }
  }

  // Helper function to check if a string is a valid MongoDB ID
  bool isValidMongoId(String id) {
    // MongoDB IDs are 24 hex characters
    if (id.length != 24) return false;

    // Check if it only contains hex characters (0-9, a-f, A-F)
    final hexRegex = RegExp(r'^[0-9a-fA-F]{24}$');
    return hexRegex.hasMatch(id);
  }

  // Get current animation based on question index
  String getCurrentAnimation() {
    if (availableAnimations.isEmpty) {
      return 'assets/caterpillar.json'; // Fallback to default
    }

    // Cycle through animations based on current question index
    int animationIndex = currentQuestionIndex % availableAnimations.length;
    return availableAnimations[animationIndex];
  }

  void _showMotivationalQuotes() {
    debugPrint('Showing motivational quotes...');

    try {
      // Store current index to prevent any state issues
      final int savedQuestionIndex = currentQuestionIndex;

      // Show motivational quotes page without continue button
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MotivationQuotesPage(),
        ),
      );

      // Automatically close after exactly 4 seconds and continue to next question
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted && Navigator.canPop(context)) {
          debugPrint(
              'Auto-continuing after 4-second motivational quotes display');
          Navigator.pop(context);

          // Continue to next question safely
          setState(() {
            currentQuestionIndex = savedQuestionIndex + 1;
            selectedChoice = null;
          });
          saveProgress();
        }
      });
    } catch (e) {
      debugPrint('Error showing motivational quotes: $e');
      // If there's an error, just move to the next question safely
      setState(() {
        currentQuestionIndex++;
        selectedChoice = null;
      });
      saveProgress();
    }
  }

  void prepareBatch() {
    int startIndex = (currentBatch - 1) * batchSize;
    int availableQuestions = allQuestions.length - startIndex;
    List<Question> newQuestions = [];

    if (availableQuestions <= 0 &&
        (wrongQuestions.isEmpty || !isReviewingWrongAnswers)) {
      // No more questions available
      debugPrint('No more questions available. Showing congratulations.');
      showCongratulations();
      return;
    }

    // If we're in review mode, only show wrong questions
    if (isReviewingWrongAnswers) {
      debugPrint(
          'In review mode - showing only wrong questions: ${wrongQuestions.length}');
      currentBatchQuestions = List<Question>.from(wrongQuestions);

      // Don't shuffle wrong questions during review
      return;
    }

    // In normal mode, don't include wrong questions until after interim/congrats page
    int questionsNeeded = batchSize;
    debugPrint('Need $questionsNeeded new questions for this batch');

    if (availableQuestions > 0) {
      newQuestions =
          allQuestions.skip(startIndex).take(questionsNeeded).toList();
      debugPrint(
          'Adding ${newQuestions.length} new questions starting from index $startIndex');
    }

    // In normal mode, only use regular questions, not wrong ones
    currentBatchQuestions = newQuestions;
    currentBatchQuestions.shuffle(); // Randomize order

    debugPrint(
        'Prepared batch with ${currentBatchQuestions.length} questions (${wrongQuestions.length} wrong questions)'); // Only show interim results if we're exactly at a multiple of 10
    // and we haven't shown interim results for this milestone yet
    int currentMilestone = (totalAttempted ~/ 10) * 10;
    if (totalAttempted > 0 &&
        totalAttempted % 10 == 0 &&
        lastInterimMilestone < currentMilestone) {
      // Update the last milestone where we showed interim results
      lastInterimMilestone = currentMilestone;
      debugPrint('Showing interim results after $totalAttempted questions');
      // Don't show immediately on first batch preparation
      if (currentBatch > 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showInterimResults();
        });
      }
    }

    setState(() {
      currentQuestionIndex = 0;
      // In review mode, we'll clear wrong questions as user gets them right in checkAnswer
    });
  }

  void showInterimResults() {
    // Create a copy of wrong questions for the interim results page
    List<Question> wrongQuestionsCopy = List<Question>.from(wrongQuestions);

    // Log the wrong questions being passed to the interim results page
    debugPrint(
        'Showing interim results with ${wrongQuestionsCopy.length} wrong questions');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InterimResultsPage(
          score: score,
          wrongQuestions: wrongQuestionsCopy,
          batchNumber: currentBatch,
          totalQuestions: allQuestions.length,
          onContinue: () {
            // When continuing from interim results page, check if we should now review wrong questions
            if (currentBatch * batchSize >= allQuestions.length &&
                wrongQuestions.isNotEmpty &&
                wrongQuestionsCopy.isNotEmpty) {
              debugPrint(
                  'All regular questions completed. Now reviewing wrong answers only.');
              setState(() {
                isReviewingWrongAnswers = true;
                // Reset current question index for wrong questions review
                currentQuestionIndex = 0;
              });
              prepareBatch(); // This will now only include wrong questions
            } else {
              currentBatch++;
              prepareBatch(); // Continue with normal questions
            }
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void checkAnswer() async {
    if (selectedChoice == null) return;

    Question currentQuestion = currentBatchQuestions[currentQuestionIndex];
    String correctAnswerValue = currentQuestion.correctAnswer;

    // Get the value of the selected option
    String selectedValue = currentQuestion.options[selectedChoice].toString();

    // Compare the actual answer values, not the letter keys
    bool isCorrect = selectedValue == correctAnswerValue;

    // For debugging
    debugPrint('Selected: $selectedChoice ($selectedValue)');
    debugPrint('Correct answer value: $correctAnswerValue');
    debugPrint('Is correct: $isCorrect');
    try {
      if (isCorrect) {
        score += 10;
        await playSound(correctSound);
        await saveTotalPoints(10);

        // If we're reviewing wrong questions and this one was correct,
        // remove it from the wrong questions list
        if (isReviewingWrongAnswers) {
          wrongQuestions.removeWhere((q) =>
              q.mongoId == currentBatchQuestions[currentQuestionIndex].mongoId);
          debugPrint(
              'Question answered correctly in review mode. Removed from wrong questions.');
          debugPrint('Remaining wrong questions: ${wrongQuestions.length}');
        }
      } else {
        await playSound(wrongSound);
        // Add wrong question to list for the next batch
        if (!isReviewingWrongAnswers) {
          // Check if the question is already in the wrong questions list
          bool isAlreadyInWrongQuestions = wrongQuestions.any((q) =>
              q.mongoId == currentBatchQuestions[currentQuestionIndex].mongoId);

          if (!isAlreadyInWrongQuestions) {
            wrongQuestions.add(currentBatchQuestions[currentQuestionIndex]);
            debugPrint(
                'Added question to wrong questions list. Total wrong questions: ${wrongQuestions.length}');
          }
        }
      }
    } catch (e) {
      debugPrint('Error playing answer sound: $e');
    }

    questionsAttempted++;
    totalAttempted++; // Track total attempts including retries
    saveProgress();

    // Find the letter key for the correct answer
    String correctAnswerLetter = '';
    currentQuestion.options.forEach((key, value) {
      if (value.toString() == correctAnswerValue) {
        correctAnswerLetter = key;
      }
    });
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 36.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 6,
                width: 80,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                decoration: BoxDecoration(
                  color: isCorrect
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFEBEE),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: isCorrect
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Lottie.asset(
                  isCorrect
                      ? 'assets/congratulations.json'
                      : 'assets/books.json',
                  width: 140,
                  height: 140,
                  repeat: true,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isCorrect ? 'Great job! 🎉' : 'Not quite right 🤔',
                style: GoogleFonts.fredoka(
                  textStyle: TextStyle(
                    color: isCorrect
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFF44336),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFEBEE).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  isCorrect
                      ? 'You got the answer correct! +10 points'
                      : 'Don\'t worry! Learning is a journey. Keep going!',
                  style: GoogleFonts.fredoka(
                    textStyle: TextStyle(
                      color: isCorrect
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFC62828),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (!isCorrect) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: const Color(0xFFFFCDD2), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFFD32F2F),
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Correct Answer:',
                            style: GoogleFonts.fredoka(
                              textStyle: const TextStyle(
                                color: Color(0xFFD32F2F),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD32F2F),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFD32F2F).withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                correctAnswerLetter,
                                style: GoogleFonts.fredoka(
                                  textStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              correctAnswerValue,
                              style: GoogleFonts.fredoka(
                                textStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCorrect
                        ? [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]
                        : [const Color(0xFF3F51B5), const Color(0xFF5C6BC0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: isCorrect
                          ? const Color(0xFF4CAF50).withOpacity(0.3)
                          : const Color(0xFF3F51B5).withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 0,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);

                    // Check if we need to show interim results after exactly 10 questions
                    if (totalAttempted % 10 == 0 &&
                        lastInterimMilestone < totalAttempted) {
                      // Update milestone counter
                      lastInterimMilestone = totalAttempted;
                      debugPrint(
                          'Showing interim results after $totalAttempted questions');
                      showInterimResults();
                      return;
                    }

                    // Check if we've reached the end of current batch
                    if (currentQuestionIndex + 1 >=
                        currentBatchQuestions.length) {
                      debugPrint('Reached end of batch');
                      // Prepare next batch and continue
                      currentBatch++;
                      prepareBatch();
                      return;
                    }

                    // Show motivational quotes every 5 questions, but not when showing interim results
                    if (questionsAttempted > 0 &&
                        questionsAttempted % 5 == 0 &&
                        totalAttempted % 10 != 0) {
                      debugPrint(
                          'Showing motivational quotes after $questionsAttempted questions');
                      _showMotivationalQuotes();
                      return; // Important: return here to prevent double navigation
                    }

                    // Otherwise just move to the next question
                    setState(() {
                      currentQuestionIndex++;
                      selectedChoice = null;
                    });
                    saveProgress();
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 64),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isCorrect ? Icons.arrow_forward : Icons.refresh,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Continue',
                        style: GoogleFonts.fredoka(
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
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
    int sessionScore =
        prefs.getInt('session_score_${widget.topicId}_$currentSessionId') ?? 0;
    sessionScore += points;
    await prefs.setInt(
        'session_score_${widget.topicId}_$currentSessionId', sessionScore);
  }

  void skipQuestion() {
    setState(() {
      currentQuestionIndex++;
      selectedChoice = null;

      // If we've reached the end of the current batch
      if (currentQuestionIndex >= currentBatchQuestions.length) {
        // Prepare next batch instead of immediately showing interim results
        currentBatch++;
        prepareBatch();
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
          wrongQuestions: wrongQuestions, // Pass wrong questions for review
          onReviewWrongAnswers: wrongQuestions.isNotEmpty
              ? () {
                  setState(() {
                    isReviewingWrongAnswers = true;
                    currentQuestionIndex = 0;
                    prepareBatch(); // This will show only wrong questions
                  });
                  Navigator.pop(context);
                }
              : null,
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Safely dispose audio resources
    AudioHelper.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF3F51B5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.question_answer,
                  size: 24, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              '${widget.topicName} Questions',
              style: GoogleFonts.fredoka(
                textStyle: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(50),
            ),
            child: IconButton(
              icon:
                  const FaIcon(FontAwesomeIcons.volumeUp, color: Colors.white),
              onPressed: () {
                if (currentBatchQuestions.isNotEmpty) {
                  speak(currentBatchQuestions[currentQuestionIndex].question);
                }
              },
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF3F51B5), // Indigo
              const Color(0xFF5C6BC0), // Medium Indigo
              const Color(0xFFE8EAF6).withOpacity(0.9), // Light indigo/white
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
          // Only show background image during loading
          image: isLoading
              ? const DecorationImage(
                  image: AssetImage('assets/soma2.png'),
                  fit: BoxFit.cover,
                  opacity: 0.05,
                  alignment: Alignment.bottomCenter,
                )
              : null,
        ),
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/loader.json',
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Loading questions...',
                      style: GoogleFonts.fredoka(
                        textStyle: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 60, color: Colors.white),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            errorMessage!,
                            style: GoogleFonts.fredoka(
                              textStyle: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF3F51B5),
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  )
                : currentBatchQuestions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Lottie.asset(
                              'assets/books.json',
                              width: 150,
                              height: 150,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No questions available for this topic',
                              style: GoogleFonts.fredoka(
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    // This is the key part that changes:
                    : SafeArea(
                        bottom: true, // Important to avoid the bottom overflow
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              // Score indicator section
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF3F51B5),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '${currentQuestionIndex + 1}/${currentBatchQuestions.length}',
                                              style: GoogleFonts.fredoka(
                                                textStyle: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Question',
                                            style: GoogleFonts.fredoka(
                                              textStyle: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF3F51B5),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            'Score: ',
                                            style: GoogleFonts.fredoka(
                                              textStyle: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF3F51B5),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.amber,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '$score',
                                              style: GoogleFonts.fredoka(
                                                textStyle: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ), // Question section - no nested ScrollView anymore
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: currentQuestionIndex <
                                        currentBatchQuestions.length
                                    ? buildQuestion()
                                    : Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Lottie.asset(
                                              'assets/congratulations.json',
                                              width: 200,
                                              height: 200,
                                            ),
                                            Text(
                                              'You have completed the quiz!',
                                              style: GoogleFonts.fredoka(
                                                textStyle: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),

                              // Add extra padding at the bottom to avoid the warning lines
                              const SizedBox(
                                  height: 165), // Increased from standard 130
                            ],
                          ),
                        ),
                      ),
      ),
    );
  } // Update the buildQuestion method to match the screenshot UI

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
              // Animated character on the left side - changes with each question
              SizedBox(
                child: Lottie.asset(
                  getCurrentAnimation(),
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
                    // Question text
                    Text(
                      question.question,
                      style: GoogleFonts.lexendDeca(
                        textStyle: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Answer options - Using simple orange buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: question.options.entries
                .map((option) => Padding(
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
                              ? Colors.orange.shade400
                              : Colors.orange.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          option.value.toString(),
                          style: GoogleFonts.lexendDeca(
                            textStyle: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          // Check Answer button
          ElevatedButton(
            onPressed: checkAnswer,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue[800],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Check Answer',
                style: GoogleFonts.lexendDeca(
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
