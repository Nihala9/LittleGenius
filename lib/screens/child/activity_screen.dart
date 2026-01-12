import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import '../../models/child_profile.dart';
import '../../models/learning_log.dart';
import '../../services/ai_engine.dart';
import '../../services/database_service.dart';
import '../../services/voice_service.dart';
import '../../widgets/tracing_view.dart';
import '../../widgets/matching_view.dart';

class ActivityScreen extends StatefulWidget {
  final ChildProfile child;
  final String conceptId;

  const ActivityScreen({super.key, required this.child, required this.conceptId});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  late String currentMode;
  List<LearningLog> sessionLogs = [];
  final VoiceService _voice = VoiceService();
  final DatabaseService _db = DatabaseService();
  
  // Dynamic thresholds from Admin config
  double masteryThreshold = 0.9; 
  int retryThreshold = 3;

  @override
  void initState() {
    super.initState();
    currentMode = widget.child.preferredMode;
    _fetchConceptConfig(); // Load Admin-configured rules
    _giveInstructions();
  }

  // Load the specific rules for this concept (e.g., Letter A)
  Future<void> _fetchConceptConfig() async {
    try {
      var doc = await FirebaseFirestore.instance.collection('concepts').doc(widget.conceptId).get();
      if (doc.exists) {
        setState(() {
          masteryThreshold = (doc.data()?['masteryThreshold'] ?? 0.9).toDouble();
          retryThreshold = (doc.data()?['retryThreshold'] ?? 3).toInt();
        });
      }
    } catch (e) {
      debugPrint("Config Error: $e");
    }
  }

  void _giveInstructions() {
    String letter = widget.conceptId.split('_').last;
    String msg = currentMode == "Tracing" 
      ? (widget.child.language == 'ml-IN' ? "$letter വരയ്ക്കൂ" : "Trace $letter") 
      : (widget.child.language == 'ml-IN' ? "$letter കണ്ടെത്തൂ" : "Find $letter");
    _voice.speakGreeting(msg, widget.child.language);
  }

  void _handleGameResult(bool isSuccess) async {
    // 1. Log attempt
    sessionLogs.add(LearningLog(
      activityId: DateTime.now().toString(),
      conceptId: widget.conceptId,
      activityMode: currentMode,
      isSuccess: isSuccess,
      timeSpent: 10,
      timestamp: DateTime.now(),
    ));

    // 2. Run AI Mastery Logic (BKT)
    double currentScore = widget.child.masteryScores[widget.conceptId] ?? 0.1;
    double newScore = AIEngine.calculateNewMastery(currentScore, isSuccess);
    widget.child.masteryScores[widget.conceptId] = newScore;

    // 3. PERFORMANCE-BASED REDIRECTION CHECK
    if (AIEngine.shouldRedirect(sessionLogs, retryThreshold)) {
      _triggerPerformanceRedirection();
    } else if (AIEngine.hasMastered(newScore, masteryThreshold)) {
      if (isSuccess) _voice.speakPraise(widget.child.language);
      _showSuccessDialog();
    } else {
      if (isSuccess) _voice.speakPraise(widget.child.language);
    }

    // 4. Update Database
    await _db.updateChildAIStats(widget.child.id, currentMode, widget.child.masteryScores);
  }

  // Performance-based redirection logic
  void _triggerPerformanceRedirection() async {
    // Query Firestore for activities of the same concept but DIFFERENT mode
    var snapshot = await FirebaseFirestore.instance
        .collection('activities')
        .where('conceptId', isEqualTo: widget.conceptId)
        .where('language', isEqualTo: widget.child.language)
        .get();

    for (var doc in snapshot.docs) {
      if (doc['activityMode'] != currentMode) {
        setState(() {
          currentMode = doc['activityMode'];
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("AI: Personalized learning mode updated!"), backgroundColor: Colors.indigo),
        );
        _voice.speakRedirection(widget.child.language);
        break;
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.network('https://assets10.lottiefiles.com/packages/lf20_u4yrau.json', height: 200, repeat: false),
            const Text("SUPER STAR!", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 10),
            Text("Goal Reached: ${(masteryThreshold * 100).toInt()}% Mastery!", textAlign: TextAlign.center),
          ],
        ),
        actions: [
          Center(child: ElevatedButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text("Next Adventure!"))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String displayLetter = widget.conceptId.split('_').last;
    return Scaffold(
      appBar: AppBar(title: Text("Adventure: $displayLetter"), backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Chip(
                label: Text("Performance Mode: $currentMode"),
                avatar: const Icon(Icons.auto_awesome, size: 16),
                backgroundColor: Colors.blue.shade50,
              ),
              const SizedBox(height: 20),
              currentMode == "Tracing"
                  ? TracingView(letter: displayLetter, onComplete: _handleGameResult)
                  : MatchingView(letter: displayLetter, onComplete: _handleGameResult),
            ],
          ),
        ),
      ),
    );
  }
}