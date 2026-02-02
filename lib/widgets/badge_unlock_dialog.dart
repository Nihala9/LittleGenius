import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../utils/app_colors.dart';

class BadgeUnlockDialog extends StatelessWidget {
  final String badgeName;
  final String badgeIcon; // e.g., 'assets/icons/badges/b1.png'

  const BadgeUnlockDialog({super.key, required this.badgeName, required this.badgeIcon});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("NEW BADGE UNLOCKED!", 
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.childPink)),
            const SizedBox(height: 20),
            ZoomIn(
              child: Image.asset(badgeIcon, height: 150),
            ),
            const SizedBox(height: 20),
            Text(badgeName, 
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.childNavy)),
            const SizedBox(height: 10),
            const Text("You are doing amazing!", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.childBlue, shape: const StadiumBorder()),
              onPressed: () => Navigator.pop(context), 
              child: const Text("Awesome!", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}