import 'package:flutter/material.dart';
import '../../models/child_model.dart';
import '../../utils/app_colors.dart';
import '../../services/database_service.dart';
import '../../services/voice_service.dart';
import '../parent/parent_dashboard.dart';
import 'learning_map.dart';
import 'resource_grid_screen.dart';

class ChildHomeScreen extends StatelessWidget {
  final ChildProfile child;
  const ChildHomeScreen({super.key, required this.child});

  // Helper to rotate colors for the categories based on the order they appear
  Color _getRainbowColor(int index) {
    List<Color> palette = [
      AppColors.childPink,
      AppColors.childOrange,
      AppColors.childBlue,
      AppColors.childGreen,
    ];
    return palette[index % palette.length];
  }

  // Logic to determine which icon to show if the Admin didn't specify one
  IconData _getCategoryIcon(String name) {
    String n = name.toLowerCase();
    if (n.contains('alpha')) return Icons.abc_rounded;
    if (n.contains('num')) return Icons.calculate_rounded;
    if (n.contains('ani')) return Icons.pets_rounded;
    if (n.contains('shape')) return Icons.category_rounded;
    if (n.contains('social')) return Icons.volunteer_activism_rounded;
    return Icons.auto_stories_rounded; // Default
  }

  void _openParentLock(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Parents Only", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Solve this to unlock settings:"),
            const SizedBox(height: 10),
            const Text("12 + 6 = ?", 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.ultraViolet)),
            const SizedBox(height: 10),
            TextField(
              controller: controller, 
              keyboardType: TextInputType.number, 
              autofocus: true,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(hintText: "Answer"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (controller.text == "18") {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => ParentDashboard(specificChild: child)
                ));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Incorrect. Try again!")));
              }
            }, 
            child: const Text("Unlock", style: TextStyle(fontWeight: FontWeight.bold))
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    final voice = VoiceService();
    Color badgeColor = Color(int.parse(child.profileColor));

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: CustomScrollView(
        slivers: [
          // 1. APP BAR: Identity & Back Navigation
          SliverAppBar(
            expandedHeight: 150, pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ultraViolet, size: 30),
              onPressed: () => Navigator.pushReplacementNamed(context, '/profile_selector'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
              title: Text("Hi, ${child.name}!", 
                style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 24)),
              background: Container(color: Colors.white),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20, top: 10),
                child: CircleAvatar(
                  radius: 30, 
                  backgroundColor: badgeColor,
                  child: Text(child.profileEmoji, style: const TextStyle(fontSize: 30)),
                ),
              ),
            ],
          ),

          // 2. THE AI TUTOR BUDDY (MASCOT BOX)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.childYellow.withAlpha(40),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Image.asset(child.avatarUrl, height: 100), // Choosen Mascot
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("I am your AI Buddy!", 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Text("Pick a world and let's explore!", style: TextStyle(fontSize: 14)),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => voice.speak("I am here to help you learn and have fun!", child.language),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.ultraViolet),
                          child: const Text("Talk to me", style: TextStyle(color: Colors.white)),
                        )
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_rounded, color: Colors.grey),
                    onPressed: () => _openParentLock(context),
                  ),
                ],
              ),
            ),
          ),

          // 3. REAL-TIME CATEGORY GRID (Integrated with Admin Content)
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: db.streamCategories(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
              }
              
              final categories = snapshot.data ?? [];

              if (categories.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 50),
                    child: Center(child: Text("The AI Buddy is setting up your folders!")),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 20, mainAxisSpacing: 20, childAspectRatio: 0.9
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildCategoryCard(context, categories[index], index, voice),
                    childCount: categories.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Map<String, dynamic> catData, int index, VoiceService voice) {
    String name = catData['name'] ?? "Adventure";
    Color cardColor = _getRainbowColor(index);

    return InkWell(
      onTap: () {
        voice.speak("Let's go to $name!", child.language);
        
        // Navigation Logic based on Category Name
        if (name.toLowerCase().contains("alpha") || name.toLowerCase().contains("num")) {
          Navigator.push(context, MaterialPageRoute(
            builder: (c) => LearningMapScreen(child: child, category: name)
          ));
        } else {
          Navigator.push(context, MaterialPageRoute(
            builder: (c) => ResourceGridScreen(child: child, category: name)
          ));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(color: cardColor.withAlpha(20), blurRadius: 20, offset: const Offset(0, 10))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: cardColor.withAlpha(30), shape: BoxShape.circle),
              child: Icon(_getCategoryIcon(name), size: 40, color: cardColor),
            ),
            const SizedBox(height: 15),
            Text(name, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark)),
          ],
        ),
      ),
    );
  }
}