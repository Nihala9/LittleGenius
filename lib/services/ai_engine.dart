import '../models/child_model.dart';
import '../models/activity_model.dart';
import 'database_service.dart';

class AIEngine {
  final _db = DatabaseService();

  Future<Activity?> getPersonalizedActivity(ChildProfile child, String conceptId) async {
    // 1. Fetch available activities for this concept
    List<Activity> allActivities = await _db.streamActivitiesForConcept(conceptId).first;
    
    // Filter by child's language
    List<Activity> localized = allActivities.where((a) => a.language == child.language).toList();
    
    if (localized.isEmpty) {
      print("AI DEBUG: No activities found for ${child.language}");
      return null;
    }

    double currentMastery = child.masteryScores[conceptId] ?? 0.0;
    String currentPreference = child.preferredMode;

    print("AI DEBUG: Child ${child.name} has Mastery: $currentMastery. Preferred Mode: $currentPreference");

    // 2. REDIRECTION LOGIC (The "Child 2" Logic)
    // If Mastery is low, we MUST find something different from the current preference
    if (currentMastery < 0.3 && localized.length > 1) {
      print("AI DEBUG: Mastery too low! Attempting Redirection...");

      try {
        // Find an activity where the mode is NOT the one they are currently failing
        Activity alternative = localized.firstWhere(
          (a) => a.activityMode.toLowerCase() != currentPreference.toLowerCase()
        );

        print("AI DEBUG: REDIRECTION SUCCESS! Switching to ${alternative.activityMode}");
        
        // Update the database so the AI remembers this new preference
        await _db.updatePreferredMode(child.id, alternative.activityMode);
        
        return alternative;
      } catch (e) {
        print("AI DEBUG: No alternative mode found in DB. Staying in $currentPreference");
      }
    }

    // 3. STABILITY LOGIC (The "Child 1" Logic)
    // Try to give the child their preferred mode if they are doing okay
    return localized.firstWhere(
      (a) => a.activityMode.toLowerCase() == currentPreference.toLowerCase(),
      orElse: () => localized.first,
    );
  }
}