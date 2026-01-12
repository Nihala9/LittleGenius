import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  final FlutterTts _tts = FlutterTts();

  // Basic Greeting/Instruction
  Future<void> speakGreeting(String message, String languageCode) async {
    await _tts.setLanguage(languageCode);
    await _tts.setPitch(1.2);
    await _tts.speak(message);
  }

  // Praise logic for "Dopamine Hits" (replaces addictive shorts/reels)
  Future<void> speakPraise(String languageCode) async {
    await _tts.setLanguage(languageCode);
    
    List<String> messages = [];
    if (languageCode == 'ml-IN') {
      messages = ["അത്യുഗ്രം!", "മിടുക്കൻ!", "നീ ജയിച്ചു!", "കൊള്ളാം!"]; 
    } else if (languageCode == 'hi-IN') {
      messages = ["बहुत बढ़िया!", "शानदार!", "तुम जीत गए!", "अद्भुत!"];
    } else {
      messages = ["Great job!", "You're a superstar!", "Amazing!", "You did it!"];
    }

    // Pick a message based on the current second to keep it random
    String randomPraise = messages[DateTime.now().second % messages.length];
    await _tts.speak(randomPraise);
  }

  // Encouraging message when AI switches game style
  Future<void> speakRedirection(String languageCode) async {
    await _tts.setLanguage(languageCode);
    String msg = languageCode == 'ml-IN' 
        ? "നമുക്ക് മറ്റൊരു രീതിയിൽ പഠിക്കാം!" 
        : "Let's try a different fun way!";
    await _tts.speak(msg);
  }
}