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
    // Logic: Get the target and 2 distractors
    _choices = GameAssets.getDistractors(widget.itemName);
    _choices.add(widget.itemName);
    _choices.shuffle();
  }

  @override
  Widget build(BuildContext context) {
    final targetData = GameAssets.getConceptData(widget.itemName);

    return SingleChildScrollView( // Added safety for small screens
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. HEADER
          FadeInDown(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.childYellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                "SHAPE MATCH",
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.w900, 
                  color: AppColors.childOrange,
                  letterSpacing: 1.2
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 40),
    
          // 2. THE SILHOUETTE TARGET
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
                width: 180, height: 180,
                decoration: BoxDecoration(
                  color: _isSolved ? Colors.white : Colors.grey.shade200,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isSolved ? AppColors.childGreen : Colors.white, 
                    width: 5
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)
                  ],
                ),
                child: Center(
                  child: _isSolved
                      ? ElasticIn(
                          child: Text(targetData['item'], style: const TextStyle(fontSize: 100)),
                        )
                      : Opacity(
                          opacity: 0.15,
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                            child: Text(targetData['item'], style: const TextStyle(fontSize: 100)),
                          ),
                        ),
                ),
              );
            },
          ),
    
          const SizedBox(height: 60),
    
          // 3. THE CHOICE TRAY (FIXED: Row changed to Wrap to prevent overflow)
          if (!_isSolved)
            FadeInUp(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 15, // Horizontal space between items
                  runSpacing: 15, // Vertical space if they wrap to a new line
                  children: _choices.map((choice) {
                    final choiceData = GameAssets.getConceptData(choice);
                    return Draggable<String>(
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
                    );
                  }).toList(),
                ),
              ),
            ),
          
          const SizedBox(height: 30),
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
      ),
    );
  }

  // Helper to build the draggable colorful pieces
  Widget _buildChoicePiece(String emoji, {bool isFeedback = false}) {
    return Container(
      width: 85, height: 85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))
        ],
        border: Border.all(color: Colors.grey.shade100, width: 2),
      ),
      child: Center(
        child: Text(
          emoji, 
          style: TextStyle(
            fontSize: 45, 
            decoration: isFeedback ? TextDecoration.none : null
          )
        ),
      ),
    );
  }
}