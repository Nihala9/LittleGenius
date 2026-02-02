import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/child_model.dart';
import '../../models/concept_model.dart';
import '../../models/activity_model.dart';
import '../../services/voice_service.dart';
import '../../services/ai_service.dart';
import '../../services/database_service.dart';
import '../../widgets/interactive_buddy.dart'; // Import interactive buddy

// Activity Views
import 'activities/tracing_activity.dart';
import 'activities/matching_activity.dart';
import 'activities/audio_quest_activity.dart';

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
  final VoiceService _voice = VoiceService();
  final AIService _aiLogic = AIService();
  final DatabaseService _db = DatabaseService();
  late ConfettiController _confettiController;
  
  late Activity _currentActivity;
  int _attempts = 0;
  bool _isCelebrating = false;

  @override
  void initState() {
    super.initState();
    _currentActivity = widget.activity;
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _startActivity();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _startActivity() async {
    String intro = "Let's learn ${widget.concept.name}!";
    await _voice.speak(intro, widget.child.language);
  }

  void _onActivityComplete(bool isCorrect) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (isCorrect) {
      double currentMastery = widget.child.masteryScores[widget.concept.id] ?? 0.0;
      double newMastery = _aiLogic.calculateNewMastery(currentMastery, true);
      
      await _db.updateMastery(user.uid, widget.child.id, widget.concept.id, newMastery);
      await _db.addStars(user.uid, widget.child.id, 10);

      if (newMastery >= 0.8 && !widget.child.badges.contains(widget.concept.category)) {
        await _db.unlockBadge(user.uid, widget.child.id, widget.concept.category);
      }

      _showCelebration();
    } else {
      setState(() => _attempts++);
      if (_attempts >= 3) _handleRedirection();
      else await _voice.speak("Try one more time!", widget.child.language);
    }
  }

  void _handleRedirection() async {
    final plan = _aiLogic.getRedirectionPlan(_currentActivity.activityMode, 0.2);
    await _voice.speak(plan['message'], widget.child.language);

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InteractiveBuddy(height: 120, language: widget.child.language),
            const SizedBox(height: 20),
            Text(plan['message'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () { Navigator.pop(c); _switchActivityMode(plan['nextMode']); },
              child: const Text("Okay!"),
            ),
          )
        ],
      ),
    );
  }

  void _switchActivityMode(String newMode) {
    setState(() {
      _attempts = 0;
      _currentActivity = Activity(id: 'temp', conceptId: widget.concept.id, title: "", activityMode: newMode, language: widget.child.language, difficulty: 1);
    });
    _startActivity();
  }

  void _showCelebration() async {
    setState(() => _isCelebrating = true);
    _confettiController.play();
    await _voice.speak("Superstar!", widget.child.language);
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          AbsorbPointer(absorbing: _isCelebrating, child: Center(child: _buildGameView())),
          Align(alignment: Alignment.topCenter, child: ConfettiWidget(confettiController: _confettiController, blastDirectionality: BlastDirectionality.explosive)),
          
          // HUD Buddy (Interactive)
          Positioned(bottom: 20, left: 20, child: InteractiveBuddy(height: 100, language: widget.child.language)),
          
          Positioned(top: 50, right: 20, child: IconButton(icon: const Icon(Icons.close, size: 30), onPressed: () => Navigator.pop(context))),
        ],
      ),
    );
  }

  Widget _buildGameView() {
    switch (_currentActivity.activityMode) {
      case "Tracing": return TracingActivity(targetLetter: widget.concept.name, onComplete: _onActivityComplete);
      case "Matching": return MatchingActivity(concept: widget.concept, onComplete: _onActivityComplete);
      case "AudioQuest": return AudioQuestActivity(concept: widget.concept, language: widget.child.language, onComplete: _onActivityComplete);
      default: return const Text("Loading...");
    }
  }
}