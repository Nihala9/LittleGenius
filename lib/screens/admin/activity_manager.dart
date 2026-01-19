import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/activity_model.dart';
import '../../models/child_profile.dart';
import '../child/activity_screen.dart';
import 'activity_wizard.dart';
import 'activity_editor_screen.dart';

class ActivityManager extends StatefulWidget {
  const ActivityManager({super.key});

  @override
  State<ActivityManager> createState() => _ActivityManagerState();
}

class _ActivityManagerState extends State<ActivityManager> {
  String searchQuery = "";

  // --- FUNCTIONAL ACTIONS ---

  // US 04: Toggle between Draft and Published state
  Future<void> _toggleStatus(Activity activity) async {
    String newStatusString = activity.status == ActivityStatus.published ? "draft" : "published";
    
    await FirebaseFirestore.instance
        .collection('activities')
        .doc(activity.id)
        .update({'status': newStatusString});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Activity status updated to ${newStatusString.toUpperCase()}"),
          backgroundColor: Colors.indigo,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Req 07: Launch a mock session for Admin to test the game
  void _previewAsChild(BuildContext context, Activity act) {
    // FIXED: Added missing required parameters 'avatar' and 'masteryScores'
    final mockChild = ChildProfile(
      id: "preview_mode",
      parentId: "admin",
      name: "Admin",
      age: 5,
      avatar: "🦁", // Provided required avatar
      language: act.language,
      masteryScores: {}, // Provided required masteryScores
      usageToday: 0,
      dailyLimit: 60,
      preferredMode: 'Visual',
      totalStars: 0,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityScreen(
          child: mockChild,
          conceptId: act.conceptId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), 
      appBar: AppBar(
        title: const Text("Content Inventory", 
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // --- SEARCH BAR ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
            child: TextField(
              onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: "Search activities...",
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF4F46E5)),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16), 
                  borderSide: BorderSide.none
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),

          // --- DYNAMIC LIST ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('activities').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No activities found."));
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final title = doc['title'].toString().toLowerCase();
                  return title.contains(searchQuery);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final activity = Activity.fromMap(
                      docs[index].data() as Map<String, dynamic>, 
                      docs[index].id
                    );
                    return _buildActivityCard(context, activity, docs[index].reference);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ActivityWizard())),
        label: const Text("Create Activity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: const Color(0xFF4F46E5),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, Activity activity, DocumentReference docRef) {
    bool isPublished = activity.status == ActivityStatus.published;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(_getModeIcon(activity.activityMode), color: const Color(0xFF4F46E5), size: 24),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(activity.title, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            Text("${activity.subject} • ${activity.language}", 
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 15.0),
          child: Row(
            children: [
              InkWell(
                onTap: () => _toggleStatus(activity),
                child: _buildStatusPill(isPublished),
              ),
              const SizedBox(width: 10),
              Text("Age: ${activity.ageGroup}", 
                style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
            ],
          ),
        ),
        // PROFESSIONAL POPUP MENU
        trailing: PopupMenuButton<int>(
          icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          onSelected: (int value) {
            if (value == 1) _previewAsChild(context, activity);
            if (value == 2) {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => ActivityEditorScreen(activity: activity),
              ));
            }
            if (value == 3) docRef.delete();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 1,
              child: Row(children: [Icon(Icons.play_circle_fill, color: Colors.green, size: 20), SizedBox(width: 10), Text("Preview")]),
            ),
            const PopupMenuItem(
              value: 2,
              child: Row(children: [Icon(Icons.edit_rounded, color: Colors.blue, size: 20), SizedBox(width: 10), Text("Edit Details")]),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 3,
              child: Row(children: [Icon(Icons.delete_forever, color: Colors.red, size: 20), SizedBox(width: 10), Text("Delete", style: TextStyle(color: Colors.red))]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(bool isPublished) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isPublished ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isPublished ? "PUBLISHED" : "DRAFT",
        style: TextStyle(
          color: isPublished ? const Color(0xFF166534) : const Color(0xFF9A3412),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  IconData _getModeIcon(String mode) {
    if (mode == "Tracing" || mode == "Kinesthetic") return Icons.gesture_rounded;
    if (mode == "Matching" || mode == "Visual") return Icons.extension_rounded;
    return Icons.volume_up_rounded;
  }
}