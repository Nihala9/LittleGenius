import 'package:flutter/material.dart';
import '../../services/voice_service.dart';
import '../../utils/app_colors.dart';

class SleepModeScreen extends StatelessWidget {
  final String language;
  final VoidCallback onUnlock;
  const SleepModeScreen({super.key, required this.language, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    VoiceService().speak("Time to rest your eyes! See you tomorrow.", language);

    return Container(
      color: AppColors.childNavy.withOpacity(0.95),
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.nightlight_round, size: 100, color: Colors.amberAccent),
          const SizedBox(height: 30),
          const Text("Time for a break!", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
          const Padding(
            padding: EdgeInsets.all(30.0),
            child: Text("You did a great job today. Let's sleep now!", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 18, decoration: TextDecoration.none)),
          ),
          ElevatedButton(onPressed: onUnlock, child: const Text("Parent Settings")),
        ],
      ),
    );
  }
}