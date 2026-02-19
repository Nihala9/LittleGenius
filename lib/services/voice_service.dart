import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class VoiceService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _systemTts = FlutterTts();

  // Initialization for the offline backup
  Future<void> initTTS() async {
    await _systemTts.setVolume(1.0);
    await _systemTts.setSpeechRate(0.4); // Slower for kids
    await _systemTts.setPitch(1.2); 
  }

  Future<void> speak(String text, String language) async {
    // 1. Try High Quality Online Voice (Free Google Translate)
    // Uses SHORT CODE (e.g., 'hi')
    bool onlineSuccess = await _speakOnline(text, _getShortCode(language));
    
    // 2. If no internet, use System Fallback
    // Uses LOCALE CODE (e.g., 'hi-IN')
    if (!onlineSuccess) {
      debugPrint("Voice: Falling back to System TTS");
      await _speakOffline(text, _getLocaleCode(language));
    }
  }

  Future<bool> _speakOnline(String text, String langCode) async {
    try {
      final String url = "https://translate.google.com/translate_tts?ie=UTF-8&q=${Uri.encodeComponent(text)}&tl=$langCode&client=tw-ob";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/buddy_voice.mp3');
        await file.writeAsBytes(response.bodyBytes);
        await _audioPlayer.play(DeviceFileSource(file.path));
        return true; 
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _speakOffline(String text, String localeCode) async {
    bool isAvailable = await _systemTts.isLanguageAvailable(localeCode);
    if (isAvailable) {
      await _systemTts.setLanguage(localeCode);
      await _systemTts.speak(text);
    } else {
      // Fallback: Try generic code or English
      await _systemTts.setLanguage("en-US");
      await _systemTts.speak(text);
    }
  }

  // Google needs 'hi'
  String _getShortCode(String language) {
    if (language == 'Hindi') return 'hi';
    if (language == 'Malayalam') return 'ml';
    if (language == 'Arabic') return 'ar';
    return 'en';
  }

  // Android needs 'hi-IN'
  String _getLocaleCode(String language) {
    if (language == 'Hindi') return 'hi-IN';
    if (language == 'Malayalam') return 'ml-IN';
    if (language == 'Arabic') return 'ar-SA';
    return 'en-US';
  }

  void stop() {
    _audioPlayer.stop();
    _systemTts.stop();
  }
}