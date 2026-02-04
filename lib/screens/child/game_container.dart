import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import '../../models/child_model.dart';
import '../../models/concept_model.dart';
import '../../models/activity_model.dart';
import '../../services/voice_service.dart';
import '../../services/ai_service.dart';
import '../../services/database_service.dart';
import '../../services/sound_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/interactive_buddy.dart';

// Activity Views
import 'activities/tracing_activity.dart';
import 'activities/matching_activity.dart';
import 'activities/audio_quest_activity.dart';
import 'activities/puzzle_activity.dart';

class GameContainer extends StatefulWidget {
  final ChildProfile child;
  final Concept concept;
  final Activity activity;

  const GameContainer({
    super.key, 
    required this.child, 
    required this.concept, 
    required this.activity
  });

  @override
  State<GameContainer> createState() => _GameContainerState();
}

class _GameContainerState extends State<GameContainer> {
  final _voice = VoiceService();
  final _aiLogic = AIService();
  final _db = DatabaseService();
  late ConfettiController _confettiController;
  
  late Activity _currentActivity;
  int _localAttempts = 0;
  int _adminLimit = 2; 
  bool _isCelebrating = false;

  @override
  void initState() {
    super.initState();
    _currentActivity = widget.activity;
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _loadAIConfig();
    _startActivity();
  }

  void _loadAIConfig() async {
    final config = await _db.getAIConfig();
    if (mounted) setState(() => _adminLimit = config['redirectionLimit'] ?? 2);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _startActivity() async {
    // Buddy explains the new task
    String msg = "Let's try ${_currentActivity.activityMode} mode with ${widget.concept.name}!";
    await _voice.speak(msg, widget.child.language);
  }

  // --- CORE LOGIC: SUCCESS OR FAIL ---
  void _onActivityComplete(bool isCorrect) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (isCorrect) {
      await SoundService.playSFX('success.mp3');
      await Future.delayed(const Duration(milliseconds: 500));
      _handleSuccess(user.uid);
    } else {
      await SoundService.playSFX('wrong.mp3');
      await Future.delayed(const Duration(milliseconds: 500));
      _localAttempts++;
      
      if (_localAttempts >= _adminLimit) {
        // TRIGGER AI REDIRECTION
        _showRedirectionDialog();
      } else {
        // TRIGGER RETRY
        _showRetryDialog();
      }
    }
  }

  void _handleSuccess(String uid) async {
    double currentMastery = widget.child.masteryScores[widget.concept.id] ?? 0.0;
    double newMastery = _aiLogic.calculateNewMastery(currentMastery, true);
    
    await _db.updateMastery(uid, widget.child.id, widget.concept.id, newMastery);
    await _db.addStars(uid, widget.child.id, 10);

    setState(() => _isCelebrating = true);
    _confettiController.play();
    await _voice.speak("Superstar! You are so smart!", widget.child.language);

    _showPopDialog(
      title: "AMAZING!",
      message: "You learned ${widget.concept.name}!",
      buttonText: "Finish Level",
      lottieAsset: 'assets/animations/trophy.json',
      iconColor: Colors.amber,
      onPressed: () {
        Navigator.pop(context); // Close Dialog
        Navigator.pop(context); // Go back to Map
      }, 
    );
  }

  void _showRetryDialog() {
    _voice.speak("Don't worry! Let's try one more time.", widget.child.language);

    _showPopDialog(
      title: "OOPS!",
      message: "Keep trying! You can do it!",
      buttonText: "Try Again",
      icon: Icons.refresh_rounded,
      iconColor: AppColors.childOrange,
      onPressed: () {
        Navigator.pop(context); // Close dialog
        setState(() {}); // Re-builds current activity
      },
    );
  }

  void _showRedirectionDialog() async {
    // Get a redirection plan from AI
    final plan = _aiLogic.getRedirectionPlan(_currentActivity.activityMode, 0.2);
    await _voice.speak(plan['message'], widget.child.language);

    _showPopDialog(
      title: "TRY THIS!",
      message: plan['message'],
      buttonText: "Let's Go!",
      icon: Icons.auto_awesome_rounded,
      iconColor: AppColors.teal,
      onPressed: () {
        Navigator.pop(context); // Close Dialog
        _switchActivityMode(plan['nextMode']); // Switch Mode Immediately
      },
    );
  }

  void _switchActivityMode(String newMode) {
    setState(() {
      _localAttempts = 0; // Reset counter for the new mode
      _currentActivity = Activity(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}', // Unique ID
        conceptId: widget.concept.id, 
        title: "", 
        activityMode: newMode, 
        language: widget.child.language, 
        difficulty: 1
      );
    });
    _startActivity();
  }

  // --- REUSABLE POPUP ---
  void _showPopDialog({
    required String title, 
    required String message, 
    required String buttonText, 
    IconData? icon, 
    String? lottieAsset, 
    required Color iconColor, 
    required VoidCallback onPressed
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            if (lottieAsset != null) 
              Lottie.asset(lottieAsset, height: 150) 
            else 
              Icon(icon, size: 80, color: iconColor),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.childNavy)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.blueGrey)),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: iconColor, minimumSize: const Size(200, 60), shape: const StadiumBorder(), elevation: 5),
              onPressed: onPressed,
              child: Text(buttonText, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // THE GAME VIEW (Wrapped in Key to ensure fresh reset on mode switch)
          AbsorbPointer(
            absorbing: _isCelebrating, 
            child: Center(
              key: ValueKey(_currentActivity.id), // CRITICAL: Forces reset when mode changes
              child: _buildGameView()
            )
          ),

          Align(
            alignment: Alignment.topCenter, 
            child: ConfettiWidget(
              confettiController: _confettiController, 
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.yellow],
            )
          ),

          Positioned(
            bottom: 20, 
            left: 20, 
            child: InteractiveBuddy(height: 100, language: widget.child.language)
          ),

          Positioned(
            top: 50, 
            right: 20, 
            child: IconButton(
              icon: const Icon(Icons.close_rounded, size: 35, color: Colors.grey), 
              onPressed: () => Navigator.pop(context)
            )
          ),
        ],
      ),
    );
  }

  Widget _buildGameView() {
    switch (_currentActivity.activityMode) {
      case "Tracing": return TracingActivity(targetLetter: widget.concept.name, onComplete: _onActivityComplete);
      case "Matching": return MatchingActivity(concept: widget.concept, onComplete: _onActivityComplete);
      case "AudioQuest": return AudioQuestActivity(concept: widget.concept, language: widget.child.language, onComplete: _onActivityComplete);
      case "Puzzle": return PuzzleActivity(itemName: widget.concept.name, onComplete: _onActivityComplete);
      default: return const Center(child: CircularProgressIndicator());
    }
  }
}