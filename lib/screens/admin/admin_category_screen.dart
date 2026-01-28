import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../services/theme_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/admin_scaffold.dart';
import 'concept_manager.dart';

class AdminCategoryScreen extends StatelessWidget {
  const AdminCategoryScreen({super.key});

  // --- CRUD: SHOW DIALOG FOR ADD/EDIT ---
  void _showCategoryDialog(BuildContext context, ThemeService theme, {Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? "");
    int selectedIconCode = existing?['iconCode'] ?? Icons.folder_rounded.codePoint;
    
    final List<IconData> availableIcons = [
      Icons.abc_rounded, Icons.numbers_rounded, Icons.pets_rounded, 
      Icons.category_rounded, Icons.palette_rounded, Icons.star_rounded,
      Icons.directions_car_rounded, Icons.music_note_rounded
    ];

    final db = DatabaseService();

    showDialog(
      context: context, 
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            existing == null ? "New Category" : "Edit Category", 
            style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl, 
                  style: TextStyle(color: theme.textColor),
                  decoration: const InputDecoration(labelText: "Category Name", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                const Text("Visual Icon", style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: availableIcons.map((icon) => GestureDetector(
                    onTap: () => setDialogState(() => selectedIconCode = icon.codePoint),
                    child: CircleAvatar(
                      backgroundColor: selectedIconCode == icon.codePoint ? AppColors.oceanBlue : theme.borderColor,
                      radius: 20,
                      child: Icon(icon, color: selectedIconCode == icon.codePoint ? Colors.white : theme.textColor, size: 20),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.oceanBlue),
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                final data = {
                  'name': nameCtrl.text.trim(),
                  'iconCode': selectedIconCode,
                };
                existing == null ? await db.addCategory(data) : await db.updateCategory(existing['id'], data);
                if (context.mounted) Navigator.pop(ctx);
              }, 
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Category?"),
        content: Text("Are you sure you want to delete '$name'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await DatabaseService().deleteCategory(id);
              if (context.mounted) Navigator.pop(ctx);
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
    final db = DatabaseService();

    return AdminScaffold(
      title: "Content Roadmap",
      breadcrumbs: const ["Home", "Categories"],
      body: Stack(
        children: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: db.streamCategories(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.oceanBlue));
              }
              
              final list = snapshot.data ?? [];

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final cat = list[i];
                  String firstLetter = cat['name'] != null && cat['name'].isNotEmpty 
                      ? cat['name'][0].toUpperCase() : "?";

                  return Card(
                    color: theme.cardColor,
                    margin: const EdgeInsets.only(bottom: 15),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20), 
                      side: BorderSide(color: theme.borderColor)
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(15),
                      // ALPHABETICAL BADGE: Shows the first letter
                      leading: CircleAvatar(
                        backgroundColor: AppColors.oceanBlue,
                        child: Text(firstLetter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(cat['name'], 
                        style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: const Text("Learning Folder", style: TextStyle(color: AppColors.teal, fontSize: 11)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit_outlined, size: 20), 
                            onPressed: () => _showCategoryDialog(context, theme, existing: cat)),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), 
                            onPressed: () => _confirmDelete(context, cat['id'], cat['name'])),
                        ],
                      ),
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (c) => ConceptManagerScreen(selectedCategory: cat['name'])
                      )),
                    ),
                  );
                },
              );
            },
          ),
          Positioned(
            bottom: 30, right: 30,
            child: FloatingActionButton.extended(
              onPressed: () => _showCategoryDialog(context, theme),
              backgroundColor: AppColors.oceanBlue,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("New Category", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}