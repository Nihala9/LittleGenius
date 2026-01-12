import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';
import '../../models/child_profile.dart';
import '../../services/auth_service.dart';
import '../child/adventure_map_screen.dart';
import 'progress_report_screen.dart';

class ParentDashboard extends StatelessWidget {
  final DatabaseService _db = DatabaseService();
  final String parentId = FirebaseAuth.instance.currentUser!.uid;

  ParentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("LittleGenius Dashboard"),
        backgroundColor: Colors.blue.shade50,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              Navigator.of(context).pop();
            },
          )
        ],
      ),
      body: StreamBuilder<List<ChildProfile>>(
        stream: _db.getChildren(parentId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final children = snapshot.data!;
          return ListView.builder(
            itemCount: children.length,
            itemBuilder: (context, index) {
              final child = children[index];
              return Card(
                margin: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: CircleAvatar(child: Text(child.name[0])),
                  title: Text(child.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Limit: ${child.dailyLimit}m | Used: ${child.usageToday}m"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.bar_chart, color: Colors.blue),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProgressReportScreen(child: child))),
                      ),
                      IconButton(
                        icon: const Icon(Icons.play_circle_fill, color: Colors.green, size: 30),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdventureMapScreen(child: child))),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddChildDialog(context),
        label: const Text("Add Child"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showAddChildDialog(BuildContext context) {
    final nameController = TextEditingController();
    int selectedAge = 2;
    String selectedLang = 'en-US';
    double selectedLimit = 30; // Default limit

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("New Child Profile"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: selectedLang,
                  decoration: const InputDecoration(labelText: "Language"),
                  items: const [
                    DropdownMenuItem(value: 'en-US', child: Text("English")),
                    DropdownMenuItem(value: 'ml-IN', child: Text("Malayalam")),
                    DropdownMenuItem(value: 'hi-IN', child: Text("Hindi")),
                  ],
                  onChanged: (val) => setState(() => selectedLang = val!),
                ),
                const SizedBox(height: 20),
                Text("Daily Limit: ${selectedLimit.toInt()} Minutes", style: const TextStyle(fontSize: 14)),
                Slider(
                  value: selectedLimit,
                  min: 15,
                  max: 120,
                  divisions: 7,
                  onChanged: (val) => setState(() => selectedLimit = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final newChild = ChildProfile(
                    id: '',
                    parentId: parentId,
                    name: nameController.text,
                    age: selectedAge,
                    language: selectedLang,
                    dailyLimit: selectedLimit.toInt(),
                    usageToday: 0,
                    masteryScores: {},
                  );
                  await _db.addChildProfile(newChild);
                  Navigator.pop(context);
                }
              },
              child: const Text("Create"),
            ),
          ],
        ),
      ),
    );
  }
}