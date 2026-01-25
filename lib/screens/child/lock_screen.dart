import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class ChildLockScreen extends StatelessWidget {
  const ChildLockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bedtime, size: 120, color: Colors.white),
            const SizedBox(height: 30),
            const Text("Time for a break!", 
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
            const Padding(
              padding: EdgeInsets.all(30.0),
              child: Text(
                "You've learned so much today! Let's play again tomorrow.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
            ),
            const SizedBox(height: 50),
            // Only a Parent knows how to exit this (e.g., another Parent Lock)
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("Parental Unlock", style: TextStyle(color: Colors.white54)),
            )
          ],
        ),
      ),
    );
  }
}