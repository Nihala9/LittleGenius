import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/game_assets.dart';
import '../../../models/concept_model.dart';

class MatchingActivity extends StatefulWidget {
  final Concept concept;
  final Function(bool) onComplete;

  const MatchingActivity({super.key, required this.concept, required this.onComplete});

  @override
  State<MatchingActivity> createState() => _MatchingActivityState();
}

class _MatchingActivityState extends State<MatchingActivity> {
  bool isMatched = false;

  @override
  Widget build(BuildContext context) {
    final data = GameAssets.getConceptData(widget.concept.name);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Match the Pair!", 
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.childNavy)),
        const SizedBox(height: 60),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 1. DRAGGABLE ITEM (The Emoji/Image)
            if (!isMatched)
              Draggable<String>(
                data: widget.concept.name,
                feedback: _buildSquare(data['item'], AppColors.childPink, isFloating: true),
                childWhenDragging: _buildSquare("", Colors.grey.shade200),
                child: BounceInDown(child: _buildSquare(data['item'], AppColors.childPink)),
              )
            else
              const SizedBox(width: 120, height: 120), // Placeholder when done

            // 2. TARGET (The Letter/Word)
            DragTarget<String>(
              onAcceptWithDetails: (details) {
                if (details.data == widget.concept.name) {
                  setState(() => isMatched = true);
                  widget.onComplete(true);
                } else {
                  widget.onComplete(false);
                }
              },
              builder: (context, candidateData, rejectedData) {
                return _buildSquare(
                  widget.concept.name, 
                  isMatched ? AppColors.childGreen : AppColors.childBlue,
                  label: isMatched ? "Matched!" : "Drop Here"
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSquare(String content, Color color, {bool isFloating = false, String? label}) {
    return Container(
      width: 120, height: 120,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
        boxShadow: isFloating ? [BoxShadow(color: Colors.black26, blurRadius: 20)] : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(content, style: const TextStyle(fontSize: 50)),
          if (label != null) Text(label, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}