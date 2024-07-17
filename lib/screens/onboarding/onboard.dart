// import 'package:flutter/material.dart';
//
// class OnboardingScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor:Color.fromRGBO(4, 133, 162, 1),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
//           child: Column(
//                   children: [
//                     ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         foregroundColor: Colors.white,
//                         backgroundColor: Color(0xFF3E81F3)
//                         ,
//                         padding: EdgeInsets.symmetric(horizontal: 64, vertical: 16),
//                         textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                         elevation: 5,
//                       ),
//                       onPressed: () {
//                         // Navigate to Login Screen
//                       },
//                       child: Text('Login'),
//                     ),
//                     SizedBox(height: 20),
//                     OutlinedButton(
//                       style: OutlinedButton.styleFrom(
//                         foregroundColor: Colors.white,
//                         side: BorderSide(color: Colors.white, width: 2),
//                         padding: EdgeInsets.symmetric(horizontal: 64, vertical: 16),
//                         textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                       ),
//                       onPressed: () {
//                         // Navigate to Signup Screen
//                       },
//                       child: Text('Sign Up'),
//                     ),
//                   ],
//                 ),
//               ),
//               Spacer(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }