import 'dart:math';

class AIService {
  // --- BKT Constants (Typical values for early learners) ---
  static const double pSlip = 0.1;  // Chance child knows it but clicks wrong
  static const double pGuess = 0.2; // Chance child doesn't know it but clicks right
  static const double pTransit = 0.1; // Chance child learns from this attempt

  // Bayesian Knowledge Tracing: Calculates new Mastery Probability
  double calculateNewMastery(double currentMastery, bool isCorrect) {
    double pKnow;
    
    if (isCorrect) {
      pKnow = (currentMastery * (1 - pSlip)) / 
              (currentMastery * (1 - pSlip) + (1 - currentMastery) * pGuess);
    } else {
      pKnow = (currentMastery * pSlip) / 
              (currentMastery * pSlip + (1 - currentMastery) * (1 - pGuess));
    }

    // Add probability of learning during the transition
    return pKnow + (1 - pKnow) * pTransit;
  }

  // Multi-Armed Bandit: Recommends the next Activity Mode
  String getRecommendedMode(String currentMode, double masteryScore) {
    List<String> modes = ["Visual", "Auditory", "Kinesthetic"];
    
    // If mastery is low (< 40%), "Explore" a new mode
    if (masteryScore < 0.4) {
      modes.remove(currentMode);
      return modes[Random().nextInt(modes.length)];
    }
    
    // Otherwise, keep using the current successful mode
    return currentMode;
  }
}