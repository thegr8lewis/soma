import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'dart:convert';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:system_auth/config.dart';
import 'package:system_auth/screens/authenticate/log_in.dart';
import 'package:system_auth/screens/home/profile/userprofile.dart';
import 'package:system_auth/screens/home/topics.dart';
import 'package:system_auth/trialpages/notification.dart';
import '../screens/home/dailyquiz.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _PamelaState();
}

class _PamelaState extends State<Homepage> {
  int _selectedIndex = 0;
  late Future<List<Subject>> _subjectsFuture;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _firstName;
  String? _initials;

  @override
  void initState() {
    super.initState();
    _subjectsFuture = _fetchSubjects();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final sessionCookie = await _storage.read(key: 'session_cookie');
      if (sessionCookie == null) {
        throw Exception('No session cookie found');
      }

      final response = await http.get(
        Uri.parse('$BASE_URL/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': sessionCookie,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final username = data['username'] as String;
        setState(() {
          _firstName = username.split(' ')[0]; // Get the first name from the username
          _initials = _firstName!.substring(0, 2).toUpperCase(); // Get the first two letters of the first name
        });
      } else {
        print('Failed to load user data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<List<Subject>> _fetchSubjects() async {
    try {
      final sessionCookie = await _storage.read(key: 'session_cookie');
      if (sessionCookie == null) {
        throw Exception('No session cookie found');
      }

      final response = await http.get(
        Uri.parse('$BASE_URL/subjects'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': sessionCookie,
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        List<Subject> subjects = body.map((dynamic item) => Subject.fromJson(item)).toList();

        // Fetch topic counts for each subject
        for (var subject in subjects) {
          final topicsResponse = await http.get(
            Uri.parse('$BASE_URL/${subject.id}/topics'),
            headers: {
              'Content-Type': 'application/json',
              'Cookie': sessionCookie,
            },
          );

          if (topicsResponse.statusCode == 200) {
            List<dynamic> topicsBody = json.decode(topicsResponse.body);
            subject.topicCount = topicsBody.length;
          } else {
            subject.topicCount = 0;
          }
        }

        return subjects;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized request. Please check your credentials.');
      } else {
        throw Exception('Failed to load subjects. Status code');
      }
    } on SocketException catch (_) {
      throw Exception('No Internet connection. Please check your network.');
    } on HttpException catch (_) {
      throw Exception('Could not find the requested resource.');
    } catch (e) {
      throw Exception('Error fetching subjects:');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  const Color(0xFFFDF7F2),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeScreen(
              subjectsFuture: _subjectsFuture,
              firstName: _firstName,
              initials: _initials),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xD20F142F),
        unselectedItemColor: Colors.black54,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final Future<List<Subject>> subjectsFuture;
  final String? firstName;
  final String? initials;

  const HomeScreen(
      {Key? key, required this.subjectsFuture, this.firstName, this.initials})
      : super(key: key);

  Future<int> _fetchPoints() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('score') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '👋 Hi ${firstName ?? 'There'},',
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Text(
                        'Great to see you again!',
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            fontSize: 15,
                            color: Colors.brown,
                          ),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    child: SizedBox(
                      child: Lottie.asset(
                        'assets/books.json',
                        repeat: true,
                        width: 110,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              FutureBuilder<int>(
                future: _fetchPoints(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error loading points'));
                  } else {
                    return _buildStatSection(snapshot.data ?? 0);
                  }
                },
              ),
              const SizedBox(height: 5),
              _buildCourseSection(context),
              const SizedBox(height: 5),
              _buildSubjectsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatSection(int points) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: const Color(0xD20F142F),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSingleStatCard(points.toString(), 'Points Earned', Colors.orange),
            ],
          ),
        ),
        const SizedBox(height: 1.0),
      ],
    );
  }

  Widget _buildSingleStatCard(String value, String label, Color color) {
    String imagePath = 'assets/star.gif';

    if (label == 'Exp. Points') {
      imagePath = 'assets/star.gif';
    } else if (label == 'Questions Done') {
      imagePath = 'assets/soma1.png';
    }

    return Row(
      children: [
        Image.asset(
          imagePath,
          width: 32,
          height: 32,
          color: color,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCourseSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Practice More'),
        _buildDailyQuizCard(context),
        const SizedBox(height: 5),
        _buildSectionTitle('Subjects'),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.brown,
      ),
    );
  }

  Widget _buildDailyQuizCard(BuildContext context) {
    double quizProgress = 0.1;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DailyQuizScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Quiz',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  'Predictable Questions',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              child: Lottie.asset(
                'assets/books.json',
                repeat: true,
                width: 110,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectsSection(BuildContext context) {
    return FutureBuilder<List<Subject>>(
      future: subjectsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: Lottie.asset('assets/loader.json', width: 50));
        } else if (snapshot.hasError) {
          if (snapshot.error.toString().contains('NetworkError')) {
            return SizedBox(
              child: Lottie.asset(
                'assets/network.json',
                repeat: true,
                width: 110,
              ),
            );
          } else {
            return const Center(child: Text('Error fetching subjects:'));
          }
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No subjects available.'));
        } else {
          return _buildSubjectsList(snapshot.data!, context);
        }
      },
    );
  }

  Widget _buildSubjectsList(List<Subject> subjects, BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TopicsPage(
                  subjectId: subject.id,
                  subjectName: subject.name ?? 'No name',
                  subject_name: '',
                ),
              ),
            );
          },
          child: Card(
            elevation: 4,
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Container(
              height: 100,
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                title: Text(
                  subject.name ?? 'No name',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                ),
                subtitle: Text(
                  '${subject.topicCount} topics',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class Subject {
  final String? name;
  final String? description;
  final int id;
  final int grade;
  int topicCount;

  Subject({this.name, this.description, required this.id, required this.grade, this.topicCount = 0});

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      name: json['name'] as String?,
      description: json['description'] as String?,
      id: json['id'],
      grade: json['grade'],
      topicCount: json['topicCount'] ?? 0,
    );
  }
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            textStyle: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('GENERAL'),
          _buildListTile(
            context,
            icon: Icons.person,
            title: 'Account',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfilePage(),
                ),
              );
            },
          ),
          _buildListTile(
            context,
            icon: Icons.notifications,
            title: 'Notifications',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationsPage(),
                ),
              );
            },
          ),
          _buildListTile(
            context,
            icon: Icons.card_giftcard,
            title: 'Coupons',
            onTap: () {
            },
          ),
          _buildListTile(
            context,
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(
                      'Confirm Logout',
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    content: Text(
                      'Are you sure you want to log out?',
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text(
                          'No',
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              fontSize: 16,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: Text(
                          'Yes',
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              fontSize: 16,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LogIn(),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('FEEDBACK'),
          _buildListTile(
            context,
            icon: Icons.bug_report,
            title: 'Report a bug',
            onTap: () {
            },
          ),
          _buildListTile(
            context,
            icon: Icons.feedback,
            title: 'Send feedback',
            onTap: () {
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context,
      {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          textStyle: const TextStyle(
            fontSize: 16,
          ),
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: const Center(
        child: Text('Notifications Page'),
      ),
    );
  }
}
