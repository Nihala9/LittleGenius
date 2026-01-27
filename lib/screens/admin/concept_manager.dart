import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/concept_model.dart';
import '../../services/database_service.dart';
import '../../services/theme_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/admin_scaffold.dart';
import 'activity_manager.dart';

class ConceptManagerScreen extends StatefulWidget {
  final String selectedCategory;
  const ConceptManagerScreen({super.key, required this.selectedCategory});

  @override
  State<ConceptManagerScreen> createState() => _ConceptManagerScreenState();
}

class _ConceptManagerScreenState extends State<ConceptManagerScreen> {
  final _db = DatabaseService();

  void _showConceptDialog(BuildContext context, ThemeService theme, {Concept? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? "");
    final orderCtrl = TextEditingController(text: existing?.order.toString() ?? "1");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(existing == null ? "Add New Lesson" : "Edit Lesson",
          style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: theme.textColor),
              decoration: InputDecoration(labelText: "Lesson Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: orderCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: theme.textColor),
              decoration: InputDecoration(labelText: "Map Order", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.oceanBlue),
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              final data = {
                'name': nameCtrl.text.trim(),
                'category': widget.selectedCategory,
                'order': int.tryParse(orderCtrl.text) ?? 1,
              };
              if (existing == null) {
                await _db.addConcept(Concept(id: '', name: data['name'] as String, category: data['category'] as String, order: data['order'] as int, isPublished: false));
              } else {
                await _db.updateConcept(existing.id, data);
              }
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context);

    return AdminScaffold(
      title: "Lessons: ${widget.selectedCategory}",
      breadcrumbs: ["Home", "Categories", widget.selectedCategory],
      body: Stack(
        children: [
          StreamBuilder<List<Concept>>(
            stream: _db.streamConceptsByCategory(widget.selectedCategory),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.oceanBlue));
              }
              final list = snapshot.data ?? [];

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final item = list[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      // VISUAL FEEDBACK: Teal border for Published, Grey for Draft
                      border: Border.all(color: item.isPublished ? AppColors.teal : theme.borderColor, width: 2),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      leading: CircleAvatar(
                        backgroundColor: item.isPublished ? AppColors.teal.withAlpha(30) : Colors.grey.withAlpha(30),
                        child: Text("${item.order}", style: TextStyle(color: item.isPublished ? AppColors.teal : Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(item.name, style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)),
                      subtitle: Text(item.isPublished ? "Status: Live" : "Status: Draft", 
                        style: TextStyle(color: item.isPublished ? AppColors.teal : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // GLOBAL VISIBILITY TOGGLE
                          Switch(
                            activeColor: AppColors.teal,
                            value: item.isPublished, 
                            onChanged: (val) => _db.updateConcept(item.id, {'isPublished': val}),
                          ),
                          const VerticalDivider(),
                          IconButton(icon: const Icon(Icons.games_rounded, color: AppColors.accentOrange), 
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ActivityManagerScreen(concept: item)))),
                        ],
                      ),
                      onLongPress: () => _showConceptDialog(context, theme, existing: item),
                    ),
                  );
                },
              );
            },
          ),
          Positioned(
            bottom: 30, right: 30,
            child: FloatingActionButton.extended(
              onPressed: () => _showConceptDialog(context, theme),
              backgroundColor: AppColors.oceanBlue,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("New Lesson", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}