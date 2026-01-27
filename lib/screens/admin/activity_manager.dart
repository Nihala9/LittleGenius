import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/concept_model.dart';
import '../../models/activity_model.dart';
import '../../services/database_service.dart';
import '../../services/theme_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/admin_scaffold.dart';

class ActivityManagerScreen extends StatefulWidget {
  final Concept concept;
  const ActivityManagerScreen({super.key, required this.concept});

  @override
  State<ActivityManagerScreen> createState() => _ActivityManagerScreenState();
}

class _ActivityManagerScreenState extends State<ActivityManagerScreen> {
  final _db = DatabaseService();

  void _showActivityDialog(ThemeService theme, {Activity? existing}) {
    String mode = existing?.activityMode ?? "Tracing";
    String lang = existing?.language ?? "English";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: Text(
            existing == null ? "New Game Style" : "Update Style", 
            style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Choose an AI teaching mode for this lesson.", 
                style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: mode, 
                dropdownColor: theme.cardColor,
                style: TextStyle(color: theme.textColor),
                decoration: InputDecoration(
                  labelText: "AI Mode",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
                items: ["Tracing", "Matching", "Puzzle", "AudioQuest", "Story", "Flashcard"]
                    .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setDialogState(() => mode = v!),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: lang, 
                dropdownColor: theme.cardColor,
                style: TextStyle(color: theme.textColor),
                decoration: InputDecoration(
                  labelText: "Content Language",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
                items: ["English", "Malayalam", "Hindi", "French", "Spanish"]
                    .map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                onChanged: (v) => setDialogState(() => lang = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.oceanBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              onPressed: () async {
                final data = {
                  'conceptId': widget.concept.id,
                  'title': "${widget.concept.name} ($mode)",
                  'activityMode': mode,
                  'language': lang,
                  'difficulty': 1
                };
                if (existing == null) {
                  await _db.addActivity(Activity.fromMap(data, ""));
                } else {
                  await _db.updateActivity(existing.id, data);
                }
                if (mounted) Navigator.pop(context);
              }, 
              child: const Text("Save Mode", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String id, String mode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Activity?"),
        content: Text("Delete the '$mode' variant?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await _db.deleteActivity(id);
              if (mounted) Navigator.pop(ctx);
            }, 
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context);

    return AdminScaffold(
      title: "${widget.concept.name} Variants",
      // Path: Home (0) > Categories (1) > Alphabets (2) > Letter A (3)
      breadcrumbs: ["Home", "Categories", widget.concept.category, widget.concept.name],
      body: Stack(
        children: [
          StreamBuilder<List<Activity>>(
            stream: _db.streamActivitiesForConcept(widget.concept.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.oceanBlue));
              }
              final list = snapshot.data ?? [];

              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.extension_off_rounded, size: 80, color: theme.subTextColor),
                      const SizedBox(height: 20),
                      Text("No game modes defined.", style: TextStyle(color: theme.subTextColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final activity = list[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.borderColor),
                    ),
                    child: ListTile(
                      leading: Icon(_getIcon(activity.activityMode), color: AppColors.oceanBlue),
                      title: Text("${activity.activityMode} Mode", style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)),
                      subtitle: Text("Language: ${activity.language}", style: TextStyle(color: theme.subTextColor)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit_note), onPressed: () => _showActivityDialog(theme, existing: activity)),
                          IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.redAccent), onPressed: () => _confirmDelete(activity.id, activity.activityMode)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          Positioned(
            bottom: 30, right: 30,
            child: FloatingActionButton.extended(
              onPressed: () => _showActivityDialog(theme),
              backgroundColor: AppColors.oceanBlue,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Add Mode", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  IconData _getIcon(String mode) {
    String m = mode.toLowerCase();
    if (m.contains("tracing")) return Icons.gesture_rounded;
    if (m.contains("matching")) return Icons.extension_rounded;
    if (m.contains("puzzle")) return Icons.grid_view_rounded;
    if (m.contains("audio")) return Icons.volume_up_rounded;
    if (m.contains("flashcard")) return Icons.style_rounded;
    return Icons.videogame_asset_rounded;
  }
}