import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../services/theme_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/admin_scaffold.dart';
import 'concept_manager.dart';

class AdminCategoryScreen extends StatelessWidget {
  const AdminCategoryScreen({super.key});

  // --- CRUD: SHOW DIALOG WITH IMAGE PICKER ---
  void _showCategoryDialog(BuildContext context, ThemeService theme, {Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? "");
    final orderCtrl = TextEditingController(text: existing?['order']?.toString() ?? "1");
    
    // IMAGE SELECTION LOGIC
    String selectedImagePath = existing?['imagePath'] ?? 'assets/icons/category/c1.png';
    
    // Predefined local assets provided by you
    final List<String> availableImages = [
      'assets/icons/category/c1.png',
      'assets/icons/category/c2.png',
      'assets/icons/category/c3.png',
      'assets/icons/category/c4.png',
      'assets/icons/category/c5.png',
      'assets/icons/category/c6.png',
      'assets/icons/category/c7.png',
      'assets/icons/category/c8.png',
      'assets/icons/category/c9.png',
    ];

    final db = DatabaseService();

    showDialog(
      context: context, 
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            existing == null ? "Create New Category" : "Edit Category", 
            style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Define the folder name, sequence, and pick a fun icon.", 
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 20),
                
                // 1. NAME INPUT
                TextField(
                  controller: nameCtrl, 
                  style: TextStyle(color: theme.textColor),
                  decoration: const InputDecoration(labelText: "Name", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),
                
                // 2. ORDER INPUT
                TextField(
                  controller: orderCtrl, 
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: theme.textColor),
                  decoration: const InputDecoration(labelText: "Map Order (1, 2, 3...)", border: OutlineInputBorder()),
                ),
                
                const SizedBox(height: 20),
                const Text("Select Category Icon", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),

                // 3. IMAGE PICKER GRID
                SizedBox(
                  height: 120,
                  width: double.maxFinite,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10),
                    itemCount: availableImages.length,
                    itemBuilder: (context, index) {
                      bool isSelected = selectedImagePath == availableImages[index];
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedImagePath = availableImages[index]),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.oceanBlue.withAlpha(40) : Colors.transparent,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isSelected ? AppColors.oceanBlue : Colors.grey.shade300, 
                              width: isSelected ? 3 : 1
                            ),
                          ),
                          child: Image.asset(availableImages[index]),
                        ),
                      );
                    },
                  ),
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
                  'order': int.tryParse(orderCtrl.text) ?? 1,
                  'imagePath': selectedImagePath, // Store the local path string
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
        content: Text("Delete '$name'?"),
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

              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map_rounded, size: 80, color: theme.subTextColor),
                      const SizedBox(height: 20),
                      const Text("No categories found."),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final cat = list[i];
                  String imgPath = cat['imagePath'] ?? 'assets/icons/category/c1.png';

                  return Card(
                    color: theme.cardColor,
                    margin: const EdgeInsets.only(bottom: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20), 
                      side: BorderSide(color: theme.borderColor)
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(15),
                      // PREVIEW OF THE SELECTED CATEGORY IMAGE
                      leading: Container(
                        width: 50, height: 50,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(color: AppColors.cloudySky.withAlpha(50), shape: BoxShape.circle),
                        child: Image.asset(imgPath),
                      ),
                      title: Text(cat['name'], 
                        style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: Text("Level Order: ${cat['order']}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit_note_rounded), onPressed: () => _showCategoryDialog(context, theme, existing: cat)),
                          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _confirmDelete(context, cat['id'], cat['name'])),
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
              icon: const Icon(Icons.add_to_photos_rounded, color: Colors.white),
              label: const Text("New Category", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}