import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/child_model.dart';
import '../../models/concept_model.dart';
import '../../services/database_service.dart';
import '../../services/ai_engine.dart';
import '../../utils/app_colors.dart';
import '../parent/parent_dashboard.dart';
import 'game_container.dart';

class LearningMapScreen extends StatelessWidget {
  final ChildProfile child;
  final String category; // Used to filter sequential lessons like A-Z or 1-10

  LearningMapScreen({super.key, required this.child, required this.category});

  final _db = DatabaseService();
  final _ai = AIEngine();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.settings, color: Colors.grey),
          onPressed: () => Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => ParentDashboard(specificChild: child))
          ),
        ),
        title: Text(
          "$category Adventure", 
          style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: CircleAvatar(
              backgroundColor: AppColors.lavender,
              backgroundImage: NetworkImage(child.avatarUrl),
            ),
          )
        ],
      ),
      body: StreamBuilder<List<Concept>>(
        // THE FILTER: Fetch only concepts that belong to the selected category (e.g. Alphabets)
        stream: _db.streamConceptsByCategory(category),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
          }
          
          final concepts = snapshot.data ?? [];

          if (concepts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  Text("No $category lessons available yet."),
                  const Text("Check the Admin dashboard to add content.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 80),
            reverse: true, // Adventure starts from the bottom of the screen
            itemCount: concepts.length,
            itemBuilder: (context, index) {
              // AI Scaffolding Logic:
              // Level 1 is always unlocked. 
              // Level 2 unlocks only if Level 1 mastery score in DB is > 80% (0.8)
              bool isUnlocked = index == 0 || 
                  (child.masteryScores[concepts[index - 1].id] ?? 0.0) > 0.8;

              return _buildPathNode(context, concepts[index], index, isUnlocked);
            },
          );
        },
      ),
    );
  }

  // --- COMPONENT: THE ZIG-ZAG ADVENTURE NODE ---
  Widget _buildPathNode(BuildContext context, Concept concept, int index, bool isUnlocked) {
    // Math to create the S-curve (Zig-Zag) path
    // Nodes shift horizontally based on their index
    double leftPadding = (index % 4 == 0 || index % 4 == 3) ? 40 : 200;

    return Padding(
      padding: EdgeInsets.only(left: leftPadding, bottom: 60),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: isUnlocked ? () async {
              // Trigger the AI Engine to pick the personalized game mode
              var activity = await _ai.getPersonalizedActivity(child, concept.id);
              
              if (activity != null && context.mounted) {
                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (c) => GameContainer(
                      child: child, 
                      activity: activity, 
                      parentId: FirebaseAuth.instance.currentUser!.uid
                    )
                  )
                );
              }
            } : null,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: isUnlocked 
                        ? AppColors.primaryBlue.withOpacity(0.2) 
                        : Colors.black.withOpacity(0.05), 
                    blurRadius: 15, 
                    offset: const Offset(0, 8)
                  )
                ],
              ),
              child: CircleAvatar(
                radius: 35,
                backgroundColor: isUnlocked ? AppColors.primaryBlue : Colors.grey.shade300,
                child: Icon(
                  isUnlocked ? Icons.play_arrow_rounded : Icons.lock_outline, 
                  color: Colors.white, 
                  size: 40
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Level Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Text(
              concept.name, 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                color: isUnlocked ? AppColors.textDark : Colors.grey
              )
            ),
          ),
        ],
      ),
    );
  }
}