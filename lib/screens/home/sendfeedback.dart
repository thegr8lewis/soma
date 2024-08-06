import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'dart:io';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';

class SendFeedbackPage extends StatefulWidget {
  @override
  _SendFeedbackPageState createState() => _SendFeedbackPageState();
}

class _SendFeedbackPageState extends State<SendFeedbackPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  File? _screenshot;
  bool _isSending = false;

  Future<void> _pickScreenshot() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _screenshot = File(pickedFile.path);
      }
    });
  }

  Future<void> _sendFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback cannot be empty')));
      return;
    }

    setState(() {
      _isSending = true;
    });

    final Email email = Email(
      body: 'Name: ${_nameController.text}\n\nFeedback: ${_feedbackController.text}',
      subject: 'App Feedback',
      recipients: ['lewis.nyakaru@gmail.com'],
      attachmentPaths: _screenshot != null ? [_screenshot!.path] : null,
      isHTML: false,
    );

    try {
      await FlutterEmailSender.send(email);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback sent successfully')));
      _nameController.clear();
      _feedbackController.clear();
      setState(() {
        _screenshot = null;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send feedback: $error')));
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Feedback & Report Bug'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              child: Lottie.asset(
                'assets/email.json',
                repeat: true,
                width: 200,
                height: 250,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter your name',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.green),
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: Icon(FontAwesomeIcons.user, color: Colors.green[500]),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _feedbackController,
              maxLines: null,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: 'Please describe what you want',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.green),
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: _pickScreenshot,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, color: Colors.grey),
                    SizedBox(width: 10),
                    Text(
                      'Upload screenshot',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            if (_screenshot != null) ...[
              const SizedBox(height: 10),
              Image.file(_screenshot!, height: 100),
            ],
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isSending ? null : _sendFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSending ? Colors.grey : Colors.green[500],
              ),
              child: _isSending ? const CircularProgressIndicator() : const Text('SUBMIT', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
