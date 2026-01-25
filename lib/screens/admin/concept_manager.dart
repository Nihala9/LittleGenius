import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/concept_model.dart';
import '../../services/database_service.dart';
import '../../services/theme_service.dart';
import '../../utils/app_colors.dart';
import 'activity_manager.dart';

class ConceptManagerScreen extends StatefulWidget {
  final String selectedCategory;
  const ConceptManagerScreen({super.key, required this.selectedCategory});
  @override
  State<ConceptManagerScreen> createState() => _ConceptManagerScreenState();
}

class _ConceptManagerScreenState extends State<ConceptManagerScreen> {
  final _db = DatabaseService();

  void _showDialog(ThemeService theme, {Concept? existing}) {
    final ctrl = TextEditingController(text: existing?.name ?? "");
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: theme.cardColor,
      title: Text(existing == null ? "Add ${widget.selectedCategory}" : "Edit Item", style: TextStyle(color: theme.textColor)),
      content: TextField(controller: ctrl, style: TextStyle(color: theme.textColor), decoration: const InputDecoration(hintText: "Name")),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
        ElevatedButton(onPressed: () async {
          final data = {'name': ctrl.text, 'category': widget.selectedCategory, 'order': 1};
          existing == null ? await _db.addConcept(Concept(id: '', name: ctrl.text, category: widget.selectedCategory, order: 1))
                           : await _db.updateConcept(existing.id, data);
          if (mounted) Navigator.pop(ctx);
        }, child: const Text("Save")),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context);
    return Scaffold(
      backgroundColor: theme.bgColor,
      appBar: AppBar(title: Text(widget.selectedCategory), backgroundColor: theme.cardColor, foregroundColor: theme.textColor),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryBlue,
        onPressed: () => _showDialog(theme),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<Concept>>(
        stream: _db.streamConceptsByCategory(widget.selectedCategory),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final list = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            itemBuilder: (context, i) => Card(
              color: theme.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: theme.borderColor)),
              child: ListTile(
                title: Text(list[i].name, style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showDialog(theme, existing: list[i])),
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18), onPressed: () => _db.deleteConcept(list[i].id)),
                    const Icon(Icons.chevron_right, color: AppColors.primaryBlue),
                  ],
                ),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ActivityManagerScreen(concept: list[i]))),
              ),
            ),
          );
        },
      ),
    );
  }
}