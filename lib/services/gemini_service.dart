import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final String _apiKey = "AIzaSyAb_yUtnc3M5_7eL5UAruT3UdDm4ZIuwfc";
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
  }

  // 1. GENERATE PARENT REPORT
  Future<String> getAIReport(String name, Map<String, double> scores, String lang) async {
    final prompt = """
    You are an expert preschool AI Tutor. Analyze these mastery scores for a student named $name: $scores.
    Identify their biggest strength and one specific area to improve. 
    Write a 2-sentence encouraging note to the parent in $lang. 
    Use the native script of $lang. Do not use complex words.
    """;
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? "Analysis pending...";
    } catch (e) {
      return "The AI Tutor is resting. Please check back later!";
    }
  }

  // 2. GENERATE AI STORY
  Future<String> generateStory(String name, String concept, String lang) async {
    final prompt = """
    Write a 4-sentence bedtime story for a 3-year-old named $name about a $concept.
    The story must be in $lang using native script.
    Make it very happy and simple. 
    End with 'Goodnight $name!'.
    """;
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? "Once upon a time...";
    } catch (e) {
      return "The library is closed for a moment.";
    }
  }

  // 3. GENERATE CONVERSATIONAL HINTS
  Future<String> getDynamicHint(String concept, String mode, String lang) async {
    final prompt = """
    A child is struggling to do a $mode activity for the concept '$concept'.
    As a friendly bird buddy, give a 1-sentence helpful hint in $lang (native script).
    Example: 'The letter A looks like a tiny mountain!'. 
    Make it imaginative and encouraging.
    """;
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? "You can do it, buddy!";
    } catch (e) {
      return "Let's try together!";
    }
  }
}