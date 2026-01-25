import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

class MatchingGame extends StatefulWidget {
  final String conceptName; // e.g., "Letter A"
  final Function(bool) onComplete;

  const MatchingGame({super.key, required this.conceptName, required this.onComplete});

  @override
  State<MatchingGame> createState() => _MatchingGameState();
}

class _MatchingGameState extends State<MatchingGame> {
  bool _isMatched = false;

  // Simple mapping for the game visuals
  String _getEmoji() {
    if (widget.conceptName.contains('A')) return "🍎";
    if (widget.conceptName.contains('B')) return "🍌";
    if (widget.conceptName.contains('C')) return "🐱";
    return "🎁";
  }

  String _getLetter() {
    return widget.conceptName.split(' ').last; // Extracts 'A' from 'Letter A'
  }

  @override
  Widget build(BuildContext context) {
    String letter = _getLetter();
    String emoji = _getEmoji();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isMatched ? "Great Job!" : "Drag the $letter to the $emoji",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 50),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // THE DRAGGABLE LETTER
            _isMatched 
              ? const SizedBox(width: 100, height: 100) // Hide after match
              : Draggable<String>(
                  data: letter,
                  feedback: _buildLetterBox(letter, isDragging: true),
                  childWhenDragging: _buildLetterBox(letter, opacity: 0.3),
                  child: _buildLetterBox(letter),
                ),

            // THE TARGET OBJECT
            DragTarget<String>(
              onAcceptWithDetails: (details) {
                if (details.data == letter) {
                  setState(() => _isMatched = true);
                  Future.delayed(const Duration(milliseconds: 500), () {
                    widget.onComplete(true); // Signal AI that child succeeded
                  });
                }
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: _isMatched ? Colors.green.shade100 : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: candidateData.isNotEmpty ? AppColors.accentOrange : Colors.grey.shade300,
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _isMatched ? "✅" : emoji,
                      style: const TextStyle(fontSize: 60),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 50),
        if (!_isMatched)
          TextButton(
            onPressed: () => widget.onComplete(false), 
            child: const Text("I'm stuck, help me!", style: TextStyle(color: Colors.grey)),
          ),
      ],
    );
  }

  Widget _buildLetterBox(String text, {bool isDragging = false, double opacity = 1.0}) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.primaryBlue,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDragging ? [const BoxShadow(blurRadius: 20, color: Colors.black26)] : [],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(fontSize: 50, color: Colors.white, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
          ),
        ),
      ),
    );
  }
}