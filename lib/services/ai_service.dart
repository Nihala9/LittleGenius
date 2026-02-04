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
    // These MUST match the cases in your GameContainer switch exactly
    List<String> availableModes = ["Tracing", "Matching", "AudioQuest", "Puzzle"];
    
    // Remove the one they are currently failing
    availableModes.remove(currentMode); 
    
    // Pick a new one randomly
    String nextMode = availableModes[Random().nextInt(availableModes.length)];
    String message = "";

    switch (nextMode) {
      case "Tracing":
        message = "You're doing great! Let's try drawing the letter now.";
        break;
      case "Matching":
        message = "Tracing is tricky! Let's try matching the pictures instead. It's fun!";
        break;
      case "AudioQuest":
        message = "Let's take a break and listen to some sounds! Can you find the right one?";
        break;
      case "Puzzle":
        message = "Let's try to fix a picture puzzle together! You're good at puzzles.";
        break;
      default:
        message = "Let's try a different way to learn this together!";
    }

    return {
      "nextMode": nextMode,
      "message": message,
    };
  }
}