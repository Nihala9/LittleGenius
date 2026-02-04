import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/game_assets.dart';

class PuzzleActivity extends StatefulWidget {
  final String itemName; // e.g., "A" or "🍎"
  final Function(bool) onComplete;

  const PuzzleActivity({super.key, required this.itemName, required this.onComplete});

  @override
  State<PuzzleActivity> createState() => _PuzzleActivityState();
}

class _PuzzleActivityState extends State<PuzzleActivity> {
  bool _isSolved = false;
  late List<String> _choices;

  @override
  void initState() {
    super.initState();
    // Get the target and 2 distractors (logical comparison)
    _choices = GameAssets.getDistractors(widget.itemName);
    _choices.add(widget.itemName);
    _choices.shuffle();
  }

  @override
  Widget build(BuildContext context) {
    final targetData = GameAssets.getConceptData(widget.itemName);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 1. HEADER (RV AppStudios Style)
        FadeInDown(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.childYellow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              "SHAPE MATCH",
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.w900, 
                color: AppColors.childOrange,
                letterSpacing: 1.5
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 50),

        // 2. THE SILHOUETTE TARGET (The "Shadow" to fill)
        DragTarget<String>(
          onAcceptWithDetails: (details) {
            if (details.data == widget.itemName) {
              setState(() => _isSolved = true);
              widget.onComplete(true);
            } else {
              widget.onComplete(false);
            }
          },
          builder: (context, candidate, rejected) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 200, height: 200,
              decoration: BoxDecoration(
                color: _isSolved ? Colors.white : Colors.grey.shade200,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isSolved ? AppColors.childGreen : Colors.white, 
                  width: 5
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05), 
                    blurRadius: 20, 
                    spreadRadius: 5
                  )
                ],
              ),
              child: Center(
                child: _isSolved
                    ? ElasticIn(
                        child: Text(targetData['item'], style: const TextStyle(fontSize: 120)),
                      )
                    : Opacity(
                        opacity: 0.15, // The Silhouette Effect
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                          child: Text(targetData['item'], style: const TextStyle(fontSize: 120)),
                        ),
                      ),
              ),
            );
          },
        ),

        const SizedBox(height: 80),

        // 3. THE CHOICE TRAY (Colorful Pieces)
        if (!_isSolved)
          FadeInUp(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _choices.map((choice) {
                final choiceData = GameAssets.getConceptData(choice);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Draggable<String>(
                    data: choice,
                    feedback: Material(
                      color: Colors.transparent,
                      child: _buildChoicePiece(choiceData['item'], isFeedback: true),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.2, 
                      child: _buildChoicePiece(choiceData['item'])
                    ),
                    child: Bounce(
                      infinite: true,
                      duration: const Duration(seconds: 2),
                      child: _buildChoicePiece(choiceData['item']),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        
        const SizedBox(height: 40),
        if (!_isSolved)
          const Text(
            "Find the matching shape!",
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.w600, 
              color: Colors.blueGrey
            ),
          ),
      ],
    );
  }

  // Helper to build the draggable colorful pieces
  Widget _buildChoicePiece(String emoji, {bool isFeedback = false}) {
    return Container(
      width: 90, height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), 
            blurRadius: 10, 
            offset: const Offset(0, 5)
          )
        ],
        border: Border.all(color: Colors.grey.shade100, width: 2),
      ),
      child: Center(
        child: Text(
          emoji, 
          style: TextStyle(
            fontSize: 50, 
            decoration: isFeedback ? TextDecoration.none : null
          )
        ),
      ),
    );
  }
}