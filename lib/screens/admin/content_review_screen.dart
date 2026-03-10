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
  String _testLanguage = "English";

  // Creates a clean sandbox profile for testing
  ChildProfile _createTestProfile() {
    return ChildProfile(
      id: "admin_tester",
      name: "QA Tester",
      age: 5,
      childClass: "Admin Mode",
      language: _testLanguage,
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
        title: Text(
          "CONTENT TESTER", 
          style: TextStyle(
            color: theme.textColor, 
            fontSize: 18, // INCREASED from 14
            fontWeight: FontWeight.bold, 
            letterSpacing: 1.2
          )
        ),
        backgroundColor: theme.cardColor,
        elevation: 0,
        actions: [
          _buildLanguageSelector(theme),
          const SizedBox(width: 15),
        ],
      ),
      body: StreamBuilder<List<Concept>>(
        stream: db.streamConcepts(),
        builder: (context, conceptSnapshot) {
          return StreamBuilder<List<Activity>>(
            stream: db.streamAllActivities(),
            builder: (context, activitySnapshot) {
              if (conceptSnapshot.connectionState == ConnectionState.waiting ||
                  activitySnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final concepts = conceptSnapshot.data ?? [];
              final activities = activitySnapshot.data ?? [];

              if (activities.isEmpty) return _buildEmptyState(theme);

              // NESTED MAPPING: Map<Category, Map<Mode, List<Activity>>>
              Map<String, Map<String, List<Activity>>> nestedData = {};
              Map<String, Concept> conceptMap = {for (var c in concepts) c.id: c};

              for (var act in activities) {
                String category = conceptMap[act.conceptId]?.category ?? "General";
                nestedData.putIfAbsent(category, () => {});
                nestedData[category]!.putIfAbsent(act.activityMode, () => []).add(act);
              }

              final categories = nestedData.keys.toList()..sort();

              return ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  String catName = categories[index];
                  return _buildCollapsibleCategory(context, theme, catName, nestedData[catName]!, conceptMap);
                },
              );
            },
          );
        },
      ),
    );
  }

  // --- UI: MINIMIZABLE CATEGORY BLOCK ---
  Widget _buildCollapsibleCategory(BuildContext context, ThemeService theme, String category, Map<String, List<Activity>> modes, Map<String, Concept> conceptMap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.borderColor),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          maintainState: true,
          iconColor: AppColors.oceanBlue,
          leading: const Icon(Icons.folder_copy_rounded, color: AppColors.oceanBlue, size: 28),
          title: Text(
            category.toUpperCase(), 
            style: TextStyle(
              color: theme.textColor, 
              fontWeight: FontWeight.w900, 
              fontSize: 16, // INCREASED from 13
              letterSpacing: 1
            )
          ),
          subtitle: Text(
            "${modes.length} learning modes", 
            style: const TextStyle(fontSize: 13, color: Colors.grey) // INCREASED from 10
          ),
          children: [
            const Divider(height: 1),
            ...modes.entries.map((entry) {
              return _buildModeSection(context, theme, entry.key, entry.value, conceptMap);
            }),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSection(BuildContext context, ThemeService theme, String mode, List<Activity> acts, Map<String, Concept> conceptMap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 20, bottom: 12),
          child: Row(
            children: [
              Icon(_getModeIcon(mode), size: 18, color: _getModeColor(mode)), // INCREASED
              const SizedBox(width: 10),
              Text(
                mode, 
                style: TextStyle(
                  color: _getModeColor(mode), 
                  fontWeight: FontWeight.bold, 
                  fontSize: 15 // INCREASED from 11
                )
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
          child: Row(
            children: acts.map((act) {
              final concept = conceptMap[act.conceptId] ?? Concept(id: '', name: '?', category: '', order: 0);
              return _buildTestChip(context, theme, act, concept);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTestChip(BuildContext context, ThemeService theme, Activity act, Concept concept) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (c) => GameContainer(
            child: _createTestProfile(),
            concept: concept,
            activity: act,
          ),
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12), // INCREASED PADDING
        decoration: BoxDecoration(
          color: theme.bgColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: theme.borderColor),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
        ),
        child: Row(
          children: [
            Text(
              concept.name, 
              style: TextStyle(
                color: theme.textColor, 
                fontWeight: FontWeight.bold, 
                fontSize: 14 // INCREASED from 12
              )
            ),
            const SizedBox(width: 8),
            const Icon(Icons.play_arrow_rounded, size: 20, color: AppColors.teal), // INCREASED
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(ThemeService theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _testLanguage,
          dropdownColor: theme.cardColor,
          style: TextStyle(
            color: theme.textColor, 
            fontSize: 14, // INCREASED from 11
            fontWeight: FontWeight.bold
          ),
          items: ["English", "Malayalam", "Hindi", "Arabic"].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
          onChanged: (v) => setState(() => _testLanguage = v!),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeService theme) {
    return Center(
      child: Text(
        "No content found.", 
        style: TextStyle(color: theme.subTextColor, fontSize: 16)
      )
    );
  }

  IconData _getModeIcon(String mode) {
    if (mode.contains('Tracing')) return Icons.gesture;
    if (mode.contains('Matching')) return Icons.compare_arrows_rounded;
    if (mode.contains('Puzzle')) return Icons.grid_view_rounded;
    if (mode.contains('Audio')) return Icons.volume_up;
    if (mode.contains('Scratch')) return Icons.auto_fix_high;
    return Icons.play_circle_outline;
  }

  Color _getModeColor(String mode) {
    if (mode.contains('Tracing')) return Colors.orange;
    if (mode.contains('Matching')) return Colors.purple;
    if (mode.contains('Puzzle')) return Colors.blue;
    if (mode.contains('Audio')) return Colors.red;
    return Colors.teal;
  }
}