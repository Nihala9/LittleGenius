import 'package:flutter/material.dart';
import '../../models/child_model.dart';
import '../../services/database_service.dart';
import '../../utils/app_colors.dart';
import 'learning_map.dart';

class CategorySelectorScreen extends StatelessWidget {
  final ChildProfile child;
  const CategorySelectorScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFF), // Clean off-white background
      body: SafeArea(
        child: Column(
          children: [
            // --- CUSTOM HEADER (Matches your Image) ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                children: [
                  // Back Button (Subtle, top left)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  
                  const SizedBox(height: 5),
                  
                  // Main Title
                  const Text(
                    "Choose Your Adventure",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900, // Extra Bold
                      color: Color(0xFF7B61FF),    // The Purple/Blue from image
                      letterSpacing: 0.5,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Subtitle
                  const Text(
                    "Pick a subject to start learning and earning stars!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF525F7F), // Slate Grey
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // --- EXISTING CARD GRID (Unchanged Logic) ---
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: db.streamCategories(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final categories = snapshot.data!;

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, 
                      mainAxisSpacing: 25, 
                      crossAxisSpacing: 20, 
                      childAspectRatio: 0.85
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      
                      // Dynamic Colors for the "Glow" effect
                      List<Color> glows = [
                        const Color(0xFFF48FB1), // Pink
                        const Color(0xFF69F0AE), // Green
                        const Color(0xFF448AFF), // Blue
                        const Color(0xFFFFB74D), // Orange
                        const Color(0xFFE040FB), // Purple
                      ];
                      Color color = glows[index % glows.length];

                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (c) => LearningMapScreen(child: child, category: cat['name'])
                        )),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            // Subtle border matching the glow color
                            border: Border.all(color: color.withOpacity(0.15), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.15), 
                                blurRadius: 20, 
                                offset: const Offset(0, 10)
                              )
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(cat['imagePath'] ?? 'assets/icons/category/c1.png', height: 75),
                              const SizedBox(height: 20),
                              Text(
                                cat['name'], 
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 16, 
                                  color: AppColors.childNavy
                                )
                              ),
                              const SizedBox(height: 5),
                              // Lesson count simulator (Static for visual, or dynamic if you have data)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10)
                                ),
                                child: Text(
                                  "Tap to Play", 
                                  style: TextStyle(
                                    color: color.withOpacity(0.8), 
                                    fontSize: 10, 
                                    fontWeight: FontWeight.bold
                                  )
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}