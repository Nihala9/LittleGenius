import 'dart:math';
import '../models/learning_log.dart';

class AIEngine {
  // BKT Parameters
  static const double pLearn = 0.4;
  static const double pGuess = 0.2;
  static const double pSlip = 0.1;

  /// Bayesian Knowledge Tracing (BKT) Calculation
  static double calculateNewMastery(double oldMastery, bool isSuccess) {
    double pKnown;
    if (isSuccess) {
      pKnown = (oldMastery * (1 - pSlip)) / 
               ((oldMastery * (1 - pSlip)) + ((1 - oldMastery) * pGuess));
    } else {
      pKnown = (oldMastery * pSlip) / 
               ((oldMastery * pSlip) + ((1 - oldMastery) * (1 - pGuess)));
    }
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

  /// MAB Recommendation: Pick a random mode from available styles (Fallback)
  static String decideNextMode(List<LearningLog> logs, String currentMode) {
    if (logs.length < 3) return currentMode;
    int failures = logs.where((log) => !log.isSuccess).length;
    if (failures >= 2) {
      List<String> allModes = ['Tracing', 'Matching', 'AudioQuest', 'Puzzle'];
      allModes.remove(currentMode);
      return allModes[Random().nextInt(allModes.length)];
    }
    return currentMode;
  }
}