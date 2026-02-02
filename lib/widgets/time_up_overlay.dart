import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class TimeUpOverlay extends StatelessWidget {
  final VoidCallback onParentUnlock;
  const TimeUpOverlay({super.key, required this.onParentUnlock});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.childNavy.withOpacity(0.95),
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.nightlight_round, size: 100, color: Colors.amberAccent),
          const SizedBox(height: 30),
          const Text("Time for a break!", 
            style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const Padding(
            padding: EdgeInsets.all(30.0),
            child: Text("You've done a great job learning today. Let's rest our eyes and play more tomorrow!", 
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 18)),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onParentUnlock,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.childBlue),
            child: const Text("Parent Unlock", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}