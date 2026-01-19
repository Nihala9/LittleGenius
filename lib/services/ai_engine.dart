import 'dart:math';
import '../models/learning_log.dart';

class AIEngine {
  // --- DYNAMIC BKT PARAMETERS ---
  // These are no longer 'const' so the Admin can tune them globally
  static double pLearn = 0.4;
  static double pGuess = 0.2;
  static double pSlip = 0.1;

  /// ADMIN SYNC: Updates the global AI parameters from Firestore settings
  static void syncRules(Map<String, dynamic> rules) {
    pLearn = (rules['pLearn'] ?? 0.4).toDouble();
    pGuess = (rules['pGuess'] ?? 0.2).toDouble();
    pSlip = (rules['pSlip'] ?? 0.1).toDouble();
  }

  /// Bayesian Knowledge Tracing (BKT) Calculation
  /// Predicts the new mastery probability based on current success or failure
  static double calculateNewMastery(double oldMastery, bool isSuccess) {
    double pKnown;
    if (isSuccess) {
      // Probability they knew it given they succeeded
      pKnown = (oldMastery * (1 - pSlip)) / 
               ((oldMastery * (1 - pSlip)) + ((1 - oldMastery) * pGuess));
    } else {
      // Probability they knew it given they failed
      pKnown = (oldMastery * pSlip) / 
               ((oldMastery * pSlip) + ((1 - oldMastery) * (1 - pGuess)));
    }

    // Update mastery based on learning probability
    double newMastery = pKnown + (1 - pKnown) * pLearn;
    return newMastery.clamp(0.0, 1.0);
  }

  /// PERFORMANCE CHECK: Compare current mastery against the dynamic Concept threshold
  static bool hasMastered(double currentScore, double conceptThreshold) {
    return currentScore >= conceptThreshold;
  }

  /// REDIRECTION LOGIC: Check for consecutive failures based on Admin threshold
  static bool shouldRedirect(List<LearningLog> logs, int adminThreshold) {
    if (logs.length < adminThreshold) return false;
    
    // Check if the last 'N' attempts were all failures
    int consecutiveFailures = 0;
    for (var log in logs.reversed.take(adminThreshold)) {
      if (!log.isSuccess) {
        consecutiveFailures++;
      } else {
        break;
      }
    }
    return consecutiveFailures >= adminThreshold;
  }

  /// Multi-Armed Bandit (MAB) Recommendation
  /// Selects an alternative learning mode when the current one fails
  static String decideNextMode(List<LearningLog> logs, String currentMode) {
    // gathering data threshold
    if (logs.length < 3) return currentMode;

    int failures = logs.where((log) => !log.isSuccess).length;

    // Trigger redirection if general performance is low
    if (failures >= 2) {
      List<String> allModes = ['Tracing', 'Matching', 'Audio', 'Puzzle'];
      allModes.remove(currentMode);

      // Explore a different "Arm" (pedagogical style)
      return allModes[Random().nextInt(allModes.length)];
    }

    return currentMode;
  }
}