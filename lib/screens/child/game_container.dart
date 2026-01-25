import 'package:flutter/material.dart';
import '../../models/child_model.dart';
import '../../models/activity_model.dart';
import '../../services/database_service.dart';
import '../../services/ai_service.dart';
import 'games/tracing_game.dart';
import 'games/matching_game.dart';

class GameContainer extends StatefulWidget {
  final ChildProfile child;
  final Activity activity;
  final String parentId;

  const GameContainer({
    super.key, 
    required this.child, 
    required this.activity, 
    required this.parentId
  });

  @override
  State<GameContainer> createState() => _GameContainerState();
}

class _GameContainerState extends State<GameContainer> {
  final _db = DatabaseService();
  final _ai = AIService();

  void _onGameFinished(bool isSuccess) async {
    // 1. Calculate new Mastery using BKT Logic
    // We fetch the current score for this specific concept
    double currentScore = widget.child.masteryScores[widget.activity.conceptId] ?? 0.1;
    
    // AI predicts the new mastery probability based on the performance
    double newScore = _ai.calculateNewMastery(currentScore, isSuccess);

    // 2. Save result to Firestore
    await _db.updateMastery(widget.parentId, widget.child.id, widget.activity.conceptId, newScore);

    // 3. Show Result Dialog (Rewards or Motivation)
    if (!mounted) return;
    _showResult(isSuccess);
  }

  void _showResult(bool isSuccess) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isSuccess ? "Super Job!" : "Nice Try!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSuccess ? Icons.stars : Icons.refresh_rounded, 
              size: 80, 
              color: isSuccess ? Colors.orange : Colors.blue
            ),
            const SizedBox(height: 15),
            Text(
              isSuccess 
                ? "You earned points!" 
                : "Let's keep practicing.",
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to Learning Map
            }, 
            child: const Text("Next Level")
          )
        ],
      ),
    );
  }

  // --- THE ROUTER LOGIC ---
  // This builds the specific game widget based on what the AI engine suggested
  Widget _buildSelectedGame() {
    String mode = widget.activity.activityMode.toLowerCase();
    
    switch (mode) {
      case 'tracing':
        return TracingGame(onComplete: _onGameFinished);
        
      case 'matching':
        return MatchingGame(
          conceptName: widget.activity.title, 
          onComplete: _onGameFinished
        );
        
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_empty, size: 50, color: Colors.grey),
              const SizedBox(height: 10),
              Text("Mode '$mode' is being prepared..."),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity.title),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        // Child can quit at any time back to the map
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: _buildSelectedGame(), // Call the builder here
      ),
    );
  }
}