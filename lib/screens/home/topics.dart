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
  String errorMessage = '';

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
        final List<Future<void>> fetches = parsedTopics.map((topic) async {
          final totalQuestions = await fetchTotalQuestions(topic['id']);
          topic['total_questions'] = totalQuestions;
        }).toList();

        await Future.wait(fetches);

        setState(() {
          topics = parsedTopics.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else {
        handleHttpError(response.statusCode);
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<int> fetchTotalQuestions(int topicId) async {
    final response = await http.get(
      Uri.parse('$BASE_URL/questions/${widget.subjectName}/$topicId'),
    );

    if (response.statusCode == 200) {
      final questions = json.decode(response.body) as List<dynamic>;
      return questions.length;
    } else {
      handleHttpError(response.statusCode);
      return 0; // Return 0 in case of an error
    }
  }

  void handleHttpError(int statusCode) {
    if (statusCode == 401) {
      throw Exception('Unauthorized request. Please check your credentials.');
    } else {
      throw Exception('Failed to load data. Status code: $statusCode');
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
      body: isLoading
          ? _buildSkeletonLoader()
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : ListView.builder(
        itemCount: topics.length,
        itemBuilder: (context, index) {
          final topic = topics[index];
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
              child: ListTile(
                title: Text(
                  topic['topic_name'] ?? 'No name',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                ),
                trailing: Text(
                  '${topic['total_questions'] ?? 0} Q',
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
                        topicId: topic['id'] ?? 0,
                        topicName: topic['topic_name'] ?? 'Unknown',
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
