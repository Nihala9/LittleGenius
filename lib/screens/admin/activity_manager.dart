import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/activity_model.dart';
import '../../models/child_profile.dart';
import '../child/activity_screen.dart';

class ActivityManager extends StatelessWidget {
  const ActivityManager({super.key});

  void _preview(BuildContext context, Activity act) {
    // Req 7: Mock session for validation
    final mock = ChildProfile(id: "preview", parentId: "admin", name: "Admin (Preview)", age: 5, language: act.language, masteryScores: {});
    Navigator.push(context, MaterialPageRoute(builder: (context) => ActivityScreen(child: mock, conceptId: act.conceptId)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Global Content Library")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('activities').snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final act = Activity.fromMap(docs[i].data() as Map<String, dynamic>, docs[i].id);
              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(act.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${act.activityMode} | ${act.language} | Goal: ${act.masteryGoal}"),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(onTap: () => _preview(context, act), child: const Text("Preview as Child")),
                      PopupMenuItem(onTap: () => docs[i].reference.update({'status': 'published'}), child: const Text("Publish")),
                      PopupMenuItem(onTap: () => docs[i].reference.update({'status': 'draft'}), child: const Text("Unpublish")),
                      PopupMenuItem(onTap: () => docs[i].reference.delete(), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}