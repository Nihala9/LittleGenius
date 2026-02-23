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
    if (mounted) {
      setState(() => _adminLimit = config['redirectionLimit'] ?? 2);
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // --- NATIVE TRANSLATION ENGINE (ACTUAL SCRIPTS) ---
  String _getLocalizedIntro(String conceptName, String mode, String lang) {
    if (lang == "Malayalam") {
      switch (mode) {
        case "Tracing": return "നമുക്ക് $conceptName വരയ്ക്കാൻ പഠിക്കാം!"; 
        case "Matching": return "$conceptName, ഇത് യോജിപ്പിക്കാം!"; 
        case "AudioQuest": return "ശ്രദ്ധിച്ചു കേൾക്കൂ, $conceptName എവിടെയാണ്?"; 
        case "Puzzle": return "ഇത് ഒന്ന് ശരിയാക്കൂ!"; 
        default: return "നമുക്ക് ഒരുമിച്ച് പഠിക്കാം!";
      }
    } else if (lang == "Hindi") {
      switch (mode) {
        case "Tracing": return "चलो $conceptName लिखना सीखते हैं!"; 
        case "Matching": return "सही जोड़ी मिलाओ!"; 
        case "AudioQuest": return "सुन कर बताओ, $conceptName कहाँ है?"; 
        case "Puzzle": return "इस पहेली को हल करो!"; 
        default: return "चलो साथ में सीखते हैं!";
      }
    } else if (lang == "Arabic") {
      switch (mode) {
        case "Tracing": return "لنقم برسم $conceptName!"; 
        case "Matching": return "قم بتوصيل $conceptName بشكل صحيح!"; 
        case "AudioQuest": return "استمع جيدا، أين هو $conceptName؟"; 
        case "Puzzle": return "قم بحل هذا اللغز!"; 
        default: return "لنلعب معا!";
      }
    }
    return "Let's learn $conceptName with $mode!";
  }

  void _startActivity() async {
    String msg = _getLocalizedIntro(widget.concept.name, _currentActivity.activityMode, widget.child.language);
    Future.delayed(const Duration(milliseconds: 700), () async {
       await _voice.speak(msg, widget.child.language);
    });
  }

  void _onActivityComplete(bool isCorrect) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (isCorrect) {
      await SoundService.playSFX('success.mp3');
      await Future.delayed(const Duration(milliseconds: 600)); 
      _handleSuccess(user.uid);
    } else {
      await SoundService.playSFX('wrong.mp3');
      await Future.delayed(const Duration(milliseconds: 600));
      _localAttempts++;
      // FIXED: Wrapped in curly braces to solve lint error
      if (_localAttempts >= _adminLimit) {
        _showRedirectionDialog();
      } else {
        _showRetryDialog();
      }
    }
  }

  void _handleSuccess(String uid) async {
    double currentMastery = widget.child.masteryScores[widget.concept.id] ?? 0.0;
    double newMastery = _aiLogic.calculateNewMastery(currentMastery, true);
    await _db.updateMastery(uid, widget.child.id, widget.concept.id, newMastery);
    await _db.addStars(uid, widget.child.id, 10);

    if (newMastery >= 0.8 && !widget.child.badges.contains(widget.concept.category)) {
      await _db.unlockBadge(uid, widget.child.id, widget.concept.category);
    }

    setState(() => _isCelebrating = true);
    _confettiController.play();
    
    String winMsg = _getLocalizedText("Superstar! You did it!", "സമർത്ഥൻ! നന്നായി ചെയ്തു!", "शाबाश! बहुत बढ़िया!");
    await _voice.speak(winMsg, widget.child.language);

    _showPopDialog(
      title: _getLocalizedText("AMAZING!", "സമ്മാനം!", "शानदार!"),
      message: _getLocalizedText("You earned 10 Stars!", "നിനക്ക് 10 നക്ഷത്രങ്ങൾ ലഭിച്ചു!", "आपको 10 सितारे मिले!"),
      buttonText: _getLocalizedText("Finish Level", "അടുത്ത ഘട്ടം", "अगला लेवल"),
      lottieAsset: 'assets/animations/trophy.json', 
      iconColor: Colors.amber,
      onPressed: () { 
        Navigator.pop(context); 
        Navigator.pop(context); 
      }, 
    );
  }

  void _showRetryDialog() {
    _showPopDialog(
      title: _getLocalizedText("TRY AGAIN", "ശ്രദ്ധിക്കുക", "कोशिश करो"),
      message: _getLocalizedText("Give it one more try, buddy!", "ഒന്ന് കൂടി ശ്രമിക്കൂ!", "एक बार और कोशिश करो!"),
      buttonText: _getLocalizedText("Retry", "വീണ്ടും", "दोबारा"),
      icon: Icons.refresh_rounded,
      iconColor: AppColors.childOrange,
      onPressed: () { 
        Navigator.pop(context); 
        setState(() {}); 
      },
    );
  }

  void _showRedirectionDialog() async {
    final plan = _aiLogic.getRedirectionPlan(_currentActivity.activityMode, 0.2);
    String speakMsg = _getLocalizedText("Let's try a new game!", "പുതിയ കളി കളിക്കാം!", "नया गेम खेलते हैं!");
    await _voice.speak(speakMsg, widget.child.language);

    _showPopDialog(
      title: _getLocalizedText("TRY THIS!", "പുതിയ കളി!", "ये ट्राई करो!"),
      message: _getLocalizedText("This might be more fun!", "ഇത് കൂടുതൽ രസമുള്ളതാണ്!", "ये ज्यादा मजेदार होगा!"),
      buttonText: _getLocalizedText("Start!", "തുടങ്ങാം", "शुरू करें"),
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
          AbsorbPointer(
            absorbing: _isCelebrating, 
            child: Center(
              key: ValueKey(_currentActivity.id), 
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