// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class MovieDetails extends StatelessWidget {
//   final Map<String, dynamic> movieData;

//   const MovieDetails({required this.movieData, Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           movieData['Title'],
//           style: GoogleFonts.poppins(
//             textStyle: const TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Image.network(movieData['Poster']),
//             const SizedBox(height: 10),
//             Text(
//               'Title: ${movieData['Title']}',
//               style: GoogleFonts.poppins(
//                 textStyle: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             Text(
//               'Year: ${movieData['Year']}',
//               style: GoogleFonts.poppins(
//                 textStyle: const TextStyle(
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//             Text(
//               'Rated: ${movieData['Rated']}',
//               style: GoogleFonts.poppins(
//                 textStyle: const TextStyle(
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//             Text(
//               'Released: ${movieData['Released']}',
//               style: GoogleFonts.poppins(
//                 textStyle: const TextStyle(
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//             Text(
//               'Runtime: ${movieData['Runtime']}',
//               style: GoogleFonts.poppins(
//                 textStyle: const TextStyle(
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//             Text(
//               'Genre: ${movieData['Genre']}',
//               style: GoogleFonts.poppins(
//                 textStyle: const TextStyle(
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//             Text(
//               'Director: ${movieData['Director']}',
//               style: GoogleFonts.poppins(
//                 textStyle: const TextStyle(
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//             Text(
//               'Writer: ${movieData['Writer']}',
//               style: GoogleFonts.poppins(
//                 textStyle: const TextStyle(
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//             Text(
//               'Actors: ${movieData['Actors']}',
//               style: GoogleFonts.poppins(
//                 textStyle: const TextStyle(
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//             Text(
//               'Plot: ${movieData['Plot']}',
//               style: GoogleFonts.poppins(
//                 textStyle: const TextStyle(
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//             Text(
//               'Language: ${movieData['Language']}',
//               style: GoogleFonts.poppins(
//                 textStyle: const TextStyle(
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//             Text(
//               'Country: ${movieData['Country']}',
//               style: GoogleFonts.poppins(
//                 textStyle: const TextStyle(
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//             Text(
//               'Awards: ${movieData['Awards']}',
//               style: GoogleFonts.poppins(
//                 textStyle: const TextStyle(
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               'Ratings:',
//               style: GoogleFonts.poppins(
//                 textStyle: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             ...movieData['Ratings'].map<Widget>((rating) {
//               return Text(
//                 '${rating['Source']}: ${rating['Value']}',
//                 style: GoogleFonts.poppins(
//                   textStyle: const TextStyle(
//                     fontSize: 16,
//                   ),
//                 ),
//               );
//             }).toList(),
//             const SizedBox(height: 10),
//             Text(
//               'Metascore: ${movieData['Metascore']}',
//               style: GoogleFonts.poppins(
//                 textStyle: const TextStyle(
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//             Text(
//               'IMDb Rating: ${movieData['imdbRating']}',
//               style: GoogleFonts.poppins(
//                 textStyle: const TextStyle(
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//             Text(
//               'IMDb Votes: ${movieData['imdbVotes']}',
//               style: GoogleFonts.poppins(
//                 textStyle: const TextStyle(
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//             Text(
//               'Box Office: ${movieData['BoxOffice']}',
//               style: GoogleFonts.poppins(
//                 textStyle: const TextStyle(
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
