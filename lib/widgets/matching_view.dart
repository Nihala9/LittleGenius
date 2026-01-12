import 'package:flutter/material.dart';

class MatchingView extends StatelessWidget {
  final String letter;
  final Function(bool) onComplete;

  const MatchingView({super.key, required this.letter, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Which one starts with $letter?", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMatchItem(context, "🍎", "Apple", true),
            _buildMatchItem(context, "🍌", "Banana", false),
          ],
        ),
      ],
    );
  }

  Widget _buildMatchItem(BuildContext context, String emoji, String name, bool isCorrect) {
    return InkWell(
      onTap: () => onComplete(isCorrect),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 80)),
          Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}