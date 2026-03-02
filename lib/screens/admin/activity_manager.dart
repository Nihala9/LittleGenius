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
    final imageCtrl = TextEditingController(text: existing?.imageUrl ?? "");

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: Text(
            existing == null ? "New Activity Mode" : "Update Mode", 
            style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Define the game style. The AI Tutor will handle translations based on the student's profile.", 
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 20),
                
                // 1. MODE SELECTOR (Universal)
                DropdownButtonFormField<String>(
                  value: mode, 
                  dropdownColor: theme.cardColor,
                  style: TextStyle(color: theme.textColor),
                  decoration: const InputDecoration(labelText: "Game Mode", border: OutlineInputBorder()),
                  items: ["Tracing", "Matching", "Puzzle", "AudioQuest", "Scratch Card"]
                      .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => setDialogState(() => mode = v!),
                ),

                // 2. IMAGE URL (For visual heavy games)
                if (mode == "Puzzle" || mode == "Scratch Card")
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: TextField(
                      controller: imageCtrl,
                      style: TextStyle(color: theme.textColor),
                      decoration: const InputDecoration(
                        labelText: "Resource Image URL",
                        hintText: "Public link to image/photo",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.oceanBlue),
              onPressed: () async {
                final data = {
                  'conceptId': widget.concept.id,
                  'title': "${widget.concept.name} ($mode)",
                  'activityMode': mode,
                  'difficulty': 1,
                  'imageUrl': imageCtrl.text.trim(),
                  // Note: 'language' is removed from the saved data
                };

                if (existing == null) {
                  await _db.addActivity(Activity.fromMap(data, ""));
                } else {
                  await _db.updateActivity(existing.id, data);
                }
                
                if (context.mounted) Navigator.pop(context);
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
        title: const Text("Delete Mode?"),
        content: Text("Remove the '$mode' variant for ${widget.concept.name}?"),
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
      title: "Activity Modes",
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
                      Icon(Icons.style_outlined, size: 60, color: theme.subTextColor),
                      const SizedBox(height: 10),
                      Text("No game modes defined yet.", style: TextStyle(color: theme.subTextColor)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final activity = list[i];
                  return Card(
                    color: theme.cardColor,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: theme.borderColor)),
                    child: ListTile(
                      leading: Icon(_getIcon(activity.activityMode), color: AppColors.oceanBlue),
                      title: Text(activity.activityMode, style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)),
                      subtitle: Text("Universal Mode", style: TextStyle(color: theme.subTextColor, fontSize: 11)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit_note), onPressed: () => _showActivityDialog(theme, existing: activity)),
                          IconButton(icon: const Icon(Icons.delete_forever, color: Colors.redAccent), onPressed: () => _confirmDelete(activity.id, activity.activityMode)),
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
              icon: const Icon(Icons.add_circle, color: Colors.white),
              label: const Text("Add Game Style", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  IconData _getIcon(String mode) {
    String m = mode.toLowerCase();
    if (m.contains("tracing")) return Icons.gesture;
    if (m.contains("matching")) return Icons.extension;
    if (m.contains("puzzle")) return Icons.grid_view_rounded;
    if (m.contains("audio")) return Icons.volume_up;
    if (m.contains("scratch")) return Icons.auto_fix_high;
    return Icons.videogame_asset;
  }
}