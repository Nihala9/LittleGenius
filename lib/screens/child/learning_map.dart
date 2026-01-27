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
  final String category;

  LearningMapScreen({super.key, required this.child, required this.category});

  final _db = DatabaseService();
  final _ai = AIEngine();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.settings, color: Colors.grey),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ParentDashboard(specificChild: child))),
        ),
        title: Text("$category Adventure", style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Concept>>(
        // --- SPRINT 1 COMPLETION: FETCH ONLY PUBLISHED CONTENT ---
        stream: _db.streamPublishedConceptsByCategory(category),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
          }
          final concepts = snapshot.data ?? [];

          if (concepts.isEmpty) {
            return const Center(child: Text("No adventures are live yet! Come back soon."));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 80),
            reverse: true,
            itemCount: concepts.length,
            itemBuilder: (context, index) {
              bool isUnlocked = index == 0 || (child.masteryScores[concepts[index - 1].id] ?? 0.0) > 0.8;
              return _buildPathNode(context, concepts[index], index, isUnlocked);
            },
          );
        },
      ),
    );
  }

  Widget _buildPathNode(BuildContext context, Concept concept, int index, bool isUnlocked) {
    double leftPadding = (index % 4 == 0 || index % 4 == 3) ? 40 : 200;
    return Padding(
      padding: EdgeInsets.only(left: leftPadding, bottom: 60),
      child: Column(
        children: [
          GestureDetector(
            onTap: isUnlocked ? () async {
              var activity = await _ai.getPersonalizedActivity(child, concept.id);
              if (activity != null && context.mounted) {
                Navigator.push(context, MaterialPageRoute(builder: (c) => GameContainer(child: child, activity: activity, parentId: FirebaseAuth.instance.currentUser!.uid)));
              }
            } : null,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: isUnlocked ? AppColors.primaryBlue : Colors.grey.shade300,
              child: Icon(isUnlocked ? Icons.play_arrow_rounded : Icons.lock_outline, color: Colors.white, size: 45),
            ),
          ),
          const SizedBox(height: 10),
          Text(concept.name, style: TextStyle(fontWeight: FontWeight.bold, color: isUnlocked ? AppColors.textDark : Colors.grey)),
        ],
      ),
    );
  }
}