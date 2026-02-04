import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/activity_model.dart';
import '../../models/child_model.dart';
import '../../models/concept_model.dart';
import '../../services/database_service.dart';
import '../../services/theme_service.dart';
import '../../utils/app_colors.dart';
import '../child/game_container.dart'; // To launch the test game

class ContentReviewScreen extends StatelessWidget {
  const ContentReviewScreen({super.key});

  // Creates a temporary profile for the Admin to test games
  ChildProfile _createTestProfile(String language) {
    return ChildProfile(
      id: "admin_tester",
      name: "Admin Tester",
      age: 5,
      childClass: "Admin Mode",
      language: language,
      avatarUrl: "assets/icons/profiles/p1.png",
      totalStars: 0,
      dailyLimit: 999, // No time limit for admin testing
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context);
    final db = DatabaseService();

    return Scaffold(
      backgroundColor: theme.bgColor,
      appBar: AppBar(
        title: Text("CONTENT TESTER & REVIEW", 
          style: TextStyle(color: theme.textColor, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: theme.cardColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.grey),
            onPressed: () => _showHelp(context),
          )
        ],
      ),
      body: StreamBuilder<List<Activity>>(
        stream: db.streamAllActivities(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: theme.textColor));
          }
          final activities = snapshot.data ?? [];

          if (activities.isEmpty) {
            return _buildEmptyState(theme);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: activities.length,
            itemBuilder: (context, i) {
              final activity = activities[i];
              return _buildActivityReviewCard(context, theme, activity, db);
            },
          );
        },
      ),
    );
  }

  Widget _buildActivityReviewCard(BuildContext context, ThemeService theme, Activity activity, DatabaseService db) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.borderColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          backgroundColor: _getModeColor(activity.activityMode).withOpacity(0.1),
          child: Icon(_getModeIcon(activity.activityMode), color: _getModeColor(activity.activityMode), size: 20),
        ),
        title: Text(activity.title, 
            style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Row(
              children: [
                _badge(activity.language, Colors.blueGrey),
                const SizedBox(width: 8),
                _badge(activity.activityMode, AppColors.oceanBlue),
              ],
            ),
          ],
        ),
        trailing: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: const Text("TEST", style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () async {
            // 1. Fetch the Concept details to provide the target (e.g., 'A') to the game
            final concepts = await db.streamConcepts().first;
            final concept = concepts.firstWhere((c) => c.id == activity.conceptId, 
              orElse: () => Concept(id: activity.conceptId, name: "Test", category: "Test", order: 1));

            if (!context.mounted) return;

            // 2. Launch the Game Container in "Admin Test Mode"
            Navigator.push(context, MaterialPageRoute(
              builder: (c) => GameContainer(
                child: _createTestProfile(activity.language),
                concept: concept,
                activity: activity,
              )
            ));
          },
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState(ThemeService theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: theme.subTextColor),
          const SizedBox(height: 15),
          Text("No activities found to review.", style: TextStyle(color: theme.subTextColor)),
        ],
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Content Review Mode"),
        content: const Text("This console allows you to test every game mode you have created. Tap 'TEST' to launch a sandbox version of the game. Scores earned here will not affect any real student profiles."),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("Got it"))],
      ),
    );
  }

  IconData _getModeIcon(String mode) {
    switch (mode) {
      case 'Tracing': return Icons.gesture;
      case 'Matching': return Icons.extension;
      case 'Puzzle': return Icons.grid_view_rounded;
      case 'AudioQuest': return Icons.volume_up;
      default: return Icons.play_circle_fill;
    }
  }

  Color _getModeColor(String mode) {
    switch (mode) {
      case 'Tracing': return Colors.orange;
      case 'Matching': return Colors.purple;
      case 'Puzzle': return Colors.blue;
      case 'AudioQuest': return Colors.red;
      default: return Colors.teal;
    }
  }
}