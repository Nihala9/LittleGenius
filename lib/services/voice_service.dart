import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class VoiceService {
  // Use a static player to prevent multiple instances from hanging the hardware
  static final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _systemTts = FlutterTts();
  
  // Queue to prevent concurrent voice calls that freeze the app
  static final List<Future<void>> _voiceQueue = [];
  static bool _isProcessingVoice = false;
  static DateTime? _lastVoiceCall;

  Future<void> initTTS() async {
    await _systemTts.setVolume(1.0);
    await _systemTts.setSpeechRate(0.4); 
    await _systemTts.setPitch(1.2); 
  }

  Future<void> speak(String text, String language) async {
    // Debounce: Prevent rapid successive calls within 200ms (common animation loops)
    if (_lastVoiceCall != null && DateTime.now().difference(_lastVoiceCall!).inMilliseconds < 200) {
      debugPrint("Voice: Debounced (animation loop detected)");
      return;
    }
    _lastVoiceCall = DateTime.now();

    // Add to queue to ensure only one voice call is active at a time
    final voiceTask = _executeSpeak(text, language);
    _voiceQueue.add(voiceTask);
    
    try {
      await voiceTask;
    } finally {
      _voiceQueue.remove(voiceTask);
    }
  }

  Future<void> _executeSpeak(String text, String language) async {
    // Wait if another voice call is in progress
    while (_isProcessingVoice) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    
    _isProcessingVoice = true;
    try {
      // 1. Immediately stop current audio to clear the native buffer
      await _audioPlayer.stop().timeout(const Duration(seconds: 1), onTimeout: () {
        debugPrint("Voice: Audio player stop timeout");
      });

      // 2. Try Online Voice (Download First logic)
      bool onlineSuccess = await _speakOnline(text, _getShortCode(language));
      
      // 3. Fallback to System TTS if Offline or Online fails
      if (!onlineSuccess) {
        debugPrint("Voice: Falling back to System TTS");
        await _speakOffline(text, _getLocaleCode(language));
      }
    } finally {
      _isProcessingVoice = false;
    }
  }

  Future<bool> _speakOnline(String text, String langCode) async {
    try {
      final String url = "https://translate.google.com/translate_tts?ie=UTF-8&q=${Uri.encodeComponent(text)}&tl=$langCode&client=tw-ob&ttsspeed=0.85";

      // FETCH BYTES WITH TIMEOUT - prevents hanging the app
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 5), onTimeout: () {
            throw TimeoutException("Voice HTTP request timeout");
          });

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        
        // Use a unique filename per session to avoid 'File in Use' crashes
        final String filePath = '${dir.path}/v_${DateTime.now().millisecondsSinceEpoch}.mp3';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        
        // --- FIX: Play from LOCAL FILE source with timeout ---
        // This is 100x faster than UrlSource and won't hang MIUI
        await _audioPlayer.play(DeviceFileSource(filePath))
            .timeout(const Duration(seconds: 3), onTimeout: () {
              debugPrint("Voice: Audio player timeout");
            });
        
        // Background cleanup: Delete old temp files
        _cleanupOldFiles(dir);
        
        return true; 
      }
      return false;
    } on TimeoutException catch (e) {
      debugPrint("Voice: Request timeout - $e");
      return false;
    } catch (e) {
      debugPrint("Online Voice Error: $e");
      return false;
    }
  }

  void _cleanupOldFiles(Directory dir) {
    dir.list().listen((file) {
      if (file.path.contains('v_') && file is File) {
        // Delete files older than 1 minute
        if (DateTime.now().difference(file.lastModifiedSync()).inMinutes > 1) {
          file.delete().catchError((_) => file);
        }
      }
    });
  }

  Future<void> _speakOffline(String text, String localeCode) async {
    try {
      await _systemTts.setLanguage(localeCode);
      await _systemTts.speak(text).timeout(const Duration(seconds: 5), onTimeout: () {
        debugPrint("Voice: System TTS timeout");
      });
    } catch (e) {
      debugPrint("System TTS Error: $e");
    }
  }

  String _getShortCode(String lang) => lang == 'Malayalam' ? 'ml' : (lang == 'Hindi' ? 'hi' : (lang == 'Arabic' ? 'ar' : 'en'));
  String _getLocaleCode(String lang) => lang == 'Malayalam' ? 'ml-IN' : (lang == 'Hindi' ? 'hi-IN' : (lang == 'Arabic' ? 'ar-SA' : 'en-US'));

  void stop() {
    _audioPlayer.stop();
    _systemTts.stop();
    _voiceQueue.clear();
    _isProcessingVoice = false;
    _lastVoiceCall = null;
  }
}