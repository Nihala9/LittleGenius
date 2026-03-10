import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../models/child_model.dart';
import '../../models/concept_model.dart';
import '../../services/database_service.dart';
import '../../utils/app_colors.dart';

class BadgeGalleryScreen extends StatelessWidget {
  final ChildProfile child;
  const BadgeGalleryScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    // List of badge definitions
    final List<Map<String, String>> badgeDefinitions = [
      {'id': 'Alphabets', 'name': 'Alphabet Explorer', 'icon': 'assets/icons/badges/b1.png'},
      {'id': 'Numbers', 'name': 'Math Wizard', 'icon': 'assets/icons/badges/b2.png'},
      {'id': 'General Knowledge', 'name': 'Super Scholar', 'icon': 'assets/icons/badges/b3.png'},
      {'id': 'Shapes', 'name': 'Shape Master', 'icon': 'assets/icons/badges/b4.png'},
      {'id': 'Colour', 'name': 'Colour Champ', 'icon': 'assets/icons/badges/b5.png'},
      {'id': 'Reading', 'name': 'Reading Rocket', 'icon': 'assets/icons/badges/b6.png'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        title: const Text("My Achievements", 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.childNavy,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Concept>>(
        // We fetch all concepts to group them by category
        stream: db.streamConcepts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final allConcepts = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(25),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, 
              mainAxisSpacing: 25, 
              crossAxisSpacing: 20, 
              childAspectRatio: 0.75 // Taller to fit the progress bar
            ),
            itemCount: badgeDefinitions.length,
            itemBuilder: (context, index) {
              final badge = badgeDefinitions[index];
              
              // --- AI LOGIC: Calculate levels achieved in this category ---
              // 1. Get all concept IDs that belong to this category
              final categoryConceptIds = allConcepts
                  .where((c) => c.category == badge['id'])
                  .map((c) => c.id)
                  .toList();

              // 2. Count how many of these levels the kid has achieved (Mastery >= 0.5 / 2 Stars)
              int completedLevelsCount = 0;
              for (var id in categoryConceptIds) {
                if ((child.masteryScores[id] ?? 0.0) >= 0.5) {
                  completedLevelsCount++;
                }
              }

              // 3. Check if they hit the target of 3
              bool isEarned = completedLevelsCount >= 3;

              return FadeInUp(
                delay: Duration(milliseconds: index * 100),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(35),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
                    border: isEarned 
                        ? Border.all(color: AppColors.childYellow, width: 3) 
                        : Border.all(color: Colors.grey.shade100, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Badge Icon
                      Opacity(
                        opacity: isEarned ? 1.0 : 0.2,
                        child: Image.asset(badge['icon']!, height: 85, fit: BoxFit.contain),
                      ),
                      const SizedBox(height: 12),
                      
                      // Badge Name
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(badge['name']!, 
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: isEarned ? AppColors.childNavy : Colors.grey,
                            fontSize: 14
                          )),
                      ),
                      const SizedBox(height: 8),

                      // --- PROGRESS INDICATOR (Kid-friendly) ---
                      if (!isEarned) 
                        Column(
                          children: [
                            Text("$completedLevelsCount / 3 Levels", 
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.childBlue)),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: completedLevelsCount / 3,
                                  backgroundColor: Colors.grey.shade100,
                                  valueColor: const AlwaysStoppedAnimation(AppColors.childBlue),
                                  minHeight: 6,
                                ),
                              ),
                            )
                          ],
                        )
                      else 
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_rounded, color: AppColors.childGreen, size: 16),
                            SizedBox(width: 4),
                            Text("UNLOCKED", style: TextStyle(color: AppColors.childGreen, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ],
                        ),
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