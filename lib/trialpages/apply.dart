import 'dart:io';
import 'dart:math';
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
      final authToken = await _storage.read(key: 'auth_token');
      if (authToken == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$BASE_URL/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
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
  }  Future<List<Subject>> _fetchSubjects() async {
    try {
      final authToken = await _storage.read(key: 'auth_token');
      if (authToken == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'Authentication token not found. Please log in again.';
        });
        throw Exception('No authentication token found. Please log in again.');
      }

      print('Fetching subjects with token: ${authToken.substring(0, min(10, authToken.length))}...');
      
      final response = await http.get(
        Uri.parse('$BASE_URL/subjects'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      print('Subjects API response code: ${response.statusCode}');
      print('Subjects API URL: $BASE_URL/subjects');
      
      if (response.statusCode == 200) {
        // Log the raw response first for debugging
        String rawResponse = response.body;
        print('Raw subjects response: $rawResponse');
        
        // Try to detect if the response is a JSON object rather than an array
        if (rawResponse.trim().startsWith('{')) {
          print('Response appears to be a JSON object, not an array');
          Map<String, dynamic> jsonObj = json.decode(rawResponse);
          _logResponseData('Parsed JSON object:', jsonObj);
          
          // Check if the object has a data field that contains the subjects array
          if (jsonObj.containsKey('data') && jsonObj['data'] is List) {
            print('Found subjects in the data field');
            List<dynamic> body = jsonObj['data'];
            return _processSubjectsList(body, authToken);
          } else if (jsonObj.containsKey('subjects') && jsonObj['subjects'] is List) {
            print('Found subjects in the subjects field');
            List<dynamic> body = jsonObj['subjects'];
            return _processSubjectsList(body, authToken);
          } else {
            // Look for any array in the response that might contain subjects
            for (var key in jsonObj.keys) {
              if (jsonObj[key] is List && (jsonObj[key] as List).isNotEmpty) {
                print('Found possible subjects array in field: $key');
                List<dynamic> body = jsonObj[key];
                return _processSubjectsList(body, authToken);
              }
            }
            
            // If we can't find a list, just convert the object to a single-item list
            print('No arrays found, treating the entire object as a single subject');
            return _processSubjectsList([jsonObj], authToken);
          }
        } else {
          // Regular array response
          try {
            List<dynamic> body = json.decode(rawResponse);
            return _processSubjectsList(body, authToken);
          } catch (e) {
            print('Failed to parse subjects as JSON array: $e');
            setState(() {
              isLoading = false;
              errorMessage = 'Failed to parse API response: $e';
            });
            return [];
          }
        }
      } else {
        handleHttpError(response.statusCode);
        return [];
      }
    } on SocketException catch (e) {
      print('Socket Exception: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'No Internet connection. Please check your network.';
      });
      throw Exception('No Internet connection. Please check your network.');
    } on HttpException catch (e) {
      print('HTTP Exception: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Could not find the requested resource.';
      });
      throw Exception('Could not find the requested resource.');
    } catch (e) {
      print('General Exception: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching subjects: $e';
      });
      print('Error fetching subjects: $e');
      return [];
    }
  }
  
  Future<List<Subject>> _processSubjectsList(List<dynamic> body, String authToken) async {
    _logResponseData('Processing subjects data:', body);
    
    if (body.isEmpty) {
      print('No subjects found in response');
      setState(() {
        isLoading = false;
      });
      return [];
    }
    
    List<Subject> subjects = [];
    for (var item in body) {
      try {
        if (item is Map<String, dynamic>) {
          Subject subject = Subject.fromJson(item);
          print('Successfully parsed subject: ${subject.name} (ID: ${subject.id})');
          subjects.add(subject);
        } else {
          print('Skipping non-map item in subjects array: $item');
        }
      } catch (e) {
        print('Error parsing subject: $e');
        print('Problem data: $item');
      }
    }
    
  // Fetch topic counts for each subject in parallel with better error handling
    await Future.wait(subjects.map((subject) async {
      try {
        // Use mongoId instead of numeric id for API calls
        String url = '$BASE_URL/${subject.mongoId}/topics';
        print('Fetching topics from: $url');
        
        final topicsResponse = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
        );

        print('Topics API response for subject ${subject.name} (ID: ${subject.mongoId}): ${topicsResponse.statusCode}');
        
        if (topicsResponse.statusCode == 200) {
          String rawResponse = topicsResponse.body;
          print('Raw topics response for subject ${subject.name} (first 100 chars): ${rawResponse.substring(0, min(100, rawResponse.length))}...');
          
          try {
            List<dynamic> topicsBody = json.decode(rawResponse);
            subject.topicCount = topicsBody.length;
            print('Subject ${subject.name} (ID: ${subject.mongoId}) has ${subject.topicCount} topics');
          } catch (e) {
            print('Error parsing topics response: $e');
            subject.topicCount = 0;
          }
        } else {
          print('Failed to load topics for subject ${subject.name} (ID: ${subject.mongoId}): Status ${topicsResponse.statusCode}');
          subject.topicCount = 0;
        }
      } catch (e) {
        print('Error fetching topics for subject ${subject.name} (ID: ${subject.mongoId}): $e');
        subject.topicCount = 0;
      }
    }));

    setState(() {
      isLoading = false;
    });
    
    print('Returning ${subjects.length} subjects');
    return subjects;
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

  // Function to debug response data
  void _logResponseData(String message, dynamic data) {
    print('DEBUG: $message');
    try {
      print(json.encode(data));
    } catch (e) {
      print('Could not encode data: $e');
      print('Raw data: $data');
    }
  }

  @override
  Widget build(BuildContext context) {    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
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
      ),      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            elevation: 10,
            backgroundColor: Colors.white,
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 0 
                        ? const Color(0xFF3F51B5).withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.home_rounded),
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 1 
                        ? const Color(0xFF3F51B5).withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_rounded),
                ),
                label: 'Profile',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: const Color(0xFF3F51B5),
            unselectedItemColor: Colors.black54,
            onTap: _onItemTapped,
          ),
        ),
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
    super.key,
    required this.subjectsFuture,
    this.firstName,
    this.initials,
    required this.pointsNotifier,
    required this.onPointsChanged,
    required this.onRefresh,
    required this.isLoading,
    required this.errorMessage,
  });
  Widget _buildSkeletonLoader() {
    // Define a list of colors for skeleton items
    final List<List<Color>> skeletonGradients = [
      [const Color(0xFFFF9800), const Color(0xFFFFB74D)], // Orange
      [const Color(0xFF9C27B0), const Color(0xFFBA68C8)], // Purple
      [const Color(0xFF2196F3), const Color(0xFF64B5F6)], // Blue
      [const Color(0xFFE91E63), const Color(0xFFF48FB1)], // Pink
    ];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: 8, // Number of skeleton cards to display
      itemBuilder: (context, index) {
        final gradientColors = skeletonGradients[index % skeletonGradients.length];
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                gradientColors[0].withOpacity(0.4),
                gradientColors[1].withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with icon placeholder
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonAnimation(
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SkeletonAnimation(
                      child: Container(
                        height: 24,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Subject name placeholder
                SkeletonAnimation(
                  child: Container(
                    height: 24,
                    width: MediaQuery.of(context).size.width * 0.3,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Description placeholder
                SkeletonAnimation(
                  child: Container(
                    height: 16,
                    width: MediaQuery.of(context).size.width * 0.25,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Button placeholder
                SkeletonAnimation(
                  child: Container(
                    height: 32,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
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
        child: Container(
          decoration: const BoxDecoration(
            // Create a colorful gradient background for kid appeal
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFEF9E7), // Light yellow at top
                Color(0xFFE8F8F5), // Light cyan in middle
                Color(0xFFD5F5E3), // Light green at bottom
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // Header with character animation
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '👋 Hi ${firstName ?? 'There'}!',
                                  style: GoogleFonts.fredoka(
                                    textStyle: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3F51B5), // Indigo color
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Ready to learn new things?',
                              style: GoogleFonts.fredoka(
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF8BC34A), // Light green
                                ),
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          child: Hero(
                            tag: 'mascot',
                            child: SizedBox(
                              child: Lottie.asset(
                                'assets/panda.json',
                                repeat: true,
                                width: 90,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Points card with animated elements
                  ValueListenableBuilder<int>(
                    valueListenable: pointsNotifier,
                    builder: (context, points, child) {
                      return _buildStatSection(points);
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildCourseSection(context),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Subjects'),
                  const SizedBox(height: 10),
                  _buildSubjectsSection(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatSection(int points) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2979FF), // Medium blue
            Color(0xFF448AFF), // Material blue
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2979FF).withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Progress',
                    style: GoogleFonts.fredoka(
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Points Earned',
                    style: GoogleFonts.fredoka(
                      textStyle: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/star.gif',
                      width: 30,
                      height: 30,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      points.toString(),
                      style: GoogleFonts.fredoka(
                        textStyle: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Add a fun animation of stars or confetti based on points
          SizedBox(
            height: 20,
            child: points > 0 
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    min(5, (points / 20).ceil()), // Show stars based on points
                    (index) => const Icon(Icons.star, color: Colors.amber, size: 20),
                  ),
                )
              : Container(),
          ),
        ],
      ),
    );
  }
  Widget _buildCourseSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Practice More'),
        const SizedBox(height: 10),
        _buildDailyQuizCard(context),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF673AB7).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        title,
        style: GoogleFonts.fredoka(
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF673AB7), // Deep purple
          ),
        ),
      ),
    );
  }

  Widget _buildDailyQuizCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DailyQuizScreen()),
        ).then((_) => onPointsChanged()); // Callback to update points after returning
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4CAF50), // Green
              Color(0xFF8BC34A), // Light green
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.quiz_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Daily Quiz',
                        style: GoogleFonts.fredoka(
                          textStyle: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Fun questions to boost your knowledge!',
                    style: GoogleFonts.fredoka(
                      textStyle: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Start Quiz',
                          style: GoogleFonts.fredoka(
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 90,
              child: Lottie.asset(
                'assets/books.json',
                repeat: true,
              ),
            ),
          ],
        ),
      ),
    );
  }Widget _buildSubjectsSection(BuildContext context) {
    return FutureBuilder<List<Subject>>(
      future: subjectsFuture,
      builder: (context, snapshot) {
        if (isLoading) {
          return SizedBox(
            height: MediaQuery.of(context).size.height - 200, // Adjust the height as needed
            child: _buildSkeletonLoader(),
          );
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          print('Error in FutureBuilder: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error loading subjects: ${snapshot.error.toString().substring(0, min(100, snapshot.error.toString().length))}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRefresh,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData) {
          return const Center(
            child: Text('No data available. Please try again.'),
          );
        } else if (snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/nosubjects.json',
                  width: 200,
                  height: 200,
                ),
                const Text(
                  'No subjects available for your grade.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRefresh,
                  child: const Text('Refresh'),
                ),
              ],
            ),
          );
        } else {
          print('Building subject list with ${snapshot.data!.length} subjects');
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
  }  Widget _buildSubjectsList(List<Subject> subjects, BuildContext context) {
    if (subjects.isEmpty) {
      return const Center(
        child: Text("No subjects available"),
      );
    }
    
    // Sort subjects by name
    subjects.sort((a, b) => a.name.compareTo(b.name));
    
    // Define subject colors list for variety
    final List<List<Color>> subjectGradients = [
      [const Color(0xFFFF9800), const Color(0xFFFFB74D)], // Orange
      [const Color(0xFF9C27B0), const Color(0xFFBA68C8)], // Purple
      [const Color(0xFF2196F3), const Color(0xFF64B5F6)], // Blue
      [const Color(0xFFE91E63), const Color(0xFFF48FB1)], // Pink
      [const Color(0xFF00BCD4), const Color(0xFF4DD0E1)], // Cyan
      [const Color(0xFF009688), const Color(0xFF4DB6AC)], // Teal
    ];
    
    // Generate subject icons for each subject
    final List<IconData> subjectIcons = [
      Icons.science_rounded,
      Icons.menu_book_rounded,
      Icons.calculate_rounded,
      Icons.language_rounded,
      Icons.history_edu_rounded,
      Icons.psychology_rounded,
    ];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index];
        final gradientColors = subjectGradients[index % subjectGradients.length];
        final iconData = subjectIcons[index % subjectIcons.length];
        
        // Debug print for each subject being rendered
        print('Rendering subject: ${subject.name} (ID: ${subject.id}) with ${subject.topicCount} topics');
        
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TopicsPage(
                  subjectId: subject.id,
                  subjectMongoId: subject.mongoId, // Pass the MongoDB ID
                  subjectName: subject.name,
                  subject_name: '',
                ),
              ),
            ).then((_) => onPointsChanged()); // Callback to update points after returning
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Subject content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row with icon
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              iconData,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${subject.topicCount} topics',
                              style: GoogleFonts.fredoka(
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Subject name
                      Text(
                        subject.name,
                        style: GoogleFonts.fredoka(
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subject.description != null && subject.description!.isNotEmpty)
                        Text(
                          subject.description!,
                          style: GoogleFonts.fredoka(
                            textStyle: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      // Start learning button
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Explore',
                              style: GoogleFonts.fredoka(
                                textStyle: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: gradientColors[0],
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: gradientColors[0],
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class Subject {
  final String name;  // Changed from nullable to non-nullable with defaults
  final String? description;
  final int id;       // For internal use
  final String mongoId; // Added to store the original MongoDB ID string
  final int grade;
  int topicCount;

  Subject({
    String? name,
    this.description, 
    required this.id, 
    required this.mongoId,
    required this.grade, 
    this.topicCount = 0
  }) : name = name ?? 'Subject $id';  // Default name if none provided

  factory Subject.fromJson(Map<String, dynamic> json) {
    // Debug the json data
    print('Parsing subject JSON: $json');
    
    // Store the original MongoDB ID as a string for API calls
    String mongoId = '';
    if (json.containsKey('id')) {
      if (json['id'] is String) {
        mongoId = json['id'];
      } else {
        print('Warning: MongoDB ID is not a string: ${json['id']}');
        mongoId = json['id'].toString();
      }
    } else {
      print('Warning: JSON missing "id" field');
      mongoId = '0';
    }
    
    // Generate a numeric ID for internal use
    int subjectId;
    if (json.containsKey('numeric_id')) {
      if (json['numeric_id'] is int) {
        subjectId = json['numeric_id'];
      } else if (json['numeric_id'] is String) {
        subjectId = int.tryParse(json['numeric_id']) ?? 0;
      } else {
        print('Warning: Subject ID has unexpected type: ${json['numeric_id']} (${json['numeric_id'].runtimeType})');
        subjectId = 0;
      }
    } else {
      // Use a simple hash of the MongoDB ID to get a numeric ID
      subjectId = mongoId.hashCode.abs();
      print('Generated internal ID $subjectId from MongoDB ID $mongoId');
    }
    
    // Handle different formats of grade (could be string, int, or missing)
    int gradeLevel;
    if (json.containsKey('grade')) {
      if (json['grade'] is String) {
        gradeLevel = int.tryParse(json['grade']) ?? 0;
      } else if (json['grade'] is int) {
        gradeLevel = json['grade'];
      } else {
        print('Warning: Grade has unexpected type: ${json['grade']} (${json['grade'].runtimeType})');
        gradeLevel = 0;
      }
    } else {
      print('Warning: JSON missing "grade" field');
      gradeLevel = 0;
    }
    
    // Handle subject name (could be string, other type, or missing)
    String? name;
    if (json.containsKey('name')) {
      if (json['name'] is String) {
        name = json['name'];
      } else {
        print('Warning: Subject name has unexpected type: ${json['name']} (${json['name'].runtimeType})');
        name = 'Subject $subjectId';
      }
    } else {
      print('Warning: JSON missing "name" field');
      name = 'Subject $subjectId';
    }
    
    // Handle description (could be string, other type, or missing)
    String? description;
    if (json.containsKey('description')) {
      if (json['description'] is String) {
        description = json['description'];
      } else if (json['description'] != null) {
        print('Warning: Description has unexpected type: ${json['description']} (${json['description'].runtimeType})');
        description = null;
      }
    }
    
    return Subject(
      name: name,
      description: description,
      id: subjectId,
      mongoId: mongoId,
      grade: gradeLevel,
      topicCount: 0, // Will be set later when we fetch topics
    );
  }
}