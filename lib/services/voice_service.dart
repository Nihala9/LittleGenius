import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  final FlutterTts _tts = FlutterTts();

  // Set up the voice parameters
  Future<void> initTTS() async {
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.4); // Slower for kids
    await _tts.setPitch(1.2);      // Slightly higher pitch for a "Buddy" feel
  }

  // Speak function with language support
  Future<void> speak(String text, String languageCode) async {
    // Mapping our languages to TTS codes
    String code = 'en-US';
    if (languageCode == 'Malayalam') code = 'ml-IN';
    if (languageCode == 'Hindi') code = 'hi-IN';
    if (languageCode == 'Spanish') code = 'es-ES';
    if (languageCode == 'French') code = 'fr-FR';

    await _tts.setLanguage(code);
    await _tts.speak(text);
  }
}


