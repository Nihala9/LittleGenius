import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class VoiceService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;

  Future<void> initTTS() async {
    if (_isInitialized) return;
    
    try {
      // In version 4.2.5, we just set parameters. 
      // The engine initializes on the first call.
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.4); // Slower for kids
      await _tts.setPitch(1.2);      // "Buddy" feel pitch
      
      // On Android, calling getEngines ensures the platform channel is awake
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _tts.getEngines;
      }
      
      _isInitialized = true;
      debugPrint("AI Voice: TTS Service prepared.");
    } catch (e) {
      debugPrint("AI Voice Error: $e");
    }
  }

  Future<void> speak(String text, String language) async {
    if (!_isInitialized) await initTTS();

    String langCode = 'en-US';
    if (language == 'Malayalam') langCode = 'ml-IN';
    if (language == 'Hindi') langCode = 'hi-IN';
    if (language == 'Spanish') langCode = 'es-ES';
    if (language == 'French') langCode = 'fr-FR';

    await _tts.setLanguage(langCode);
    await _tts.speak(text);
  }
}