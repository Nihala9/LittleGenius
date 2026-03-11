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
import 'activities/scratch_reveal_activity.dart';

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
  
  // Unique session key to force-reload the game UI on retry or redirect
  String _sessionKey = DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void initState() {
    super.initState();
    _currentActivity = widget.activity;
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _loadAIConfig();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startActivity();
    });
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

  // --- 1. NATIVE TUTOR: START GAME INSTRUCTIONS ---
  String _getLocalizedIntro(String conceptName, String mode, String lang) {
    String activeMode = mode;
    bool isAlphaNum = widget.concept.category == "Alphabets" || widget.concept.category == "Numbers";
    if (mode == "Tracing" && !isAlphaNum) activeMode = "Scratch Card";

    if (lang == "Malayalam") {
      switch (activeMode) {
        case "Tracing": return "നമുക്ക് $conceptName വരയ്ക്കാൻ പഠിക്കാം!"; 
        case "Matching": return "$conceptName യോജിപ്പിക്കാം!"; 
        case "AudioQuest": return "ശ്രദ്ധിച്ചു കേൾക്കൂ, $conceptName എവിടെയാണ്?"; 
        case "Puzzle": return "ഈ പസിൽ ഒന്ന് ശരിയാക്കൂ!"; 
        case "Scratch Card": return "ഈ മാന്ത്രിക പെട്ടി ഒന്ന് ഉരച്ചു നോക്കൂ!";
        default: return "നമുക്ക് ഒരുമിച്ച് പഠിക്കാം!";
      }
    } else if (lang == "Hindi") {
      switch (activeMode) {
        case "Tracing": return "चलो $conceptName लिखना सीखते हैं!"; 
        case "Matching": return "सही जोड़ी मिलाओ!"; 
        case "AudioQuest": return "सुन कर बताओ, $conceptName कहाँ है?"; 
        case "Puzzle": return "इस पहेली को हल करो!"; 
        case "Scratch Card": return "जादू देखने के लिए इसे खुरचें!";
        default: return "चलो साथ में सीखते हैं!";
      }
    } else if (lang == "Arabic") {
      switch (activeMode) {
        case "Tracing": return "لنقم برسم الحرف $conceptName!"; 
        case "Matching": return "هيا نصل الحروف المتشابهة!"; 
        case "AudioQuest": return "استمع جيداً، أين هو $conceptName؟"; 
        case "Puzzle": return "لنحل هذا اللغز معاً!"; 
        case "Scratch Card": return "امسح هذا المربع السحري!";
        default: return "لنبدأ التعلم معاً!";
      }
    }
    return "Let's learn $conceptName with $activeMode!";
  }

  void _startActivity() async {
    String msg = _getLocalizedIntro(widget.concept.name, _currentActivity.activityMode, widget.child.language);
    Future.delayed(const Duration(milliseconds: 700), () async {
       await _voice.speak(msg, widget.child.language);
    });
  }

  // --- 2. COMPLETION LOGIC (ROUTING) ---
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
      setState(() { _localAttempts++; });

      if (_localAttempts >= _adminLimit) {
        _showRedirectionDialog();
      } else {
        _showRetryDialog();
      }
    }
  }

  // --- 3. NATIVE TUTOR: FINAL REVISION & PRAISE ---
  Future<void> _announceFinalRevision() async {
    String lang = widget.child.language;
    String name = widget.concept.name;
    String msg = "";

    if (lang == "Malayalam") {
      msg = "മിടുക്കൻ! ഇത് $name ആണ്. നമുക്ക് ഒന്നുകൂടി പറയാം, $name!";
    } else if (lang == "Hindi") {
      msg = "बहुत अच्छे! यह $name है. एक बार फिर बोलिए, $name!";
    } else if (lang == "Arabic") {
      msg = "أحسنت! هذا هو $name. قلها مرة أخرى، $name!";
    } else {
      msg = "Great job! This is $name. Let's say it together, $name!";
    }

    await _voice.speak(msg, lang);
  }

  void _handleSuccess(String uid) async {
    double currentMastery = widget.child.masteryScores[widget.concept.id] ?? 0.0;
    double newMastery = _aiLogic.calculateNewMastery(currentMastery, true);
    
    // FIXED LINE 164: Added 'widget.child.name' and 'widget.concept.category'
    await _db.updateMastery(
      uid, 
      widget.child.id, 
      widget.concept.id, 
      newMastery, 
      widget.child.name, 
      widget.concept.category
    );
    
    await _db.addStars(uid, widget.child.id, 10);

    if (newMastery >= 0.8 && !widget.child.badges.contains(widget.concept.category)) {
      await _db.unlockBadge(uid, widget.child.id, widget.concept.category);
    }

    setState(() => _isCelebrating = true);
    _confettiController.play();
    
    // Announce concept for final revision
    await _announceFinalRevision();

    _showPopDialog(
      title: _getLocalizedText("AMAZING!", "സമ്മാനം!", "शानदार!", "مذهل!"),
      message: _getLocalizedText("You earned 10 Stars!", "നിനക്ക് 10 നക്ഷത്രങ്ങൾ ലഭിച്ചു!", "आपको 10 सितारे मिले!", "لقد حصلت على 10 نجوم!"),
      buttonText: _getLocalizedText("Finish", "പൂർത്തിയാക്കുക", "समाप्त", "إنهاء"),
      lottieAsset: 'assets/animations/trophy.json', 
      iconColor: Colors.amber,
      onPressed: () { Navigator.pop(context); Navigator.pop(context); }, 
    );
  }

  // --- 4. ERROR & REDIRECTION LOGIC ---

  void _showRetryDialog() {
    _showPopDialog(
      title: _getLocalizedText("TRY AGAIN", "ശ്രദ്ധിക്കുക", "कोशिश करो", "حاول ثانية"),
      message: _getLocalizedText("Give it one more try, buddy!", "ഒന്ന് കൂടി ശ്രമിക്കൂ!", "एक बार और कोशिश करो!", "حاول مرة أخرى!"),
      buttonText: _getLocalizedText("Retry", "വീണ്ടും", "दोबारा", "إعادة"),
      icon: Icons.refresh_rounded,
      iconColor: AppColors.childOrange,
      onPressed: () { 
        Navigator.pop(context); 
        setState(() { _sessionKey = DateTime.now().millisecondsSinceEpoch.toString(); }); 
      },
    );
  }

  void _showRedirectionDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    final plan = _aiLogic.getRedirectionPlan(_currentActivity.activityMode, 0.2);
    
    // --- NEW: Notify Parent immediately when Redirection starts ---
    if (user != null) {
      _db.logStruggleAlert(
        user.uid, 
        widget.child.id, 
        widget.child.name, 
        widget.concept.name, 
        widget.concept.category
      );
    }

    await _voice.speak(plan['message'], widget.child.language);

    _showPopDialog(
      title: _getLocalizedText("TRY THIS!", "പുതിയ കളി!", "ये ट्राई करो!", "جرب هذا!"),
      message: plan['message'],
      buttonText: _getLocalizedText("Start!", "തുടങ്ങാം", "शुरू करें", "ابدأ"),
      icon: Icons.auto_awesome_rounded,
      iconColor: AppColors.teal,
      onPressed: () { 
        Navigator.pop(context); 
        _switchActivityMode(plan['nextMode']); 
      },
    );
  }

  void _switchActivityMode(String newMode) {
    setState(() {
      _localAttempts = 0;
      _sessionKey = DateTime.now().millisecondsSinceEpoch.toString(); 
      _currentActivity = Activity(
        id: 'redirect_$_sessionKey', 
        conceptId: widget.concept.id, 
        title: "", 
        activityMode: newMode, 
        difficulty: 1,
        imageUrl: widget.activity.imageUrl, 
      );
    });
    _startActivity();
  }

  // --- HELPERS ---

  String _getLocalizedText(String en, String ml, String hi, String ar) {
    if (widget.child.language == "Malayalam") return ml;
    if (widget.child.language == "Hindi") return hi;
    if (widget.child.language == "Arabic") return ar;
    return en;
  }

  void _showPopDialog({required String title, required String message, required String buttonText, IconData? icon, String? lottieAsset, required Color iconColor, required VoidCallback onPressed}) {
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
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.childNavy)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Colors.blueGrey)),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: iconColor, minimumSize: const Size(200, 50), shape: const StadiumBorder(), elevation: 5),
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
              key: ValueKey(_sessionKey), 
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
    String mode = _currentActivity.activityMode;
    bool isAlphaNum = widget.concept.category == "Alphabets" || widget.concept.category == "Numbers";

    if (mode == "Tracing" && !isAlphaNum) {
      return ScratchRevealActivity(itemName: widget.concept.name, imageUrl: _currentActivity.imageUrl, language: widget.child.language, onComplete: _onActivityComplete);
    }

    switch (mode) {
      case "Tracing": return TracingActivity(targetLetter: widget.concept.name, language: widget.child.language, onComplete: _onActivityComplete);
      case "Matching": return MatchingActivity(concept: widget.concept, onComplete: _onActivityComplete);
      case "AudioQuest": return AudioQuestActivity(concept: widget.concept, language: widget.child.language, onComplete: _onActivityComplete);
      case "Puzzle": return PuzzleActivity(imageUrl: _currentActivity.imageUrl, itemName: widget.concept.name, onComplete: _onActivityComplete);
      case "Scratch Card": return ScratchRevealActivity(itemName: widget.concept.name, imageUrl: _currentActivity.imageUrl, language: widget.child.language, onComplete: _onActivityComplete);
      default: return const Center(child: CircularProgressIndicator());
    }
  }
}