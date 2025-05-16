import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_auth/models/modelquestions.dart';

/// A helper class to cache questions data to reduce API calls
/// and improve offline availability of questions.
class QuestionsCacheHelper {
  static const String _cacheKeyPrefix = 'questions_cache_';
  static const Duration _cacheExpiry = Duration(days: 3); // Cache expiry period
  
  /// Saves a list of questions to local cache for a specific topic
  static Future<bool> cacheQuestions({
    required int topicId,
    required String topicName,
    required List<Question> questions,
  }) async {
    try {
      if (questions.isEmpty) {
        debugPrint('Not caching empty questions list');
        return false;
      }
      
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Convert questions to JSON
      final List<Map<String, dynamic>> questionsJson = 
          questions.map((q) => _questionToJson(q)).toList();
      
      // Create cache entry with metadata
      final Map<String, dynamic> cacheEntry = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'topicId': topicId,
        'topicName': topicName,
        'questionCount': questions.length,
        'questions': questionsJson,
      };
      
      // Save to cache with both ID and name keys for redundancy
      final String cacheString = json.encode(cacheEntry);
      await prefs.setString('${_cacheKeyPrefix}id_$topicId', cacheString);
      await prefs.setString('${_cacheKeyPrefix}name_${_normalizeName(topicName)}', cacheString);
      
      debugPrint('Cached ${questions.length} questions for topic $topicName (ID: $topicId)');
      return true;
    } catch (e) {
      debugPrint('Error caching questions: $e');
      return false;
    }
  }
  
  /// Retrieves cached questions for a topic if available and not expired
  static Future<List<Question>?> getCachedQuestions({
    required int topicId,
    required String topicName,
  }) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Try to get cache by ID first
      String? cacheString = prefs.getString('${_cacheKeyPrefix}id_$topicId');
      
      // If not found, try by name
      cacheString ??= prefs.getString('${_cacheKeyPrefix}name_${_normalizeName(topicName)}');
      
      if (cacheString == null) {
        debugPrint('No cache found for topic $topicName (ID: $topicId)');
        return null;
      }
      
      // Parse the cache entry
      final Map<String, dynamic> cacheEntry = json.decode(cacheString);
      
      // Check if cache is expired
      final int timestamp = cacheEntry['timestamp'] as int;
      final DateTime cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final DateTime now = DateTime.now();
      
      if (now.difference(cacheTime) > _cacheExpiry) {
        debugPrint('Cache expired for topic $topicName (ID: $topicId)');
        return null;
      }
      
      // Convert JSON to Question objects
      final List<dynamic> questionsJson = cacheEntry['questions'] as List<dynamic>;
      final List<Question> questions = questionsJson
          .map((q) => _jsonToQuestion(q as Map<String, dynamic>))
          .toList();
      
      debugPrint('Retrieved ${questions.length} cached questions for topic $topicName (ID: $topicId)');
      return questions;
    } catch (e) {
      debugPrint('Error retrieving cached questions: $e');
      return null;
    }
  }
  
  /// Clears the cache for a specific topic
  static Future<bool> clearTopicCache({
    required int topicId,
    required String topicName,
  }) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_cacheKeyPrefix}id_$topicId');
      await prefs.remove('${_cacheKeyPrefix}name_${_normalizeName(topicName)}');
      debugPrint('Cleared cache for topic $topicName (ID: $topicId)');
      return true;
    } catch (e) {
      debugPrint('Error clearing topic cache: $e');
      return false;
    }
  }
  
  /// Clears all cached questions
  static Future<bool> clearAllCache() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> keys = prefs.getKeys()
          .where((key) => key.startsWith(_cacheKeyPrefix))
          .toList();
      
      for (String key in keys) {
        await prefs.remove(key);
      }
      
      debugPrint('Cleared all questions cache (${keys.length} entries)');
      return true;
    } catch (e) {
      debugPrint('Error clearing all cache: $e');
      return false;
    }
  }
  
  // Helper methods
  static String _normalizeName(String name) {
    return name.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]'), '_');
  }
  
  static Map<String, dynamic> _questionToJson(Question question) {
    return {
      'id': question.id,
      'mongoId': question.mongoId,
      'grade': question.grade,
      'subject': question.subject,
      'topicId': question.topicId,
      'question': question.question,
      'imageUrl': question.imageUrl,
      'options': question.options,
      'correctAnswer': question.correctAnswer,
    };
  }
  
  static Question _jsonToQuestion(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as int? ?? 0,
      mongoId: json['mongoId'] as String? ?? '',
      grade: json['grade'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      topicId: json['topicId'] as int? ?? 0,
      question: json['question'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      options: Map<String, dynamic>.from(json['options'] as Map),
      correctAnswer: json['correctAnswer'] as String? ?? '',
    );
  }
}
