import '../models/child_model.dart';
import '../models/activity_model.dart';
import 'database_service.dart';

class AIEngine {
  final _db = DatabaseService();

  // The Ladder: If Tracing (Hard) is too tough, move to Matching (Medium), then Audio (Easy)
  final List<String> _ladder = ['Tracing', 'Matching', 'AudioQuest'];

  Future<Activity?> getPersonalizedActivity(ChildProfile child, String conceptId) async {
    // 1. Get all activities available for this concept from Firebase
    List<Activity> all = await _db.streamActivitiesForConcept(conceptId).first;
    
    // 2. Filter by the child's language
    List<Activity> localized = all.where((a) => a.language == child.language).toList();
    if (localized.isEmpty) return null;

    double mastery = child.masteryScores[conceptId] ?? 0.0;
    String currentMode = child.preferredMode;

    // 3. AI LOGIC: If mastery is very low (< 30%), the current mode is too hard.
    if (mastery < 0.3 && localized.length > 1) {
      int idx = _ladder.indexOf(currentMode);
      
      // Step down the ladder to an easier mode
      String nextMode = (idx < _ladder.length - 1) ? _ladder[idx + 1] : _ladder[0];

      try {
        Activity alternative = localized.firstWhere((a) => a.activityMode == nextMode);
        // Automatically update child's preferred mode in DB for next time
        await _db.updatePreferredMode(child.id, alternative.activityMode);
        return alternative;
      } catch (e) {
        // Fallback to whatever is available
        return localized.first;
      }
    }

    // 4. Default: Return the activity that matches their preferred mode
    return localized.firstWhere(
      (a) => a.activityMode == currentMode, 
      orElse: () => localized.first
    );
  }
}