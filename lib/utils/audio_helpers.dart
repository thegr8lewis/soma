import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

/// A helper class that provides robust audio playback capabilities 
/// with error handling and retry logic.
class AudioHelper {
  static AudioPlayer? _sharedPlayer;
  
  /// Play a sound asset with robust error handling
  /// Returns true if the sound was played successfully
  static Future<bool> playSound(String soundFile) async {
    try {
      // Initialize the player if needed
      _sharedPlayer ??= AudioPlayer();
      
      // Only play sound if app is active
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        try {
          // Set the source first
          await _sharedPlayer!.setSource(AssetSource(soundFile));
          await Future.delayed(const Duration(milliseconds: 100));
          
          // Then play the sound
          await _sharedPlayer!.resume();
          debugPrint('Sound played successfully: $soundFile');
          return true;
        } catch (e) {
          // If there was an error, try to reinitialize the player before playing
          debugPrint('Error playing sound, attempting to reinitialize: $e');
          
          // Create a new instance with error handling
          try {
            // Dispose old player
            await _sharedPlayer?.dispose();
            
            // Create a new one
            _sharedPlayer = AudioPlayer();
            await Future.delayed(const Duration(milliseconds: 300)); // Longer delay
            
            // Try again with the new player
            await _sharedPlayer!.setSource(AssetSource(soundFile));
            await Future.delayed(const Duration(milliseconds: 100));
            await _sharedPlayer!.resume();
            
            debugPrint('Sound played after reinitialization: $soundFile');
            return true;
          } catch (innerE) {
            debugPrint('Still failed to play sound after reinitialization: $innerE');
            return false;
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error in playSound method: $e');
      return false;
    }
  }
  
  /// Safely dispose the shared audio player
  static Future<void> dispose() async {
    try {
      await _sharedPlayer?.dispose();
      _sharedPlayer = null;
    } catch (e) {
      debugPrint('Error disposing audio player: $e');
    }
  }
}
