import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../models/child_model.dart';
import '../../models/concept_model.dart';
import '../../models/activity_model.dart';
import '../../services/database_service.dart';
import '../../services/ai_engine.dart';
import '../../services/sound_service.dart'; // Using your SoundService
import '../../utils/app_colors.dart';
import 'game_container.dart';

class LearningMapScreen extends StatelessWidget {
  final ChildProfile child;
  final String category;

  const LearningMapScreen({super.key, required this.child, required this.category});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    final ai = AIEngine();

    return Scaffold(
      body: Stack(
        children: [
          // 1. THE IMMERSIVE BACKGROUND
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/map_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. SCROLLABLE ADVENTURE PATH
          StreamBuilder<List<Concept>>(
            stream: db.streamPublishedConceptsByCategory(category),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final concepts = snapshot.data!;

              if (concepts.isEmpty) {
                return const Center(child: Text("No levels found yet!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 120, horizontal: 20),
                itemCount: concepts.length,
                itemBuilder: (context, index) {
                  final concept = concepts[index];
                  double mastery = child.masteryScores[concept.id] ?? 0.0;
                  
                  // Logic to unlock: First node is always open, others depend on previous mastery
                  bool isLocked = index > 0 && (child.masteryScores[concepts[index - 1].id] ?? 0.0) < 0.5;

                  return _buildWindingNode(context, concept, index, mastery, isLocked, ai);
                },
              );
            },
          ),
          
          // 3. TOP NAVIGATION OVERLAY
          _buildTopOverlay(context),
        ],
      ),
    );
  }

  Widget _buildTopOverlay(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                SoundService.playSFX('pop.mp3');
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back, color: AppColors.childNavy),
              ),
            ),
            const SizedBox(width: 15),
            // Header for Category Name
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                category.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindingNode(BuildContext context, Concept concept, int index, double mastery, bool isLocked, AIEngine ai) {
    // --- PATH ALIGNMENT LOGIC ---
    // This creates the "S" curve movement to match your map image road
    double horizontalOffset;
    int cycle = index % 4;
    if (cycle == 0) horizontalOffset = -0.6; // Left
    else if (cycle == 1) horizontalOffset = 0.0; // Center
    else if (cycle == 2) horizontalOffset = 0.6; // Right
    else horizontalOffset = 0.0; // Center again

    return Align(
      alignment: Alignment(horizontalOffset, 0),
      child: FadeInDown(
        delay: Duration(milliseconds: index * 100),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              GestureDetector(
                onTap: isLocked ? null : () async {
                  SoundService.playSFX('pop.mp3');
                  Activity? activity = await ai.getPersonalizedActivity(child, concept.id);
                  if (activity != null && context.mounted) {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (c) => GameContainer(child: child, concept: concept, activity: activity)
                    ));
                  }
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Node Glow/Background
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        color: isLocked ? Colors.black45 : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isLocked ? Colors.transparent : AppColors.childBlue.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 2
                          )
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          isLocked ? Icons.lock_outline : (mastery >= 0.8 ? Icons.star_rounded : Icons.play_arrow_rounded),
                          size: 45,
                          color: isLocked ? Colors.white38 : (mastery >= 0.8 ? Colors.amber : AppColors.childBlue),
                        ),
                      ),
                    ),
                    // Progress Indicator
                    if (!isLocked)
                      SizedBox(
                        width: 105, height: 105,
                        child: CircularProgressIndicator(
                          value: mastery,
                          strokeWidth: 8,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(mastery >= 0.8 ? Colors.amber : AppColors.childYellow),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // TEXT STYLING: Shadowed for Forest readability
              Text(
                concept.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(offset: Offset(2, 2), blurRadius: 4.0, color: Colors.black87),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}