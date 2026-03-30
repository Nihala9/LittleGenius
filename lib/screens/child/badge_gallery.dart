import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:math';
import '../../models/child_model.dart';
import '../../models/concept_model.dart';
import '../../services/database_service.dart';
import '../../utils/app_colors.dart';
import '../parent/parent_dashboard.dart';
import 'stories/story_library_screen.dart'; // Corrected Import

class BadgeGalleryScreen extends StatefulWidget {
  final ChildProfile child;
  const BadgeGalleryScreen({super.key, required this.child});

  @override
  State<BadgeGalleryScreen> createState() => _BadgeGalleryScreenState();
}

class _BadgeGalleryScreenState extends State<BadgeGalleryScreen> {
  final DatabaseService _db = DatabaseService();
  final int _currentIndex = 2; // Badges is index 2 in our Magic Nav

  // --- LOCALIZATION HELPERS ---
  String _getTranslated(String key) {
    String lang = widget.child.language;
    Map<String, Map<String, String>> values = {
      'title': {
        'English': 'My Achievements',
        'Malayalam': 'എന്റെ നേട്ടങ്ങൾ',
        'Hindi': 'मेरी उपलब्धियां',
        'Arabic': 'إنجازاتي'
      },
      'levels': {
        'English': 'Levels',
        'Malayalam': 'ഘട്ടങ്ങൾ',
        'Hindi': 'स्तर',
        'Arabic': 'مستويات'
      },
      'unlocked': {
        'English': 'UNLOCKED',
        'Malayalam': 'നേടി കഴിഞ്ഞു',
        'Hindi': 'अनलॉक किया',
        'Arabic': 'تم الفتح'
      }
    };
    return values[key]?[lang] ?? values[key]?['English'] ?? '';
  }

  // --- PARENT LOCK FOR NAVIGATION ---
  void _openParentLock(ChildProfile liveChild) {
    final ctrl = TextEditingController();
    final Random rng = Random();
    int num1 = rng.nextInt(20) + 10;
    int num2 = rng.nextInt(15) + 5;
    int correctAnswer = num1 + num2;
    bool isAr = liveChild.language == "Arabic";

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Column(
          children: [
            const Icon(Icons.lock_person_rounded, color: AppColors.ultraViolet, size: 40),
            const SizedBox(height: 10),
            Text(isAr ? "للآباء فقط" : "Parents Only", 
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.ultraViolet)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isAr ? "قم بحل المسألة للدخول:" : "Solve this to enter:"),
            const SizedBox(height: 20),
            Text("$num1 + $num2 = ?", 
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.childBlue)),
            const SizedBox(height: 15),
            TextField(controller: ctrl, keyboardType: TextInputType.number, autofocus: true, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.ultraViolet, shape: const StadiumBorder()),
              onPressed: () {
                if (ctrl.text == correctAnswer.toString()) {
                  Navigator.pop(c);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ParentDashboard(specificChild: liveChild)));
                } else {
                  Navigator.pop(c);
                }
              }, 
              child: Text(isAr ? "فتح" : "Unlock")
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      extendBody: true,
      appBar: AppBar(
        title: Text(_getTranslated('title'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.childNavy,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<Concept>>(
        stream: _db.streamConcepts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final allConcepts = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(25, 20, 25, 120),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 25, crossAxisSpacing: 20, childAspectRatio: 0.75
            ),
            itemCount: badgeDefinitions.length,
            itemBuilder: (context, index) {
              final badge = badgeDefinitions[index];
              
              final categoryConceptIds = allConcepts.where((c) => c.category == badge['id']).map((c) => c.id).toList();

              int completedLevelsCount = 0;
              for (var id in categoryConceptIds) {
                if ((widget.child.masteryScores[id] ?? 0.0) >= 0.5) {
                  completedLevelsCount++;
                }
              }

              bool isEarned = completedLevelsCount >= 3;

              return FadeInUp(
                delay: Duration(milliseconds: index * 100),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(35),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15)],
                    border: isEarned ? Border.all(color: AppColors.childYellow, width: 3) : Border.all(color: Colors.grey.shade100, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Opacity(
                        opacity: isEarned ? 1.0 : 0.2,
                        child: Image.asset(badge['icon']!, height: 80),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(badge['name']!, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: isEarned ? AppColors.childNavy : Colors.grey, fontSize: 13)),
                      ),
                      const SizedBox(height: 10),
                      if (!isEarned) ...[
                        Column(
                          children: [
                            Text("$completedLevelsCount / 3 ${_getTranslated('levels')}", 
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.childBlue)),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(value: completedLevelsCount / 3, minHeight: 6, backgroundColor: Colors.grey.shade100, valueColor: const AlwaysStoppedAnimation(AppColors.childBlue)),
                              ),
                            )
                          ],
                        )
                      ] else ...[
                        Text(_getTranslated('unlocked'), style: const TextStyle(color: AppColors.childGreen, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ]
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: _buildMagicNav(widget.child),
    );
  }

  // --- MAGIC NAVIGATION BAR ---
  Widget _buildMagicNav(ChildProfile liveChild) {
    String lang = liveChild.language;
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 25),
      child: Container(
        height: 75,
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(35),
          boxShadow: [BoxShadow(color: AppColors.childBlue.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _magicNavItem(0, Icons.home_rounded, lang == "Arabic" ? "الرئيسية" : "Home", liveChild),
            _magicNavItem(1, Icons.auto_stories_rounded, lang == "Arabic" ? "قصص" : "Stories", liveChild),
            _magicNavItem(2, Icons.star_rounded, lang == "Arabic" ? "الأوسمة" : "Badges", liveChild),
            _magicNavItem(3, Icons.lock_rounded, lang == "Arabic" ? "الآباء" : "Parents", liveChild),
          ],
        ),
      ),
    );
  }

  Widget _magicNavItem(int index, IconData icon, String label, ChildProfile liveChild) {
    bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (index == 0) {
          Navigator.pop(context);
        } else if (index == 1) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => StoryLibraryScreen(child: liveChild)));
        } else if (index == 3) {
          _openParentLock(liveChild);
        } else if (index == 2) {
          return; // Already on Badges
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isActive ? BoxDecoration(color: AppColors.childBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isActive 
              ? Bounce(duration: const Duration(milliseconds: 500), child: Icon(icon, color: AppColors.childBlue, size: 26))
              : Icon(icon, color: Colors.grey.shade400, size: 24),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isActive ? AppColors.childBlue : Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }
}