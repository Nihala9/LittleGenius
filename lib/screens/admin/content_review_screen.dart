import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/activity_model.dart';
import '../../models/child_model.dart';
import '../../models/concept_model.dart';
import '../../services/database_service.dart';
import '../../services/theme_service.dart';
import '../../utils/app_colors.dart';
import '../child/game_container.dart';

class ContentReviewScreen extends StatefulWidget {
  const ContentReviewScreen({super.key});

  @override
  State<ContentReviewScreen> createState() => _ContentReviewScreenState();
}

class _ContentReviewScreenState extends State<ContentReviewScreen> {
  String _testLanguage = "English"; // Default test language

  ChildProfile _createTestProfile() {
    return ChildProfile(
      id: "admin_tester",
      name: "Admin Tester",
      age: 5,
      childClass: "Admin Mode",
      language: _testLanguage, // Use selected language
      avatarUrl: "assets/icons/profiles/p1.png",
      totalStars: 0,
      dailyLimit: 999,
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
          // LANGUAGE SELECTOR FOR TESTING
          DropdownButton<String>(
            value: _testLanguage,
            dropdownColor: theme.cardColor,
            style: TextStyle(color: theme.textColor, fontSize: 12),
            items: ["English", "Malayalam", "Hindi", "Arabic"].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
            onChanged: (v) => setState(() => _testLanguage = v!),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: StreamBuilder<List<Activity>>(
        stream: db.streamAllActivities(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: theme.textColor));
          }
          final activities = snapshot.data ?? [];
          if (activities.isEmpty) return _buildEmptyState(theme);

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: activities.length,
            itemBuilder: (context, i) => _buildActivityReviewCard(context, theme, activities[i], db),
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
        title: Text(activity.title, style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            _badge(activity.activityMode, AppColors.oceanBlue),
            if (activity.imageUrl != null && activity.imageUrl!.isNotEmpty) ...[
              const SizedBox(width: 8),
              _badge("Image Set", Colors.green),
            ]
          ],
        ),
        trailing: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal, foregroundColor: Colors.white),
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: const Text("TEST"),
          onPressed: () async {
            final concepts = await db.streamConcepts().first;
            final concept = concepts.firstWhere((c) => c.id == activity.conceptId, 
              orElse: () => Concept(id: activity.conceptId, name: "Test", category: "Test", order: 1));

            if (!context.mounted) return;
            Navigator.push(context, MaterialPageRoute(
              builder: (c) => GameContainer(
                child: _createTestProfile(),
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
    return Center(child: Text("No activities found.", style: TextStyle(color: theme.subTextColor)));
  }

  IconData _getModeIcon(String mode) {
    if (mode.contains('Tracing')) return Icons.gesture;
    if (mode.contains('Matching')) return Icons.extension;
    if (mode.contains('Puzzle')) return Icons.grid_view_rounded;
    if (mode.contains('Audio')) return Icons.volume_up;
    return Icons.play_circle_fill;
  }

  Color _getModeColor(String mode) {
    if (mode.contains('Tracing')) return Colors.orange;
    if (mode.contains('Matching')) return Colors.purple;
    if (mode.contains('Puzzle')) return Colors.blue;
    if (mode.contains('Audio')) return Colors.red;
    return Colors.teal;
  }
}