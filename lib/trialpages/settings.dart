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
import '../../../trialpages/notification.dart';

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

  void _showUpdateBottomSheet() {
    final TextEditingController nameController = TextEditingController(text: _name);
    final TextEditingController gradeController = TextEditingController(text: _grade?.toString());
    bool isUpdating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16.0,
                right: 16.0,
                top: 16.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Update Details',
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    child: TextField(
                      onChanged: (value) {
                        setState(() {});
                      },
                      controller: nameController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_outline_outlined),
                        hintText: 'Name',
                        hintStyle: GoogleFonts.poppins(),
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
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    child: TextField(
                      onChanged: (value) {
                        setState(() {});
                      },
                      controller: gradeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.school),
                        hintText: 'Grade',
                        hintStyle: GoogleFonts.poppins(),
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
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                  if (_updateErrorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _updateErrorMessage,
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 20),
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
                    child: Text(
                      'Update',
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showConfirmationBottomSheet(String actionType) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Confirm $actionType',
                style: GoogleFonts.poppins(
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Are you sure you want to $actionType your profile?',
                style: GoogleFonts.poppins(),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (actionType == 'delete') {
                        _deleteProfile();
                      } else if (actionType == 'logout') {
                        _logOut();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: actionType == 'delete' ? Colors.red : Colors.green,
                    ),
                    child: Text(
                      actionType == 'delete' ? 'Delete' : 'Log Out',
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF7F2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.black,
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Homepage()),
            );
          },
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            textStyle: const TextStyle(
              color: Colors.black,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(0.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0), // Add horizontal padding
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey.shade800,
                      child: _profileImageUrl != null
                          ? Text(
                        _name?.substring(0, 2).toUpperCase() ?? '',
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      )
                          : const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10), // Add some space between the CircleAvatar and the Text
                    Text(
                      _name ?? 'Loading...',
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              ListTile(
                leading: const Icon(Icons.email, color: Colors.grey),
                title: Text(
                  'Email',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
                subtitle: Text(
                  'XYZ@gmail.com',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.black,size: 20,),
                  onPressed: () {
                    _showUpdateBottomSheet();
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.school, color: Colors.grey),
                title: Text(
                  'Grade',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
                subtitle: Text(
                  _grade != null ? 'Grade: $_grade' : 'Loading...',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.black,size: 20,),
                  onPressed: () {
                    _showUpdateBottomSheet();
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.notifications, color: Colors.grey),
                title: Text(
                  'Notification',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.black,size: 20,),
                onTap: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationPage()));
                } ,
              ),
              ListTile(
                leading: const Icon(Icons.notifications, color: Colors.grey),
                title: Text(
                  'Coupons',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.black,size: 20,),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'FEEDBACK',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.bug_report, color: Colors.grey),
                title: Text(
                  'Report a bug',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.black,size: 20,),
              ),
              ListTile(
                leading: const Icon(Icons.feedback_rounded, color: Colors.grey),
                title: Text(
                  'Send feedback',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.black,size: 20,),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'SETTINGS',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.grey),
                title: Text(
                  'LogOut',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
                subtitle: Text(
                  'Delete your session',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
                onTap: () {
                  _showConfirmationBottomSheet('logout');
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.grey),
                title: Text(
                  'Delete account',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
                subtitle: Text(
                  'Permanently delete your account',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
                onTap: () {
                  _showConfirmationBottomSheet('delete');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
