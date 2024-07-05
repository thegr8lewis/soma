import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

import '../../config.dart';
import '../../trialpages/trial3.dart';
import 'questions.dart';

class TopicsPage extends StatefulWidget {
  final int subjectId;
  final String subjectName;

  TopicsPage({required this.subjectId, required this.subjectName});

  @override
  _TopicsPageState createState() => _TopicsPageState();
}

class _TopicsPageState extends State<TopicsPage> {
  List topics = [];
  int? selectedTopicIndex; // Track the index of the selected topic

  @override
  void initState() {
    super.initState();
    fetchTopics();
  }

  fetchTopics() async {
    final response = await http.get(Uri.parse('$BASE_URL/${widget.subjectId}/topics'));
    if (response.statusCode == 200) {
      setState(() {
        topics = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load topics');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subjectName} Topics'),
      ),
      body: ListView.builder(
        itemCount: topics.length,
        itemBuilder: (context, index) {
          var topic = topics[index];
          var topicName = topic['topic_name'] ?? 'Unnamed Topic';
          bool isSelected = index == selectedTopicIndex; // Check if this topic is selected
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedTopicIndex = index; // Update the selected topic index
              });
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                  Quest()
                  //     QuestionsPage(
                  //   topicId: topic['id'],
                  //   topicName: topicName,
                  // ),
                ),
              );
            },
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              elevation: 4,
              margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: isSelected ? Colors.grey[200] : Colors.white, // Change color based on selection
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                title: Text(
                  topicName,
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
