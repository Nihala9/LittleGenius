import '../models/child_model.dart';
import '../models/activity_model.dart';
import 'database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AIEngine {
  final _db = DatabaseService();

  // The pedagogical rotation sequence
  final List<String> _ladder = ['Tracing', 'Matching', 'AudioQuest', 'Puzzle', 'Scratch Card'];

  Future<Activity?> getPersonalizedActivity(ChildProfile child, String conceptId) async {
    try {
      // 1. Get all activities added by Admin for this concept
      List<Activity> all = await _db.streamActivitiesForConcept(conceptId).first;
      if (all.isEmpty) return null;

      final uid = FirebaseAuth.instance.currentUser?.uid;
      ChildProfile latest = await _db.getLatestChildProfile(uid!, child.id);
      
      String lastMode = latest.preferredMode;

      // --- CIRCULAR SHUFFLE LOGIC ---
      // Every time the kid clicks, we move to the NEXT mode in the ladder
      int currentIdx = _ladder.indexOf(lastMode);
      
      // Try to find the next available mode in the sequence
      for (int i = 1; i <= _ladder.length; i++) {
        String nextCandidate = _ladder[(currentIdx + i) % _ladder.length];
        
        // Check if Admin actually created this variant
        var matches = all.where((a) => a.activityMode == nextCandidate).toList();
        
        if (matches.isNotEmpty) {
          Activity nextActivity = matches.first;
          
          // Save the new mode so the next click shuffles again
          await _db.updatePreferredMode(child.id, nextActivity.activityMode);
          
          debugPrint("AI SHUFFLE: Rotated from $lastMode to ${nextActivity.activityMode}");
          return nextActivity;
        }
      }

      // Fallback: If only one mode exists, just return that
      return all.first;
    } catch (e) {
      return null;
    }
  }
}