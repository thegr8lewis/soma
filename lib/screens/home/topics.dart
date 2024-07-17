import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:system_auth/screens/home/questions.dart';
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
        for (var topic in parsedTopics) {
          final totalQuestions = await fetchTotalQuestions(topic['id']);
          topic['total_questions'] = totalQuestions;
        }
        setState(() {
          topics = parsedTopics.cast<Map<String, dynamic>>();
        });
      } else {
        throw Exception('Failed to load topics');
      }
    } catch (e) {
      print('Error fetching topics: $e');
      // Handle error as needed
    }
  }

  Future<int> fetchTotalQuestions(int topicId) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/questions/${widget.subjectName}/$topicId'),
      );

      if (response.statusCode == 200) {
        final questions = json.decode(response.body) as List<dynamic>;
        return questions.length;
      } else {
        throw Exception('Failed to load questions');
      }
    } catch (e) {
      print('Error fetching total questions: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectName),
      ),
      body: topics.isEmpty
          ? const Center(child: CircularProgressIndicator())
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
                title: Text(topic['topic_name'] ?? 'No name'), // Use null-aware operator
                trailing: Text(
                  '${topic['total_questions'] ?? 0} questions', // Display total questions
                  // style: const TextStyle(fontWeight: FontWeight.bold),
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
