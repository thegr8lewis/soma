import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:skeleton_text/skeleton_text.dart';
import 'dart:convert';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:system_auth/config.dart';
import 'package:system_auth/screens/authenticate/log_in.dart';
import 'package:system_auth/screens/home/profile/userprofile.dart';
import 'package:system_auth/screens/home/topics.dart';
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
  final ValueNotifier<int> _pointsNotifier = ValueNotifier<int>(0);
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _subjectsFuture = _fetchSubjects();
    _fetchUserData();
    _fetchPoints();
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

  Future<void> _fetchPoints() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _pointsNotifier.value = prefs.getInt('total_score') ?? 0;
  }

  Future<void> _refreshData() async {
    // Fetch the latest points and subjects
    await _fetchPoints();
    setState(() {
      _subjectsFuture = _fetchSubjects();
    });
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

        // Fetch topic counts for each subject in parallel
        await Future.wait(subjects.map((subject) async {
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
        }));

        setState(() {
          isLoading = false;
        });
        return subjects;
      } else {
        handleHttpError(response.statusCode);
      }
    } on SocketException catch (_) {
      throw Exception('No Internet connection. Please check your network.');
    } on HttpException catch (_) {
      throw Exception('Could not find the requested resource.');
    } catch (e) {
      throw Exception('Error fetching subjects: $e');
    }

    // Return an empty list if an error occurs
    return [];
  }

  void handleHttpError(int statusCode) {
    setState(() {
      isLoading = false;
      errorMessage = 'Failed to load subjects. Status code: $statusCode';
    });
    if (statusCode == 401) {
      throw Exception('Unauthorized request. Please check your credentials.');
    } else {
      throw Exception('Failed to load subjects. Status code: $statusCode');
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
      backgroundColor: const Color(0xFFFDF7F2),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeScreen(
            subjectsFuture: _subjectsFuture,
            firstName: _firstName,
            initials: _initials,
            pointsNotifier: _pointsNotifier,
            onPointsChanged: _fetchPoints, // Callback to fetch points when they change
            onRefresh: _refreshData, // Callback to refresh data
            isLoading: isLoading,
            errorMessage: errorMessage,
          ),
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
  final ValueNotifier<int> pointsNotifier;
  final VoidCallback onPointsChanged;
  final Future<void> Function() onRefresh;
  final bool isLoading;
  final String errorMessage;

  const HomeScreen({
    Key? key,
    required this.subjectsFuture,
    this.firstName,
    this.initials,
    required this.pointsNotifier,
    required this.onPointsChanged,
    required this.onRefresh,
    required this.isLoading,
    required this.errorMessage,
  }) : super(key: key);

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      shrinkWrap: true,
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
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), // Ensure the scroll physics allows pull-to-refresh
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
                          'assets/panda.json',
                          repeat: true,
                          width: 110,
                        ),
                      ),
                    ),
                  ],
                ),
                ValueListenableBuilder<int>(
                  valueListenable: pointsNotifier,
                  builder: (context, points, child) {
                    return _buildStatSection(points);
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
        ).then((_) => onPointsChanged()); // Callback to update points after returning
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
        if (isLoading) {
          return SizedBox(
            height: MediaQuery.of(context).size.height - 200, // Adjust the height as needed
            child: _buildSkeletonLoader(),
          );
        } else if (snapshot.hasError) {
          return Center(child: Text(errorMessage));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No subjects available.'));
        } else {
          return ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildSubjectsList(snapshot.data!, context),
            ],
          );
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
            ).then((_) => onPointsChanged()); // Callback to update points after returning
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
                      fontSize: 18,
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
                      color: Colors.grey,
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