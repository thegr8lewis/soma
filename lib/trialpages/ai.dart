import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';



class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _questionController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  Future<void> _sendMessage(String question) async {
    if (question.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _messages.add({'role': 'user', 'text': question});
    });

    try {
      final response = await http.post(
        Uri.parse('https://api.llama.com/v1/answers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer LL-ilIZfdLsMW4Uym5fQuxxSQ7gxSWWyb4kmGlzASeWnzm2tj6GW9zis8W7EPSyBQQ2',
        },
        body: json.encode({
          'question': question,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['answer'] != null) {
          setState(() {
            _messages.add({'role': 'llama', 'text': data['answer']});
          });
        } else {
          setState(() {
            _messages.add({'role': 'llama', 'text': 'Received an invalid response from the API.'});
          });
        }
      } else {
        setState(() {
          _messages.add({'role': 'llama', 'text': 'Failed to get response from the API.'});
        });
      }
    } catch (error) {
      setState(() {
        _messages.add({'role': 'llama', 'text': 'An error occurred: $error'});
      });
    } finally {
      setState(() {
        _isLoading = false;
        _questionController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ListTile(
                  leading: message['role'] == 'llama' ? Icon(FontAwesomeIcons.robot, color: Colors.green) : Icon(FontAwesomeIcons.user, color: Colors.blue),
                  title: Text(message['text'] ?? 'Error: Message text is null'),
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      hintText: 'Enter your question',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () => _sendMessage(_questionController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
