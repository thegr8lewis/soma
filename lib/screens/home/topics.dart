import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:system_auth/screens/home/questions.dart';
import 'package:skeleton_text/skeleton_text.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../config.dart';
import '../home/questions.dart'; // Import the correct path to QuestionsPage

// Class to model Topic data
class Topic {
  final int id;           // Used internally in the app
  final String mongoId;   // Original MongoDB ID from the backend
  final String name;
  final String? description;
  final int subjectId;
  int totalQuestions;

  Topic({
    required this.id, 
    required this.mongoId,
    required this.name, 
    this.description,
    required this.subjectId,
    this.totalQuestions = 0,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    // Debug the json data
    print('Parsing topic JSON: $json');
    
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
    
    // Generate numeric ID for internal use or use existing numeric_id if available
    int topicId;
    if (json.containsKey('numeric_id')) {
      if (json['numeric_id'] is int) {
        topicId = json['numeric_id'];
      } else if (json['numeric_id'] is String) {
        topicId = int.tryParse(json['numeric_id']) ?? 0;
      } else {
        print('Warning: Topic ID has unexpected type: ${json['numeric_id']} (${json['numeric_id'].runtimeType})');
        topicId = 0;
      }
    } else {
      // Use a simple hash of the MongoDB ID to get a numeric ID
      topicId = mongoId.hashCode.abs();
      print('Generated internal ID $topicId from MongoDB ID $mongoId');
    }
    
    // Handle different formats of subject_id
    int subjectId;
    if (json.containsKey('subject_id')) {
      if (json['subject_id'] is String) {
        subjectId = int.tryParse(json['subject_id']) ?? 0;
      } else if (json['subject_id'] is int) {
        subjectId = json['subject_id'];
      } else {
        print('Warning: subject_id has unexpected type: ${json['subject_id']} (${json['subject_id'].runtimeType})');
        subjectId = 0;
      }
    } else {
      print('Warning: JSON missing "subject_id" field');
      subjectId = 0;
    }
    
    // Handle topic name
    String name;
    if (json.containsKey('name')) {
      if (json['name'] is String) {
        name = json['name'];
      } else {
        print('Warning: Topic name has unexpected type: ${json['name']} (${json['name'].runtimeType})');
        name = 'Topic $topicId';
      }
    } else {
      print('Warning: JSON missing "name" field');
      name = 'Topic $topicId';
    }
    
    // Handle description
    String? description;
    if (json.containsKey('description')) {
      if (json['description'] is String) {
        description = json['description'];
      } else if (json['description'] != null) {
        print('Warning: Description has unexpected type: ${json['description']} (${json['description'].runtimeType})');
        description = null;
      }
    }
      return Topic(
      id: topicId,
      mongoId: mongoId,
      name: name,
      description: description,
      subjectId: subjectId,
      totalQuestions: json['total_questions'] is int ? json['total_questions'] : 0,
    );
  }
}

// Helper function to log response data
void _logResponseData(String message, dynamic data) {
  print('DEBUG: $message');
  try {
    print(json.encode(data));
  } catch (e) {
    print('Could not encode data: $e');
    print('Raw data: $data');
  }
}

class TopicsPage extends StatefulWidget {
  final int subjectId;
  final String subjectName;
  final String subject_name;
  final String subjectMongoId; // Added to store the MongoDB ID string for API calls

  const TopicsPage({
    super.key, 
    required this.subjectId, 
    required this.subjectName, 
    required this.subject_name,
    this.subjectMongoId = '', // Default to empty string if not provided
  });

  @override
  _TopicsPageState createState() => _TopicsPageState();
}

class _TopicsPageState extends State<TopicsPage> {
  List<Map<String, dynamic>> topics = [];
  bool isLoading = true;
  bool isInitialLoad = true; // New state variable
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchTopics();
  }  Future<void> fetchTopics() async {
    try {
      final authToken = await const FlutterSecureStorage().read(key: 'auth_token');
      
      if (authToken == null) {
        setState(() {
          isLoading = false;
          isInitialLoad = false;
          errorMessage = 'Authentication token not found. Please log in again.';
        });
        return;
      }      // Use MongoDB ID consistently for all subjects
      String idToUse = widget.subjectMongoId.isNotEmpty ? widget.subjectMongoId : widget.subjectId.toString();
      
      print('Fetching topics for subject "${widget.subjectName}" using ID: $idToUse (MongoDB ID: ${widget.subjectMongoId})');
      print('API URL: $BASE_URL/$idToUse/topics');
      
      final response = await http.get(
        Uri.parse('$BASE_URL/$idToUse/topics'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      print('Topics API response code: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('Response body: ${response.body}');
      }
      
      if (response.statusCode == 200) {
        // Log the raw response for debugging
        String rawResponse = response.body;
        print('Raw topics response: $rawResponse');
        
        try {
          // Try to parse the response
          List<dynamic> parsedTopics = [];
          
          // Handle JSON object wrapper or direct array
          if (rawResponse.trim().startsWith('{')) {
            // Response is a JSON object, try to find an array inside it
            Map<String, dynamic> jsonObj = json.decode(rawResponse);
            print('Response appears to be a JSON object, checking for topics array');
            
            // Check common field names that might contain the topics
            if (jsonObj.containsKey('data') && jsonObj['data'] is List) {
              print('Found topics in "data" field');
              parsedTopics = jsonObj['data'];
            } else if (jsonObj.containsKey('topics') && jsonObj['topics'] is List) {
              print('Found topics in "topics" field');
              parsedTopics = jsonObj['topics'];
            } else {
              // Look for any array in the response
              bool foundArray = false;
              for (var key in jsonObj.keys) {
                if (jsonObj[key] is List) {
                  print('Found possible topics array in field: $key');
                  parsedTopics = jsonObj[key];
                  foundArray = true;
                  break;
                }
              }
              
              if (!foundArray) {
                // If no array was found, create a list with the object itself
                print('No arrays found in response, treating as a single topic');
                parsedTopics = [jsonObj];
              }
            }
          } else {
            // Response is already an array
            parsedTopics = json.decode(rawResponse);
          }
          
          if (parsedTopics.isEmpty) {
            setState(() {
              isLoading = false;
              isInitialLoad = false;
              errorMessage = 'No topics available for your selected subject.';
            });
            return;
          }
          
          print('Found ${parsedTopics.length} topics');
          
          // Sanitize and process each topic
          List<Map<String, dynamic>> processedTopics = [];
          for (var topicData in parsedTopics) {
            if (topicData is Map<String, dynamic>) {
              try {
                // Ensure required fields exist with proper types
                var processedTopic = <String, dynamic>{};
                  // Process ID field
                if (topicData.containsKey('id')) {
                  // Store the original MongoDB ID string for API calls
                  if (topicData['id'] is String) {
                    processedTopic['mongo_id'] = topicData['id'];
                    // Generate a numeric ID for internal use
                    processedTopic['id'] = topicData['id'].hashCode.abs();
                  } else if (topicData['id'] is int) {
                    processedTopic['id'] = topicData['id'];
                    processedTopic['mongo_id'] = topicData['id'].toString();
                  } else {
                    processedTopic['id'] = 0;
                    processedTopic['mongo_id'] = '0';
                  }
                } else {
                  // Generate a random ID if missing
                  processedTopic['id'] = processedTopics.length + 1;
                  processedTopic['mongo_id'] = processedTopic['id'].toString();
                }
                  // Process name field
                if (topicData.containsKey('topic_name') && topicData['topic_name'] is String) {
                  processedTopic['name'] = topicData['topic_name'];
                } else if (topicData.containsKey('name') && topicData['name'] is String) {
                  processedTopic['name'] = topicData['name'];
                } else {
                  processedTopic['name'] = 'Topic ${processedTopic['id']}';
                }
                
                // Store the original topic_name for API calls if available
                if (topicData.containsKey('topic_name') && topicData['topic_name'] is String) {
                  processedTopic['topic_name'] = topicData['topic_name'];
                } else {
                  processedTopic['topic_name'] = processedTopic['name'];
                }
                
                // Process description field
                if (topicData.containsKey('description') && topicData['description'] is String) {
                  processedTopic['description'] = topicData['description'];
                } else {
                  processedTopic['description'] = '';
                }
                
                // Process subject_id field
                if (topicData.containsKey('subject_id')) {
                  if (topicData['subject_id'] is int) {
                    processedTopic['subject_id'] = topicData['subject_id'];
                  } else if (topicData['subject_id'] is String) {
                    processedTopic['subject_id'] = int.tryParse(topicData['subject_id']) ?? widget.subjectId;
                  } else {
                    processedTopic['subject_id'] = widget.subjectId;
                  }
                } else {
                  processedTopic['subject_id'] = widget.subjectId;
                }
                  processedTopics.add(processedTopic);
                print('Processed topic: ${processedTopic['name']} (ID: ${processedTopic['id']}, MongoDB ID: ${processedTopic['mongo_id']}, Topic Name for API: ${processedTopic['topic_name']})');
              } catch (e) {
                print('Error processing topic data: $e');
                print('Problem data: $topicData');
              }
            }
          }
          
          // Load total questions for each topic
          for (var topic in processedTopics) {
            try {
              final totalQuestions = await fetchTotalQuestions(topic['id']);
              topic['total_questions'] = totalQuestions;
              print('Topic ${topic['name']} has $totalQuestions questions');
            } catch (e) {
              print('Error fetching question count for topic ${topic['id']}: $e');
              topic['total_questions'] = 0;
            }
          }

          setState(() {
            topics = processedTopics;
            isLoading = false;
            isInitialLoad = false;
          });
        } catch (e) {
          print('Error parsing topics response: $e');
          setState(() {
            isLoading = false;
            isInitialLoad = false;
            errorMessage = 'Error parsing topics: $e';
          });
        }
      } else {
        print('Failed to load topics. Status code: ${response.statusCode}');
        setState(() {
          isLoading = false;
          isInitialLoad = false;
          errorMessage = 'Failed to load topics. Status code: ${response.statusCode}';
        });
      }
    } catch (e) {
      print('Error in fetchTopics: $e');
      setState(() {
        isLoading = false;
        isInitialLoad = false;
        errorMessage = 'Network error: $e';
      });
    }
  }  Future<int> fetchTotalQuestions(int topicId) async {
    try {
      final authToken = await const FlutterSecureStorage().read(key: 'auth_token');
      
      if (authToken == null) {
        print('Authentication token not found for fetchTotalQuestions');
        return 0;
      }      // Get the MongoDB ID and topic_name for this topic
      String mongoId = '0';
      String topicName = '';
      for (var topic in topics) {
        if (topic['id'] == topicId) {
          if (topic.containsKey('mongo_id')) {
            mongoId = topic['mongo_id'];
          }
          if (topic.containsKey('topic_name')) {
            topicName = topic['topic_name'];
          } else if (topic.containsKey('name')) {
            topicName = topic['name'];
          }
          break;
        }
      }      // Use MongoDB ID when available, especially when topic_name is just 'Bible'
      String idToUse;
      if (mongoId != '0') {
        idToUse = mongoId;  // Always prefer MongoDB ID for API calls
      } else if (topicName.isNotEmpty && topicName != "Topic") {
        idToUse = topicName;  // Use topic_name only if it's not just "Bible"
      } else {
        idToUse = topicId.toString();  // Last resort: use numeric ID
      }
      
      // Use MongoDB ID consistently for subject as well
      String subjectIdToUse = widget.subjectMongoId.isNotEmpty ? widget.subjectMongoId : widget.subjectName;      final String url = '$BASE_URL/questions/$subjectIdToUse/$idToUse';
      print('Fetching questions count from: $url');
      print('Using MongoDB ID: $mongoId (Priority 1), Topic Name (if not "Topic"): $topicName (Priority 2), Topic ID: $topicId (Priority 3)');
      print('Using Subject: ${widget.subjectName}, Subject MongoDB ID: ${widget.subjectMongoId}');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );
  
      print('Questions API response for topic $topicId: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // Log the raw response
        String rawResponse = response.body;
        print('Raw questions response (first 100 chars): ${rawResponse.substring(0, min(100, rawResponse.length))}...');
        
        try {
          // Try to parse the response
          List<dynamic> questions = [];
          
          // Handle JSON object wrapper or direct array
          if (rawResponse.trim().startsWith('{')) {
            // Response is a JSON object, try to find an array inside it
            Map<String, dynamic> jsonObj = json.decode(rawResponse);
            print('Questions response appears to be a JSON object');
            
            // Check common field names that might contain the questions
            if (jsonObj.containsKey('data') && jsonObj['data'] is List) {
              print('Found questions in "data" field');
              questions = jsonObj['data'];
            } else if (jsonObj.containsKey('questions') && jsonObj['questions'] is List) {
              print('Found questions in "questions" field');
              questions = jsonObj['questions'];
            } else {
              // Look for any array in the response
              bool foundArray = false;
              for (var key in jsonObj.keys) {
                if (jsonObj[key] is List) {
                  print('Found possible questions array in field: $key');
                  questions = jsonObj[key];
                  foundArray = true;
                  break;
                }
              }
              
              if (!foundArray) {
                // If no array was found, check if the object itself looks like a question
                print('No arrays found in response');
                if (jsonObj.containsKey('question') || jsonObj.containsKey('id')) {
                  print('The object itself appears to be a single question');
                  questions = [jsonObj];
                }
              }
            }
          } else {
            // Response is already an array
            questions = json.decode(rawResponse);
          }
          
          if (questions.isEmpty) {
            print('No questions found for topic $topicId');
            return 0;
          }
          
          print('Found ${questions.length} questions for topic $topicId');
          return questions.length;
        } catch (e) {
          print('Error parsing questions response: $e');
          return 0;
        }
      } else {
        print('Failed to load questions. Status code: ${response.statusCode}');
        return 0;
      }
    } catch (e) {
      print('Error in fetchTotalQuestions: $e');
      return 0;
    }
  }
  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      itemCount: 8, // Number of skeleton cards to display
      itemBuilder: (context, index) {
        return Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: Colors.blue.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonAnimation(
                  child: Container(
                    height: 20,
                    width: MediaQuery.of(context).size.width * 0.6,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SkeletonAnimation(
                  child: Container(
                    height: 20,
                    width: MediaQuery.of(context).size.width * 0.2,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.subjectName,
          style: GoogleFonts.poppins(
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0, // Remove shadow for a modern look
      ),
      body: Container(
        decoration: const BoxDecoration(
          // Create a beautiful gradient background
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8F9FA), // Light blue-grey at the top
              Color(0xFFE3F2FD), // Lighter blue in the middle
              Color(0xFFD5E8FC), // Soft blue at the bottom
            ],
          ),
        ),
        child: isInitialLoad
            ? _buildSkeletonLoader()
            : errorMessage != null
                ? Center(
                    child: Text(
                      errorMessage!,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  )
                : topics.isEmpty
                    ? const Center(
                        child: Text(
                          'No topics available for now.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      )                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      itemCount: topics.length,
                      itemBuilder: (context, index) {
                        final topic = topics[index];
                        return Center( // Center the container within the ListView
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.9, // Control the width here
                            margin: const EdgeInsets.symmetric(vertical: 10), // Adjust vertical margin
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), // Adjust padding
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.1),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              // Add a subtle border
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.1),
                                width: 1,
                              ),
                            ),                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                              title: Text(
                                topic['name'] ?? 'No name', // Use the correct field name
                                style: GoogleFonts.poppins(
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF3F51B5), // Indigo color for the title
                                  ),
                                ),
                              ),
                              // trailing: Container(
                              //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              //   decoration: BoxDecoration(
                              //     color: const Color(0xFFE8EAF6), // Light indigo background
                              //     borderRadius: BorderRadius.circular(20),
                              //   ),
                              //   child: Text(
                              //     '${topic['total_questions'] ?? 0} Q', // Display total questions
                              //     style: GoogleFonts.poppins(
                              //       textStyle: const TextStyle(
                              //         fontSize: 14,
                              //         fontWeight: FontWeight.w500,
                              //         color: Color(0xFF3F51B5), // Matching indigo color
                              //       ),
                              //     ),
                              //   ),
                              // ),
                              onTap: () {                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QuestionsPage(
                                      topicId: topic['id'] ?? 0,
                                      topicName: topic['name'] ?? 'Unknown',
                                      subjectName: widget.subjectName,
                                      topicMongoId: topic['mongo_id'] ?? '', // Pass the topic MongoDB ID
                                      subjectMongoId: widget.subjectMongoId, // Pass the subject MongoDB ID
                                      topicOriginalName: topic['topic_name'] ?? topic['name'] ?? '', // Pass the original topic_name for API calls
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
      ),
    );
  }
}