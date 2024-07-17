import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:system_auth/screens/authenticate/log_in.dart';
import 'package:system_auth/screens/home/home.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:system_auth/trialpages/apply.dart';

import '../../../config.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _name;
  String? _profileImageUrl;
  int? _grade;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _updateErrorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final sessionCookie = await _storage.read(key: 'session_cookie');
      final response = await http.get(
        Uri.parse('$BASE_URL/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': sessionCookie ?? '',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _name = data['username'];
          _profileImageUrl = data['profile_image_url'];
          _grade = data['grade'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage = 'Failed to load user data';
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
        _errorMessage = 'Error fetching user data';
      });
    }
  }

  Future<void> _updateProfile(String newName, int newGrade) async {
    final sessionCookie = await _storage.read(key: 'session_cookie');
    final response = await http.put(
      Uri.parse('$BASE_URL/update'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': sessionCookie ?? '',
      },
      body: jsonEncode(<String, dynamic>{
        'username': newName,
        'grade': newGrade,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        _name = newName;
        _grade = newGrade;
        _updateErrorMessage = '';
      });
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    } else {
      setState(() {
        _updateErrorMessage = 'Failed to update';
      });
    }
  }

  Future<void> _deleteProfile() async {
    final sessionCookie = await _storage.read(key: 'session_cookie');
    final response = await http.delete(
      Uri.parse('$BASE_URL/delete'),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': sessionCookie ?? '',
      },
    );

    if (response.statusCode == 200) {
      // Profile successfully deleted, navigate to home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LogIn()),
      );
    } else {
      setState(() {
        _updateErrorMessage = 'Failed to delete Profile';
      });
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Profile'),
          content: const Text('Are you sure you want to delete your profile? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteProfile();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateDialog() {
    final TextEditingController nameController = TextEditingController(text: _name);
    final TextEditingController gradeController = TextEditingController(text: _grade?.toString());
    bool isUpdating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Stack(
              children: [
                AlertDialog(
                  title: const Text(
                    'Update Your Details',
                    style: TextStyle(
                      // fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        onChanged: (value) {
                          setState(() {});
                        },
                        controller: nameController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline_outlined),
                          hintText: 'Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.grey,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        onChanged: (value) {
                          setState(() {});
                        },
                        controller: gradeController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.school),
                          hintText: 'GRADE',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.grey,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ),
                      if (_updateErrorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _updateErrorMessage,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                  actions: <Widget>[
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: nameController.text.isNotEmpty && gradeController.text.isNotEmpty && !isUpdating
                          ? () async {
                        setState(() {
                          isUpdating = true;
                        });
                        await _updateProfile(nameController.text, int.parse(gradeController.text));
                        setState(() {
                          isUpdating = false;
                        });
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isUpdating)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: LoadingAnimationWidget.staggeredDotsWave(
                        color: Colors.teal,
                        size: 100,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _logOut() async {
    await _storage.delete(key: 'session_cookie');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LogIn()),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F2),
      appBar: AppBar(
        backgroundColor: Colors.grey,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.black, // Change icon color to white
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Homepage()),
            );
          },
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black, // Change text color to white
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(0.0), // Adjust padding as needed
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  Container(
                    height: screenHeight * 0.3,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(50),
                        bottomRight: Radius.circular(50),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      Center(
                        child: CircleAvatar(
                          radius: screenWidth < 600 ? 70 : 90,
                          backgroundColor: Colors.grey.shade200,
                          child: _profileImageUrl != null
                              ? Text(
                            _name?.substring(0, 2).toUpperCase() ??
                                '',
                            style: TextStyle(
                              fontSize: screenWidth < 600 ? 30 : 40,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                              : const Icon(
                            Icons.face,
                            size: 80,
                            // size: screenWidth < 600 ? 60 : 80,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          _name ?? 'Loading...',
                          style: TextStyle(
                            fontSize: screenWidth < 600 ? 20 : 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              _grade != null ? 'Grade: $_grade' : 'Loading...',
                              style: TextStyle(
                                fontSize: screenWidth < 600 ? 15 : 20,
                                color: Colors.black,
                              ),
                            ),
                            if (_updateErrorMessage.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _updateErrorMessage,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: screenWidth < 600 ? 8 : 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth < 600 ? 10.0 : 20.0),
                    child: Text(
                      'Update Profile',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: screenWidth < 600 ? 20 : 25,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: 'Edit profile', // Tooltip message to display
                    child: IconButton(
                      icon: const SizedBox(
                        width: 27, // Specify the desired width
                        height: 27, // Specify the desired height
                        child: Icon(Icons.edit_note_rounded),
                      ),
                      onPressed: _showUpdateDialog,
                    ),
                  ),

                ],
              ),
              const SizedBox(height: 22),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth < 600 ? 10.0 : 20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _name ?? 'Name',
                              style: TextStyle(
                                fontSize: screenWidth < 600 ? 16 : 19,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.school),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _grade != null ? 'Grade: $_grade' : 'Grade',
                              style: TextStyle(
                                fontSize: screenWidth < 600 ? 16 : 19,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.help),
                        SizedBox(width: 8),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Help and information',
                              style: TextStyle(
                                fontSize: 16,
                                // fontSize: screenWidth < 600 ? 16 : 19,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.message),
                        SizedBox(width: 8),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Contact Us',
                              style: TextStyle(
                                fontSize: 16,
                                // fontSize: screenWidth < 600 ? 12 : 15,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenWidth < 600 ? 170 :330), // Adjust spacing for larger screens
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextButton(
                    onPressed: () {
                      _logOut();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Log Out',
                              style: TextStyle(
                                fontSize: screenWidth < 600 ? 16 : 19,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _showDeleteConfirmationDialog();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.delete_forever, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Delete Profile',
                              style: TextStyle(
                                fontSize: screenWidth < 600 ? 16 : 19,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


}
