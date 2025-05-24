import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'dart:math';

class MotivationQuotesPage extends StatefulWidget {
  final VoidCallback? onContinue;

  const MotivationQuotesPage({super.key, this.onContinue});

  @override
  State<MotivationQuotesPage> createState() => _MotivationQuotesPageState();
}

class _MotivationQuotesPageState extends State<MotivationQuotesPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final Random _random = Random();
  late String _quote;
  late Color _backgroundColor;
  late Color _textColor;

  // List of engaging quotes for kids
  final List<String> _quotes = [
    "You're doing amazing! Keep going! 🌟",
    "Wow! You're so smart! Let's keep learning! 🎓",
    "You're a superstar student! 🌠",
    "Your brain is growing stronger with each question! 💪",
    "You're on fire today! 🔥",
    "Keep up the great work, you're getting smarter! 📚",
    "You're a learning champion! 🏆",
    "Each question makes you even more awesome! ✨",
    "I believe in you! You can do this! 🌈",
    "You make learning fun! Let's continue! 🎮",
    "Your curiosity is taking you to new heights! 🚀",
    "You're unstoppable! Let's keep going! 🏃‍♂️",
    "Learning is your superpower! ⚡",
    "You're a knowledge explorer! 🧭",
    "Every question brings you closer to becoming a genius! 🧠",
    "High five for your hard work! ✋",
    "You're making great progress! 🌱",
    "You're cracking these questions like a pro! 🥳",
    "Your effort is amazing! Keep shining! ☀️",
    "You're turning learning into an adventure! 🗺️"
  ];
  // List of animation assets that are verified to exist in the assets folder
  final List<String> _animations = [
    'assets/confetti.json', // Keep only animations we're sure exist
    'assets/jumps.json',
    'assets/panda.json',
    'assets/caterpillar.json',
  ];

  // Bright color pairs for kids (background, text)
  final List<List<Color>> _colorPairs = [
    [const Color(0xFFFFD700), Colors.black], // Gold
    [const Color(0xFF87CEEB), Colors.black], // Sky Blue
    [const Color(0xFFFF69B4), Colors.white], // Hot Pink
    [const Color(0xFF32CD32), Colors.white], // Lime Green
    [const Color(0xFFFFA500), Colors.black], // Orange
    [const Color(0xFF9370DB), Colors.white], // Medium Purple
    [const Color(0xFF00CED1), Colors.black], // Dark Turquoise
    [const Color(0xFFFF6347), Colors.white], // Tomato
    [const Color(0xFF7FFFD4), Colors.black], // Aquamarine
    [const Color(0xFFDDA0DD), Colors.black], // Plum
  ];

  // Safely get a random animation
  String get _randomAnimation {
    if (_animations.isEmpty) {
      return 'assets/confetti.json'; // Fallback animation
    }
    final index = _random.nextInt(_animations.length);
    return _animations[index];
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _animationController.forward();

    // Select a random quote and color pair
    _quote = _quotes[_random.nextInt(_quotes.length)];
    final colorPair = _colorPairs[_random.nextInt(_colorPairs.length)];
    _backgroundColor = colorPair[0];
    _textColor = colorPair[1];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_backgroundColor, _backgroundColor.withOpacity(0.7)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 200,
                width: 200,
                child: Builder(
                  builder: (context) {
                    try {
                      if (_randomAnimation.endsWith('.json')) {
                        return Lottie.asset(
                          _randomAnimation,
                          repeat: true,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('Error loading animation: $error');
                            return const Icon(Icons.star,
                                size: 100, color: Colors.amber);
                          },
                        );
                      } else {
                        return Image.asset(
                          _randomAnimation,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('Error loading image: $error');
                            return const Icon(Icons.emoji_events,
                                size: 100, color: Colors.amber);
                          },
                        );
                      }
                    } catch (e) {
                      debugPrint('Animation error: $e');
                      return const Icon(Icons.celebration,
                          size: 100, color: Colors.amber);
                    }
                  },
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "GREAT PROGRESS!",
                        style: GoogleFonts.poppins(
                          textStyle: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _backgroundColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _quote,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 50),
              // Remove the continue button - will auto-close after 4 seconds
            ],
          ),
        ),
      ),
    );
  }

  // Remove the _buildContinueButton method since we no longer need it
}
