import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Quest extends StatefulWidget {
  const Quest({super.key});

  @override
  State<Quest> createState() => _QuestState();
}

class _QuestState extends State<Quest> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDF7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.brown[800]),
          onPressed: () {
            Navigator.pop(context); // Navigate back to TopicsPage
          },
        ),
        actions: [
          SizedBox(height: 10,),
          // TextButton(
          //   onPressed: () {
          //     // Add your button action here
          //   },
          //   child: Text(
          //     'Skip',
          //     style: GoogleFonts.poppins(
          //       textStyle: TextStyle(
          //         fontSize: 16,
          //         fontWeight: FontWeight.bold,
          //         color: Colors.orange,
          //       ),
          //     ),
          //   ),
          // )
        ],
        title: Center(
          child: Text(
            'Math Quiz',
            style: GoogleFonts.poppins(
              textStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.brown[800],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '1/20',
                    style: GoogleFonts.poppins(
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[800],
                      ),
                    ),
                  ),
                  SizedBox(width: 10,),
                  Expanded(
                    child: SizedBox(
                      height: 10,
                      child: LinearProgressIndicator(
                        value: 12 / 20,
                        backgroundColor: Colors.orange[100],
                        color: Color.fromARGB(255, 15, 160, 27),
                        valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 15, 160, 27)),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                'If David’s age is 27 years old in 2011. What was his age in 2003?',
                style: GoogleFonts.poppins(
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown[800],
                  ),
                ),
              ),
              SizedBox(height: 20),
              _buildOptionCard('19 years', true),
              _buildOptionCard('37 years', false),
              _buildOptionCard('20 years', false),
              _buildOptionCard('17 years', false),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  // Handle report question action
                },
                child: Row(
                  children: [
                    Icon(Icons.flag, color: Colors.brown[800]),
                    SizedBox(width: 10),
                    Text(
                      'Report question',
                      style: GoogleFonts.poppins(
                        textStyle: TextStyle(
                          fontSize: 16,
                          color: Colors.brown[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(String option, bool isCorrect) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(35.0),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            option,
            style: GoogleFonts.poppins(
              textStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          if (isCorrect)
            Icon(Icons.check_circle, color: Colors.white),
        ],
      ),
    );
  }
}
