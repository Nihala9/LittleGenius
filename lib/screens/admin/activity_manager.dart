import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/concept_model.dart';
import '../../models/activity_model.dart';
import '../../services/database_service.dart';
import '../../services/theme_service.dart';
import '../../utils/app_colors.dart';

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
          title: Text(existing == null ? "Add Game Style" : "Edit Style", style: TextStyle(color: theme.textColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: mode, dropdownColor: theme.cardColor,
                style: TextStyle(color: theme.textColor),
                items: ["Tracing", "Matching", "Puzzle", "AudioQuest", "Story", "Flashcard"].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setDialogState(() => mode = v!),
              ),
              DropdownButtonFormField<String>(
                value: lang, dropdownColor: theme.cardColor,
                style: TextStyle(color: theme.textColor),
                items: ["English", "Malayalam", "Hindi"].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                onChanged: (v) => setDialogState(() => lang = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(onPressed: () async {
              final data = {'conceptId': widget.concept.id, 'title': "${widget.concept.name} ($mode)", 'activityMode': mode, 'language': lang, 'difficulty': 1};
              existing == null ? await _db.addActivity(Activity.fromMap(data, "")) : await _db.updateActivity(existing.id, data);
              if (mounted) Navigator.pop(context);
            }, child: const Text("Save")),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context);
    return Scaffold(
      backgroundColor: theme.bgColor,
      appBar: AppBar(title: Text("Modes: ${widget.concept.name}"), backgroundColor: theme.cardColor, foregroundColor: theme.textColor),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showActivityDialog(theme),
        backgroundColor: AppColors.accentOrange, child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<Activity>>(
        stream: _db.streamActivitiesForConcept(widget.concept.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final list = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: list.length,
            itemBuilder: (context, i) => Card(
              color: theme.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: theme.borderColor)),
              child: ListTile(
                leading: Icon(_getIcon(list[i].activityMode), color: AppColors.primaryBlue),
                title: Text(list[i].activityMode, style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)),
                subtitle: Text(list[i].language, style: TextStyle(color: theme.subTextColor)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showActivityDialog(theme, existing: list[i])),
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18), onPressed: () => _db.deleteActivity(list[i].id)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getIcon(String mode) {
    if (mode == "Tracing") return Icons.gesture;
    if (mode == "Matching") return Icons.extension;
    return Icons.videogame_asset;
  }
}