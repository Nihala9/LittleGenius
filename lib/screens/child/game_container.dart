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

  // --- NATIVE TRANSLATION ENGINE ---
  String _getLocalizedIntro(String conceptName, String mode, String lang) {
    if (lang == "Malayalam") {
      switch (mode) {
        case "Tracing": return "Namukku $conceptName varaykkan padikkam!"; 
        case "Matching": return "$conceptName, ithu cherupadippikkam!"; 
        case "AudioQuest": return "Sradhichu kelkkoo, $conceptName evideyanu?"; 
        case "Puzzle": return "Ithu onnu shariyaakkoo!"; 
        default: return "Namukku orumichu padikkam!";
      }
    } else if (lang == "Hindi") {
      switch (mode) {
        case "Tracing": return "Chalo, $conceptName likhna seekhte hain!"; 
        case "Matching": return "Sahi jodi milao!"; 
        case "AudioQuest": return "Sun kar batao, $conceptName kahan hai?"; 
        case "Puzzle": return "Is puzzle ko solve karo!"; 
        default: return "Chalo khelte hain!";
      }
    }
    return "Let's learn $conceptName with $mode!";
  }

  void _startActivity() async {
    String msg = _getLocalizedIntro(widget.concept.name, _currentActivity.activityMode, widget.child.language);
    // Tiny delay to ensure UI is ready
    Future.delayed(const Duration(milliseconds: 700), () async {
       await _voice.speak(msg, widget.child.language);
    });
  }

  // --- CORE COMPLETION LOGIC ---
  void _onActivityComplete(bool isCorrect) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (isCorrect) {
      await SoundService.playSFX('success.mp3');
      await Future.delayed(const Duration(milliseconds: 600)); // Prevent audio overlap
      _handleSuccess(user.uid);
    } else {
      await SoundService.playSFX('wrong.mp3');
      await Future.delayed(const Duration(milliseconds: 600));
      _localAttempts++;
      if (_localAttempts >= _adminLimit) _showRedirectionDialog();
      else _showRetryDialog();
    }
  }

  void _handleSuccess(String uid) async {
    // 1. Logic Calculations
    double currentMastery = widget.child.masteryScores[widget.concept.id] ?? 0.0;
    double newMastery = _aiLogic.calculateNewMastery(currentMastery, true);
    
    // 2. Database Updates
    await _db.updateMastery(uid, widget.child.id, widget.concept.id, newMastery);
    await _db.addStars(uid, widget.child.id, 10);

    // 3. Badge Unlock Check (If Mastery hits 80%)
    if (newMastery >= 0.8 && !widget.child.badges.contains(widget.concept.category)) {
      await _db.unlockBadge(uid, widget.child.id, widget.concept.category);
    }

    // 4. Celebration Sequence
    setState(() => _isCelebrating = true);
    _confettiController.play();
    
    String winMsg = _getLocalizedText("Superstar! You did it!", "Samarthan! Nannayi cheithu!", "Shabash! Bahut badhiya!");
    await _voice.speak(winMsg, widget.child.language);

    _showPopDialog(
      title: _getLocalizedText("AMAZING!", "Sammaanam!", "Shaandaar!"),
      message: _getLocalizedText("You earned 10 Stars!", "Ninnakku 10 nakshatrangal labhichu!", "Aapko 10 sitare mile!"),
      buttonText: _getLocalizedText("Finish Level", "Adutha Ghattam", "Agla Level"),
      lottieAsset: 'assets/animations/trophy.json', 
      iconColor: Colors.amber,
      onPressed: () { 
        Navigator.pop(context); // Close Popup
        Navigator.pop(context); // Return to Map
      }, 
    );
  }

  void _showRetryDialog() {
    _showPopDialog(
      title: _getLocalizedText("TRY AGAIN", "Sradhikkuka", "Koshish Karo"),
      message: _getLocalizedText("Give it one more try, buddy!", "Onnu koodi sramikkoo!", "Ek baar aur koshish karo!"),
      buttonText: _getLocalizedText("Retry", "Veendum", "Dobara"),
      icon: Icons.refresh_rounded,
      iconColor: AppColors.childOrange,
      onPressed: () { 
        Navigator.pop(context); 
        setState(() {}); // Rebuild activity locally
      },
    );
  }

  void _showRedirectionDialog() async {
    final plan = _aiLogic.getRedirectionPlan(_currentActivity.activityMode, 0.2);
    
    String speakMsg = _getLocalizedText("Let's try a new game!", "Puthiya kali kalikkam!", "Naya game khelte hain!");
    await _voice.speak(speakMsg, widget.child.language);

    _showPopDialog(
      title: _getLocalizedText("TRY THIS!", "Puthiya Kali!", "Ye Try Karo!"),
      message: plan['message'],
      buttonText: _getLocalizedText("Start!", "Thudangam", "Shuru Karein"),
      icon: Icons.auto_awesome_rounded,
      iconColor: AppColors.teal,
      onPressed: () { 
        Navigator.pop(context); 
        _switchActivityMode(plan['nextMode']); 
      },
    );
  }

  String _getLocalizedText(String en, String ml, String hi) {
    if (widget.child.language == "Malayalam") return ml;
    if (widget.child.language == "Hindi") return hi;
    return en;
  }

  void _switchActivityMode(String newMode) {
    setState(() {
      _localAttempts = 0;
      // Unique ID ensures ValueKey forces a full UI rebuild
      _currentActivity = Activity(
        id: 'redirect_${DateTime.now().millisecondsSinceEpoch}', 
        conceptId: widget.concept.id, 
        title: "", 
        activityMode: newMode, 
        language: widget.child.language, 
        difficulty: 1
      );
    });
    _startActivity();
  }

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
      context: context, barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lottieAsset != null) 
              Lottie.asset(lottieAsset, height: 150, errorBuilder: (c, e, s) => Icon(Icons.emoji_events, size: 80, color: iconColor)) 
            else 
              Icon(icon, size: 80, color: iconColor),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.childNavy)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.blueGrey)),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: iconColor, 
                minimumSize: const Size(200, 50), 
                shape: const StadiumBorder(),
                elevation: 5
              ),
              onPressed: onPressed, 
              child: Text(buttonText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          // THE GAME VIEW
          AbsorbPointer(
            absorbing: _isCelebrating, 
            child: Center(
              key: ValueKey(_currentActivity.id), // CRITICAL: Rebuilds on redirection
              child: _buildGameView()
            )
          ),

          // OVERLAYS
          Align(
            alignment: Alignment.topCenter, 
            child: ConfettiWidget(
              confettiController: _confettiController, 
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.yellow],
            )
          ),

          // HUD ELEMENTS
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
      case "Tracing": 
        return TracingActivity(
          targetLetter: widget.concept.name, 
          language: widget.child.language, 
          onComplete: _onActivityComplete
        );
      case "Matching": 
        return MatchingActivity(
          concept: widget.concept, 
          onComplete: _onActivityComplete
        );
      case "AudioQuest": 
        return AudioQuestActivity(
          concept: widget.concept, 
          language: widget.child.language, 
          onComplete: _onActivityComplete
        );
      case "Puzzle": 
        return PuzzleActivity(
          itemName: widget.concept.name, 
          onComplete: _onActivityComplete
        );
      default: 
        return const Center(child: CircularProgressIndicator());
    }
  }
}