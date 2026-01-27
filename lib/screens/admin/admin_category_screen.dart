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
    final db = DatabaseService();

    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          existing == null ? "Create New Category" : "Edit Category", 
          style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Define a high-level folder for your lessons (e.g., Alphabets, Animals).", 
              style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl, 
              style: TextStyle(color: theme.textColor),
              decoration: InputDecoration(
                hintText: "Category Name",
                filled: true,
                fillColor: theme.isDarkMode ? Colors.white.withAlpha(5) : Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.oceanBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              final data = {'name': nameCtrl.text.trim()};
              
              if (existing == null) {
                await db.addCategory(data);
              } else {
                await db.updateCategory(existing['id'], data);
              }
              if (context.mounted) Navigator.pop(ctx);
            }, 
            child: const Text("Save Category", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- CRUD: DELETE CONFIRMATION ---
  void _confirmDelete(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Category?"),
        content: Text("Warning: Deleting '$name' will make all lessons inside it inaccessible."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Keep it")),
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
      title: "Content Categories",
      // BREADCRUMB PATH: Home > Categories
      breadcrumbs: const ["Home", "Categories"],
      body: Stack(
        children: [
          // 1. DYNAMIC CATEGORY LIST
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: db.streamCategories(),
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
                      Icon(Icons.folder_open_rounded, size: 80, color: theme.subTextColor),
                      const SizedBox(height: 20),
                      Text("No categories found.", style: TextStyle(color: theme.subTextColor, fontWeight: FontWeight.bold)),
                      const Text("Click (+) to start building the learning library.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100), // Extra bottom padding for FAB
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final cat = list[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.borderColor),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.oceanBlue.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.folder_rounded, color: AppColors.oceanBlue),
                      ),
                      title: Text(cat['name'], 
                        style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: const Text("Lesson Folder", style: TextStyle(color: AppColors.teal, fontSize: 10, fontWeight: FontWeight.bold)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20), 
                            onPressed: () => _showCategoryDialog(context, theme, existing: cat)
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20), 
                            onPressed: () => _confirmDelete(context, cat['id'], cat['name'])
                          ),
                          const VerticalDivider(),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.oceanBlue),
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
          
          // 2. FLOATING ADD BUTTON (Positioned inside the Stack)
          Positioned(
            bottom: 30,
            right: 30,
            child: FloatingActionButton.extended(
              onPressed: () => _showCategoryDialog(context, theme),
              backgroundColor: AppColors.oceanBlue,
              elevation: 8,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Add Category", 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ),
          )
        ],
      ),
    );
  }
}