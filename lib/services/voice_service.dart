import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class VoiceService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;

  Future<void> initTTS() async {
    if (_isInitialized) return;
    
    try {
      // Configuration for a "Gentle & Clear" tone
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.45); // Siri-like speed (not too fast, not too slow)
      await _tts.setPitch(1.1);      // Slightly higher for a friendly "Buddy" feel
      
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _tts.setEngine("com.google.android.tts"); // Use Google's high-quality engine
      }
      
      _isInitialized = true;
      debugPrint("AI Voice: Service Ready");
    } catch (e) {
      debugPrint("AI Voice Init Error: $e");
    }
  }

  // Helper to pick a high-quality voice for the specific language
  Future<void> _optimizeVoice(String langCode) async {
    try {
      List<dynamic> voices = await _tts.getVoices;
      
      // Try to find a "Natural" or "Siri" style voice in the list
      for (var voice in voices) {
        String name = voice["name"].toString().toLowerCase();
        if (voice["locale"].toString().contains(langCode)) {
          // On iOS, we look for 'premium' or 'siri'. On Android, 'network' or 'wavenet'.
          if (name.contains("premium") || name.contains("siri") || name.contains("wavenet")) {
            await _tts.setVoice({"name": voice["name"], "locale": voice["locale"]});
            break;
          }
        }
      }
    } catch (e) {
      debugPrint("Voice Optimization Error: $e");
    }
  }

  Future<void> speak(String text, String language) async {
    if (!_isInitialized) await initTTS();

    // --- LANGUAGE MAPPING ---
    String langCode = 'en-US';
    switch (language) {
      case 'Malayalam': langCode = 'ml-IN'; break;
      case 'Hindi':     langCode = 'hi-IN'; break;
      case 'Arabic':    langCode = 'ar-SA'; break; // Saudi Arabic
      case 'Spanish':   langCode = 'es-ES'; break;
      case 'French':    langCode = 'fr-FR'; break;
      default:          langCode = 'en-US';
    }

    await _tts.setLanguage(langCode);
    
    // Attempt to pick the clearest voice available on the device
    await _optimizeVoice(langCode);

    // Provide a small delay on Android to ensure engine binding
    if (Platform.isAndroid) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}