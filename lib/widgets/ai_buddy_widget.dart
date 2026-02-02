import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

enum BuddyState { idle, happy, thinking, waving }

class AIBuddyWidget extends StatelessWidget {
  final BuddyState state;
  final double height;

  const AIBuddyWidget({super.key, this.state = BuddyState.idle, this.height = 150});

  @override
  Widget build(BuildContext context) {
    String animationPath;
    
    switch (state) {
      case BuddyState.happy:
        animationPath = 'assets/animations/buddy_happy.json';
        break;
      case BuddyState.thinking:
        animationPath = 'assets/animations/buddy_think.json';
        break;
      case BuddyState.waving:
        animationPath = 'assets/animations/buddy_wave.json';
        break;
      default:
        animationPath = 'assets/animations/buddy_idle.json';
    }

    return Lottie.asset(
      animationPath,
      height: height,
      fit: BoxFit.contain,
    );
  }
}