class Question {
  final int id;         // Internal app ID 
  final String mongoId; // Original MongoDB ID from the backend
  final String grade;
  final String subject;
  final int topicId;
  final String question;
  final String? imageUrl;
  final Map<String, dynamic> options;
  final String correctAnswer;

  Question({
    required this.id,
    required this.mongoId,
    required this.grade,
    required this.subject,
    required this.topicId,
    required this.question,
    this.imageUrl,
    required this.options,
    required this.correctAnswer,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    // Debug the JSON data
    print('Parsing question JSON: $json');
    
    // Store the original MongoDB ID as a string for API calls
    String mongoId = '';
    if (json.containsKey('id')) {
      if (json['id'] is String) {
        mongoId = json['id'];
      } else {
        print('Warning: MongoDB ID is not a string: ${json['id']}');
        mongoId = json['id'].toString();
      }
    } else {
      print('Warning: JSON missing "id" field');
      mongoId = '0';
    }
    
    // Process ID for internal use
    int questionId;
    if (json.containsKey('numeric_id')) {
      if (json['numeric_id'] is int) {
        questionId = json['numeric_id'];
      } else if (json['numeric_id'] is String) {
        questionId = int.tryParse(json['numeric_id']) ?? 0;
      } else {
        print('Warning: Question numeric_id has unexpected type: ${json['numeric_id']}');
        questionId = 0;
      }
    } else {
      // Use a simple hash of the MongoDB ID to get a numeric ID
      questionId = mongoId.hashCode.abs();
      print('Generated internal ID $questionId from MongoDB ID $mongoId');
    }
    
    // Process grade
    String grade = '';
    if (json.containsKey('grade')) {
      grade = json['grade']?.toString() ?? '';
    }
    
    // Process subject
    String subject = '';
    if (json.containsKey('subject')) {
      subject = json['subject']?.toString() ?? '';
    }
    
    // Process topic_id
    int topicId;
    if (json.containsKey('topic_id')) {
      if (json['topic_id'] is int) {
        topicId = json['topic_id'];
      } else if (json['topic_id'] is String) {
        topicId = int.tryParse(json['topic_id']) ?? 0;
      } else {
        print('Warning: Topic ID has unexpected type: ${json['topic_id']} (${json['topic_id'].runtimeType})');
        topicId = 0;
      }
    } else {
      print('Warning: JSON missing "topic_id" field');
      topicId = 0;
    }
    
    // Process question text
    String questionText = 'Question not available';
    if (json.containsKey('question')) {
      if (json['question'] is String) {
        questionText = json['question'];
      } else {
        print('Warning: Question text has unexpected type: ${json['question']} (${json['question'].runtimeType})');
      }
    }
    
    // Process options
    Map<String, dynamic> optionsMap = {};
    if (json.containsKey('options')) {
      var options = json['options'];
      
      if (options is List) {
        // Convert list to map with letter keys
        List<dynamic> optionsList = options;
        for (int i = 0; i < optionsList.length; i++) {
          // Use letters as keys: A, B, C, D, etc.
          String key = String.fromCharCode(65 + i); // 65 is ASCII for 'A'
          optionsMap[key] = optionsList[i];
        }
      } else if (options is Map) {
        // Use the map directly, possibly after normalization
        optionsMap = Map<String, dynamic>.from(options);
      }
    } else {
      // Try to find option fields (like option_a, option_b, etc.)
      for (var key in json.keys) {
        if (key.startsWith('option_') && key.length > 7) {
          String optionKey = key.substring(7).toUpperCase(); // Extract the letter part
          optionsMap[optionKey] = json[key];
        }
      }
    }
    
    // Process correct answer
    String correctAnswer = '';
    if (json.containsKey('correct_answer')) {
      if (json['correct_answer'] is String) {
        correctAnswer = json['correct_answer'];
      } else if (json['correct_answer'] is int) {
        // Convert numeric index to letter (0 -> A, 1 -> B, etc.)
        int index = json['correct_answer'];
        correctAnswer = String.fromCharCode(65 + index);
      }
    } else if (json.containsKey('answer')) {
      correctAnswer = json['answer'].toString();
    }
      return Question(
      id: questionId,
      mongoId: mongoId,
      grade: grade,
      subject: subject,
      topicId: topicId,
      question: questionText,
      imageUrl: json['image_url']?.toString(),
      options: optionsMap,
      correctAnswer: correctAnswer,
    );
  }
}