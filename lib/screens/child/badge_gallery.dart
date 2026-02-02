import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../models/child_model.dart';
import '../../utils/app_colors.dart';

class BadgeGalleryScreen extends StatelessWidget {
  final ChildProfile child;
  const BadgeGalleryScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // List of possible badges in your app
    final List<Map<String, String>> allBadges = [
      {'id': 'Alphabets', 'name': 'Alphabet Explorer', 'icon': 'assets/icons/category/c1.png'},
      {'id': 'Numbers', 'name': 'Math Wizard', 'icon': 'assets/icons/category/c2.png'},
      {'id': 'General Knowledge', 'name': 'Super Scholar', 'icon': 'assets/icons/category/c3.png'},
      {'id': 'Shapes', 'name': 'Shape Master', 'icon': 'assets/icons/category/c4.png'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        title: const Text("My Achievements"),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.childNavy,
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(25),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, mainAxisSpacing: 20, crossAxisSpacing: 20, childAspectRatio: 0.8
        ),
        itemCount: allBadges.length,
        itemBuilder: (context, index) {
          final badge = allBadges[index];
          bool isEarned = child.badges.contains(badge['id']);

          return FadeInUp(
            delay: Duration(milliseconds: index * 100),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                border: isEarned ? Border.all(color: AppColors.childYellow, width: 3) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Opacity(
                    opacity: isEarned ? 1.0 : 0.2,
                    child: Image.asset(badge['icon']!, height: 80, color: isEarned ? null : Colors.black),
                  ),
                  const SizedBox(height: 15),
                  Text(badge['name']!, 
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      color: isEarned ? AppColors.childNavy : Colors.grey,
                      fontSize: 14
                    )),
                  if (!isEarned) const Text("Locked", style: TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}