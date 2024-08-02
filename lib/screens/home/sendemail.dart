import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:lottie/lottie.dart';

class SendEmailFromFlutterApp extends StatefulWidget {
  const SendEmailFromFlutterApp({super.key});

  @override
  State<SendEmailFromFlutterApp> createState() => _SendEmailFromFlutterAppState();
}

class _SendEmailFromFlutterAppState extends State<SendEmailFromFlutterApp> {
  final key = GlobalKey<FormState>();
  TextEditingController subject = TextEditingController();
  TextEditingController body = TextEditingController();

  sendEmail(String subject, String body) async {
    final Email email = Email(
      body: body,
      subject: subject,
      recipients: ['lewis.nyakaru@gmail.com'],
      isHTML: false,
    );
    await FlutterEmailSender.send(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Send Feedback & Report Bug"),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double padding = constraints.maxWidth * 0.05;
          double iconSize = constraints.maxWidth * 0.08;
          double buttonPadding = constraints.maxWidth * 0.08;
          double buttonFontSize = constraints.maxWidth * 0.045;
          double textFieldFontSize = constraints.maxWidth * 0.04;

          return Padding(
            padding: EdgeInsets.all(padding),
            child: SingleChildScrollView(
              child: Form(
                key: key,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 250,
                      height: 250,
                      child: Lottie.asset(
                        'assets/email.json',
                        repeat: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: subject,
                      decoration: InputDecoration(
                        hintText: "Enter subject",
                        hintStyle: TextStyle(fontSize: textFieldFontSize),
                        labelStyle: TextStyle(color: Colors.grey, fontSize: textFieldFontSize),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green[500]!),
                        ),
                        prefixIcon: Icon(Icons.subject, color: Colors.green[500], size: iconSize),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a subject';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: body,
                      maxLength: 400,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "Enter body (max 400 characters)",
                        hintStyle: TextStyle(fontSize: textFieldFontSize),
                        labelStyle: TextStyle(color: Colors.grey, fontSize: textFieldFontSize),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green[500]!),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the body of the email';
                        } else if (value.length > 400) {
                          return 'The body cannot exceed 400 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (subject.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Please enter a subject')),
                          );
                        } else if (body.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Please enter the body of the email')),
                          );
                        } else if (key.currentState!.validate()) {
                          key.currentState!.save();
                          sendEmail(subject.text, body.text);
                          subject.clear();
                          body.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Email Sent Successfully')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: buttonPadding, vertical: 15),
                        textStyle: TextStyle(fontSize: buttonFontSize),
                        backgroundColor: Colors.green[500],
                      ),
                      child: const Text("Send Mail",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
