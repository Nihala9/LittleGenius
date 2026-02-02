import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart'; // Ensure this is in pubspec.yaml
import '../../../utils/app_colors.dart';
import '../../../services/sound_service.dart';

class PuzzleActivity extends StatefulWidget {
  final String itemName; // e.g., "🍎"
  final Function(bool) onComplete;

  const PuzzleActivity({super.key, required this.itemName, required this.onComplete});

  @override
  State<PuzzleActivity> createState() => _PuzzleActivityState();
}

class _PuzzleActivityState extends State<PuzzleActivity> {
  bool _isSolved = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Title animation
        FadeInDown(
          child: const Text(
            "Fix the Picture!", 
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.childNavy)
          ),
        ),
        const SizedBox(height: 60),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- 1. THE TARGET SLOT ---
            DragTarget<String>(
              onAcceptWithDetails: (details) {
                if (details.data == "piece") {
                  SoundService.playSFX('success.mp3');
                  setState(() => _isSolved = true);
                  widget.onComplete(true);
                }
              },
              builder: (context, candidate, rejected) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 160, height: 160,
                  decoration: BoxDecoration(
                    color: _isSolved ? Colors.transparent : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: _isSolved ? AppColors.childGreen : Colors.grey.shade300, 
                      width: 4,
                    ),
                  ),
                  child: Center(
                    child: _isSolved 
                      ? ElasticIn( // FIXED: Using ElasticIn for a great success feel
                          duration: const Duration(milliseconds: 1000),
                          child: Text(
                            widget.itemName, 
                            style: const TextStyle(fontSize: 100)
                          ),
                        )
                      : Text(
                          widget.itemName, 
                          style: TextStyle(
                            fontSize: 100, 
                            color: AppColors.childNavy.withOpacity(0.1) // Corrected Opacity
                          ),
                        ),
                  ),
                );
              },
            ),
            
            const SizedBox(width: 50),

            // --- 2. THE DRAGGABLE PIECE ---
            SizedBox(
              width: 120,
              height: 120,
              child: !_isSolved 
                ? Draggable<String>(
                    data: "piece",
                    feedback: Material(
                      color: Colors.transparent,
                      child: Text(
                        widget.itemName, 
                        style: const TextStyle(fontSize: 110, decoration: TextDecoration.none)
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.2, 
                      child: Text(widget.itemName, style: const TextStyle(fontSize: 100))
                    ),
                    child: Bounce( // FIXED: Using Bounce for idle animation
                      infinite: true,
                      duration: const Duration(seconds: 2),
                      child: Text(
                        widget.itemName, 
                        style: const TextStyle(fontSize: 100)
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 40),
        if (!_isSolved)
          FadeIn(
            delay: const Duration(seconds: 1),
            child: const Text(
              "Drag the piece to the box!",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }
}