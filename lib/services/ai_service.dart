import 'dart:math';

class AIService {
  static const double pSlip = 0.1;  
  static const double pGuess = 0.2; 
  static const double pTransit = 0.1;

  // Bayesian Knowledge Tracing
  double calculateNewMastery(double currentMastery, bool isCorrect) {
    double pKnow;
    if (isCorrect) {
      pKnow = (currentMastery * (1 - pSlip)) / 
              (currentMastery * (1 - pSlip) + (1 - currentMastery) * pGuess);
    } else {
      pKnow = (currentMastery * pSlip) / 
              (currentMastery * pSlip + (1 - currentMastery) * (1 - pGuess));
    }
    return (pKnow + (1 - pKnow) * pTransit).clamp(0.0, 1.0);
  }

  // AI REDIRECTION LOGIC
  // Returns a "Redirection Plan" containing the next mode and a buddy message
  Map<String, dynamic> getRedirectionPlan(String currentMode, double masteryScore) {
    List<String> modes = ["Visual", "Auditory", "Kinesthetic"];
    modes.remove(currentMode); // Don't suggest the same mode they just failed
    
    String nextMode = modes[Random().nextInt(modes.length)];
    String message = "";

    switch (nextMode) {
      case "Visual":
        message = "Tracing is tricky! Let's watch how the letter is made first. Follow the magic eyes!";
        break;
      case "Auditory":
        message = "Let's take a break and listen to the sound this letter makes! Can you roar like the Lion?";
        break;
      default:
        message = "Let's try a different way to learn this together!";
    }

    return {
      "nextMode": nextMode,
      "message": message,
      "buddyAction": "think", // Used for Lottie animation selection
    };
  }
}