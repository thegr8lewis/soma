// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:lottie/lottie.dart';
// import 'package:system_auth/config.dart';
// import 'package:system_auth/screens/home/topics.dart';
// import 'package:system_auth/screens/home/profile/userprofile.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'SOMA APP',
//       home: const HomePage(),
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//     );
//   }
// }

// class HomePage extends StatefulWidget {
//   const HomePage({Key? key}) : super(key: key);

//   @override
//   _HomePageState createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   late Future<List<Subject>> _subjectsFuture;
//   final FlutterSecureStorage _storage = const FlutterSecureStorage();

//   @override
//   void initState() {
//     super.initState();
//     _subjectsFuture = _fetchSubjects();
//   }

//   Future<List<Subject>> _fetchSubjects() async {
//     try {
//       final sessionCookie = await _storage.read(key: 'session_cookie');
//       if (sessionCookie == null) {
//         throw Exception('No session cookie found');
//       }

//       final response = await http.get(
//         Uri.parse('$BASE_URL/subjects'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Cookie': sessionCookie,
//         },
//       );

//       if (response.statusCode == 200) {
//         List<dynamic> body = json.decode(response.body);
//         return body.map((dynamic item) => Subject.fromJson(item)).toList();
//       } else {
//         throw Exception('Failed to load subjects. Status code: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Error fetching subjects: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         title: const Text('SOMA APP'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.person),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => const ProfilePage(),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           _buildLoadingView(), // Always show the Lottie animation at the top
//           Expanded(
//             child: FutureBuilder<List<Subject>>(
//               future: _subjectsFuture,
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return Container(); // Do not show anything if waiting
//                 } else if (snapshot.hasError) {
//                   WidgetsBinding.instance.addPostFrameCallback((_) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('Error: ${snapshot.error}')),
//                     );
//                   });
//                   return _buildErrorView();
//                 } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                   return const Center(child: Text('No subjects available.'));
//                 } else {
//                   return _buildSubjectsList(snapshot.data!);
//                 }
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLoadingView() {
//     return Container(
//       height: 220, // Adjust height to fit the animation and text
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.only(left: 16.0), // Adjust the padding to your needs
//             child: Lottie.network(
//               'https://lottie.host/87997b7c-46c7-4168-a524-c25961818aa7/wOv6KaTfF0.json',
//               height: 150,
//             ),
//           ),
//           const SizedBox(width: 20),
//         ],
//       ),
//     );
//   }

//   Widget _buildErrorView() {
//     return const Center(child: Text('An error occurred. Please try again.'));
//   }

//   Widget _buildSubjectsList(List<Subject> subjects) {
//     return ListView.builder(
//       itemCount: subjects.length,
//       itemBuilder: (context, index) {
//         var subject = subjects[index];
//         return Padding(
//           padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
//           child: Card(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10.0),
//             ),
//             elevation: 2,
//             child: ListTile(
//               title: Text(
//                 subject.name,
//                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               subtitle: LinearProgressIndicator(
//                 value: subject.grade / 100, // Adjust according to your grade data
//                 backgroundColor: Colors.grey[200],
//                 valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
//               ),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => TopicsPage(
//                       subjectId: subject.id,
//                       subjectName: subject.name,
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// class Subject {
//   final int id;
//   final String name;
//   final int grade;

//   Subject({required this.id, required this.name, required this.grade});

//   factory Subject.fromJson(Map<String, dynamic> json) {
//     return Subject(
//       id: json['id'],
//       name: json['name'],
//       grade: json['grade'],
//     );
//   }
// }