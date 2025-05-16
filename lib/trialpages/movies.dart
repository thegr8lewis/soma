import 'package:flutter/material.dart';

class MovieDetailsPage extends StatelessWidget {
  final Map<String, dynamic> movieData;

  const MovieDetailsPage({super.key, required this.movieData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(movieData['original_title']),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                'https://image.tmdb.org/t/p/w500${movieData['poster_path']}',
                height: 300,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Overview',
                
              ),
              const SizedBox(height: 8.0),
              Text(movieData['overview']),
              const SizedBox(height: 16.0),
              const Text(
                'Release Date',
                
              ),
              const SizedBox(height: 8.0),
              Text(movieData['release_date']),
              const SizedBox(height: 16.0),
              const Text(
                'Vote Average',
                
              ),
              const SizedBox(height: 8.0),
              Text('${movieData['vote_average']} / 10'),
              const SizedBox(height: 16.0),
              const Text(
                'Vote Count',
                
              ),
              const SizedBox(height: 8.0),
              Text(movieData['vote_count'].toString()),
            ],
          ),
        ),
      ),
    );
  }
}
