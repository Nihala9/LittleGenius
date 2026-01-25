import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../services/theme_service.dart';
import '../../utils/app_colors.dart';
import 'concept_manager.dart';

class AdminCategoryScreen extends StatelessWidget {
  const AdminCategoryScreen({super.key});

  void _showCategoryDialog(BuildContext context, ThemeService theme, {Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? "");
    final db = DatabaseService();

    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: theme.cardColor,
      title: Text(existing == null ? "New Category" : "Edit Category", style: TextStyle(color: theme.textColor)),
      content: TextField(controller: nameCtrl, style: TextStyle(color: theme.textColor), decoration: const InputDecoration(hintText: "Category Name")),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
        ElevatedButton(onPressed: () async {
          final data = {'name': nameCtrl.text, 'icon': Icons.folder.codePoint};
          existing == null ? await db.addCategory(data) : await db.updateCategory(existing['id'], data);
          if (context.mounted) Navigator.pop(ctx);
        }, child: const Text("Save")),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context);
    final db = DatabaseService();

    return Scaffold(
      backgroundColor: theme.bgColor,
      appBar: AppBar(title: const Text("CATEGORIES"), backgroundColor: theme.cardColor, foregroundColor: theme.textColor),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryBlue,
        onPressed: () => _showCategoryDialog(context, theme),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: db.streamCategories(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final list = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            itemBuilder: (context, i) => Card(
              color: theme.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: theme.borderColor)),
              child: ListTile(
                leading: const Icon(Icons.folder, color: AppColors.primaryBlue),
                title: Text(list[i]['name'], style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showCategoryDialog(context, theme, existing: list[i])),
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18), onPressed: () => db.deleteCategory(list[i]['id'])),
                  ],
                ),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ConceptManagerScreen(selectedCategory: list[i]['name']))),
              ),
            ),
          );
        },
      ),
    );
  }
}