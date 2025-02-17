import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:system_auth/screens/home/questions.dart';
import 'package:skeleton_text/skeleton_text.dart';
import 'dart:convert';

import '../../config.dart';
import '../home/questions.dart'; // Import the correct path to QuestionsPage

class TopicsPage extends StatefulWidget {
  final int subjectId;
  final String subjectName;
  final String subject_name; // Corrected variable name

  TopicsPage({required this.subjectId, required this.subjectName, required this.subject_name});

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
  }

  Future<void> fetchTopics() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/${widget.subjectId}/topics'), // Adjust the API endpoint according to your backend
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> parsedTopics = json.decode(response.body);
        
        if (parsedTopics.isEmpty) {
          setState(() {
            isLoading = false;
            isInitialLoad = false;
            errorMessage = 'No topics available for now.';
          });
          return;
        }

        // Load total questions for each topic
        for (var topic in parsedTopics) {
          final totalQuestions = await fetchTotalQuestions(topic['id']);
          topic['total_questions'] = totalQuestions;
        }

        setState(() {
          topics = parsedTopics.cast<Map<String, dynamic>>();
          isLoading = false;
          isInitialLoad = false;
        });
      } else {
        // throw Exception('Failed to load topics. Status code: ${response.statusCode}');
        throw Exception('No topics found');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isInitialLoad = false;
        errorMessage = e.toString();
      });
    }
  }

    Future<int> fetchTotalQuestions(int topicId) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/questions/${widget.subjectName}/$topicId'),
      );
  
      if (response.statusCode == 200) {
        final questions = json.decode(response.body) as List<dynamic>;
        if (questions.isEmpty) {
          return 0; // Return 0 if no questions found
        }
        return questions.length;
      } else {
        throw Exception('Failed to load questions. Status code: ${response.statusCode}');
        // throw Exception('No topics found');
      }
    } catch (e) {
      throw Exception('Error fetching total questions: $e');
    }
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      itemCount: 8, // Number of skeleton cards to display
      itemBuilder: (context, index) {
        return Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonAnimation(
                  child: Container(
                    height: 20,
                    width: MediaQuery.of(context).size.width * 0.6,
                    color: Colors.grey[300],
                  ),
                ),
                const SizedBox(height: 8),
                SkeletonAnimation(
                  child: Container(
                    height: 20,
                    width: MediaQuery.of(context).size.width * 0.4,
                    color: Colors.grey[300],
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
      ),
      body: isInitialLoad
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
                    )
                  : ListView.builder(
                      itemCount: topics.length,
                      itemBuilder: (context, index) {
                        final topic = topics[index];
                        return Center( // Center the container within the ListView
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.9, // Control the width here
                            margin: const EdgeInsets.symmetric(vertical: 8), // Adjust vertical margin
                            padding: const EdgeInsets.all(16), // Adjust padding
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListTile(
                              title: Text(
                                topic['topic_name'] ?? 'No name', // Use null-aware operator
                                style: GoogleFonts.poppins(
                                  textStyle: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.brown,
                                  ),
                                ),
                              ),
                              trailing: Text(
                                '${topic['total_questions'] ?? 0} Q', // Display total questions
                                style: GoogleFonts.poppins(
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QuestionsPage(
                                      topicId: topic['id'] ?? 0, // Example default value
                                      topicName: topic['topic_name'] ?? 'Unknown', // Example default value
                                      subjectName: widget.subjectName,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}