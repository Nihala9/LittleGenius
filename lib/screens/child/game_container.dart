import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:animate_do/animate_do.dart';
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
import 'activities/scratch_reveal_activity.dart';
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
    required this.activity,
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
  late DateTime _levelStartTime;

  int _localAttempts = 0;
  int _adminLimit = 2;
  bool _isCelebrating = false;

  String _sessionKey = DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void initState() {
    super.initState();
    _levelStartTime = DateTime.now();
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
      setState(() {
        _adminLimit = config['redirectionLimit'] ?? 2;
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // --- NATIVE AI TUTOR HINT ---
  void _getSmartHint() {
    String lang = widget.child.language;
    String mode = _currentActivity.activityMode;
    String concept = widget.concept.name;
    String msg = "";

    if (lang == "Malayalam") {
      if (mode == "Tracing") {
        msg = "$concept വരയ്ക്കാൻ ശ്രമിക്കൂ, നിങ്ങൾക്ക് ഇത് ചെയ്യാൻ കഴിയും!";
      } else {
        msg = "ഒന്നുകൂടി ശ്രദ്ധിച്ചു നോക്കൂ!";
      }
    } else if (lang == "Hindi") {
      msg = "चिंता मत करो, एक बार फिर कोशिश करो। आप $concept को पहचान सकते हैं!";
    } else if (lang == "Arabic") {
      msg = "حاول مرة أخرى في $concept، أنت ذكي جداً!";
    } else {
      switch (mode) {
        case "Tracing":
          msg = "Try following the lines of $concept slowly.";
          break;
        case "Puzzle":
          msg = "Look for the missing piece of the $concept puzzle!";
          break;
        default:
          msg = "Look closely at $concept and try again!";
      }
    }

    _voice.speak(msg, lang);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.childBlue,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  void _startActivity() async {
    String lang = widget.child.language;
    String concept = widget.concept.name;
    String msg = (lang == "Malayalam") ? "നമുക്ക് $concept പഠിക്കാം!" : "Let's learn $concept!";
    Future.delayed(const Duration(milliseconds: 700), () {
      _voice.speak(msg, lang);
    });
  }

  void _onActivityComplete(bool isCorrect) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (isCorrect) {
      await SoundService.playSFX('success.mp3');
      _handleSuccess(user.uid);
    } else {
      await SoundService.playSFX('wrong.mp3');
      setState(() => _localAttempts++);
      if (_localAttempts >= _adminLimit) {
        _showRedirectionDialog();
      } else {
        _showRetryDialog();
      }
    }
  }

  // --- SUCCESS LOGIC: POINTS UNDER 100 ---
  void _handleSuccess(String uid) async {
    final secondsTaken = DateTime.now().difference(_levelStartTime).inSeconds;

    // Real score calculation (Max 100)
    // 100 points - (10 per mistake) - (1 per 4 seconds)
    int penalty = (_localAttempts * 10) + (secondsTaken ~/ 4);
    int finalScore = (100 - penalty).clamp(30, 100);

    double currentMastery = widget.child.masteryScores[widget.concept.id] ?? 0.0;
    double newMastery = _aiLogic.calculateNewMastery(currentMastery, true);

    await _db.updateMastery(uid, widget.child.id, widget.concept.id, newMastery, widget.child.name, widget.concept.category);
    await _db.addStars(uid, widget.child.id, 10);

    setState(() => _isCelebrating = true);
    _confettiController.play();

    int starCount = 3;
    if (finalScore < 60) {
      starCount = 1;
    } else if (finalScore < 85) {
      starCount = 2;
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => VictoryDialog(
          levelName: widget.concept.name,
          stars: starCount,
          score: finalScore,
          onNext: () {
            Navigator.pop(ctx);
            Navigator.pop(context);
          },
          onReplay: () {
            Navigator.pop(ctx);
            setState(() {
              _localAttempts = 0;
              _levelStartTime = DateTime.now();
              _isCelebrating = false;
              _sessionKey = DateTime.now().millisecondsSinceEpoch.toString();
            });
            _startActivity();
          },
        ),
      );
    }
  }

  void _showRedirectionDialog() {
    final plan = _aiLogic.getRedirectionPlan(_currentActivity.activityMode, 0.2);
    _showPopDialog(
      title: "TRY THIS!",
      message: plan['message'],
      buttonText: "Start!",
      icon: Icons.auto_awesome_rounded,
      iconColor: AppColors.teal,
      onPressed: () {
        Navigator.pop(context);
        _switchActivityMode(plan['nextMode']);
      },
    );
  }

  void _showRetryDialog() {
    _showPopDialog(
      title: "TRY AGAIN",
      message: "Give it one more try, buddy!",
      buttonText: "Retry",
      icon: Icons.refresh_rounded,
      iconColor: AppColors.childOrange,
      onPressed: () {
        Navigator.pop(context);
        setState(() {
          _sessionKey = DateTime.now().millisecondsSinceEpoch.toString();
        });
      },
    );
  }

  void _switchActivityMode(String newMode) {
    setState(() {
      _localAttempts = 0;
      _levelStartTime = DateTime.now();
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

  void _showPopDialog({
    required String title,
    required String message,
    required String buttonText,
    IconData? icon,
    String? lottieAsset,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lottieAsset != null) Lottie.asset(lottieAsset, height: 150) else Icon(icon, size: 80, color: iconColor),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.childNavy)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Colors.blueGrey)),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: iconColor, minimumSize: const Size(200, 50), shape: const StadiumBorder()),
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
              child: _buildGameView(),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
            ),
          ),
          Positioned(bottom: 20, left: 20, child: InteractiveBuddy(height: 100, language: widget.child.language)),
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: _getSmartHint,
              child: const CircleAvatar(
                backgroundColor: Colors.amber,
                child: Icon(Icons.lightbulb_outline, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, size: 35, color: Colors.grey),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameView() {
    String mode = _currentActivity.activityMode;
    bool isAlphaNum = widget.concept.category == "Alphabets" || widget.concept.category == "Numbers";

    if (mode == "Tracing" && !isAlphaNum) {
      return ScratchRevealActivity(
        itemName: widget.concept.name,
        imageUrl: _currentActivity.imageUrl,
        language: widget.child.language,
        onComplete: _onActivityComplete,
      );
    }

    switch (mode) {
      case "Tracing":
        return TracingActivity(targetLetter: widget.concept.name, language: widget.child.language, onComplete: _onActivityComplete);
      case "Matching":
        return MatchingActivity(concept: widget.concept, onComplete: _onActivityComplete);
      case "AudioQuest":
        return AudioQuestActivity(concept: widget.concept, language: widget.child.language, onComplete: _onActivityComplete);
      case "Puzzle":
        return PuzzleActivity(imageUrl: _currentActivity.imageUrl, itemName: widget.concept.name, onComplete: _onActivityComplete);
      case "Scratch Card":
        return ScratchRevealActivity(itemName: widget.concept.name, imageUrl: _currentActivity.imageUrl, language: widget.child.language, onComplete: _onActivityComplete);
      default:
        return const Center(child: CircularProgressIndicator());
    }
  }
}

// --- VICTORY DIALOG CLASS ---
class VictoryDialog extends StatelessWidget {
  final String levelName;
  final int stars;
  final int score;
  final VoidCallback onNext;
  final VoidCallback onReplay;

  const VictoryDialog({
    super.key,
    required this.levelName,
    required this.stars,
    required this.score,
    required this.onNext,
    required this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 95, 20, 30),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF9E7),
              borderRadius: BorderRadius.circular(45),
              border: Border.all(color: const Color(0xFFB07D4D), width: 10),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  levelName.toUpperCase(),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF7B5233)),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        bool isFilled = index < stars;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: BounceInDown(
                            delay: Duration(milliseconds: 200 * index),
                            child: Icon(
                              Icons.star_rounded,
                              size: index == 1 ? 90 : 70,
                              color: isFilled ? const Color(0xFFFFC107) : Colors.grey.shade300,
                              shadows: isFilled ? [const Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))] : [],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text("YOUR SCORE  ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF7B5233))),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: score.toDouble()),
                      duration: const Duration(seconds: 2),
                      builder: (context, value, child) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                        );
                      },
                    ),
                    const Text(" / 100", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 35),
                Row(
                  children: [
                    Expanded(child: _btn("REPLAY", const Color(0xFF3498DB), onReplay)),
                    const SizedBox(width: 15),
                    Expanded(child: _btn("NEXT", const Color(0xFF76D72F), onNext)),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: -35,
            child: ElasticInDown(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFF76D72F),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: const Text(
                  "COMPLETE",
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 65,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 5),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 6))],
        ),
        child: Center(
          child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
        ),
      ),
    );
  }
}