import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../models/concept_model.dart';
import '../../../utils/game_assets.dart';
import '../../../utils/app_colors.dart';

class MatchingActivity extends StatefulWidget {
  final Concept concept;
  final Function(bool) onComplete;

  const MatchingActivity({super.key, required this.concept, required this.onComplete});

  @override
  State<MatchingActivity> createState() => _MatchingActivityState();
}

class _MatchingActivityState extends State<MatchingActivity> with SingleTickerProviderStateMixin {
  late List<String> _options;
  bool _isMatched = false;
  bool _showTutorial = true;

  // Animation Controller for the "Ghost Hand"
  late AnimationController _tutorialController;
  late Animation<Offset> _handPath;
  late Animation<double> _handOpacity;

  @override
  void initState() {
    super.initState();
    _options = GameAssets.getDistractors(widget.concept.name);
    _options.add(widget.concept.name);
    _options.shuffle();

    // 1. Initialize Tutorial Controller (Moves every 3 seconds)
    _tutorialController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    // 2. Define the "Drag" Path (From choices area to target area)
    _handPath = Tween<Offset>(
      begin: const Offset(0, 180), // Position over the items
      end: const Offset(0, -100),   // Position over the box
    ).animate(CurvedAnimation(
      parent: _tutorialController, 
      curve: const Interval(0.0, 0.8, curve: Curves.easeInOut)
    ));

    // 3. Fade in/out logic
    _handOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20), // Show
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),          // Hold
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20), // Hide
    ]).animate(_tutorialController);
  }

  @override
  void dispose() {
    _tutorialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final correctItem = GameAssets.getConceptData(widget.concept.name)['item'];

    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Match them up!", 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.childNavy)),
            const SizedBox(height: 40),

            // --- 1. THE TARGET BOX ---
            DragTarget<String>(
              onAcceptWithDetails: (details) {
                if (details.data == widget.concept.name) {
                  setState(() { _isMatched = true; _showTutorial = false; });
                  widget.onComplete(true);
                } else {
                  widget.onComplete(false);
                }
              },
              builder: (context, candidate, rejected) {
                return Container(
                  width: 150, height: 150,
                  decoration: BoxDecoration(
                    color: _isMatched ? AppColors.childGreen.withOpacity(0.2) : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: _isMatched ? AppColors.childGreen : AppColors.childBlue, width: 4),
                  ),
                  child: Center(
                    child: Text(widget.concept.name, 
                      style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: AppColors.childBlue)),
                  ),
                );
              },
            ),

            const SizedBox(height: 80),

            // --- 2. THE CHOICES ---
            Wrap(
              spacing: 20,
              children: _options.map((opt) {
                final item = GameAssets.getConceptData(opt)['item'];
                return Draggable<String>(
                  data: opt,
                  onDragStarted: () => setState(() => _showTutorial = false),
                  feedback: _buildItemTile(item, isDragging: true),
                  childWhenDragging: Opacity(opacity: 0.2, child: _buildItemTile(item)),
                  child: _buildItemTile(item),
                );
              }).toList(),
            ),
          ],
        ),

        // --- 3. THE GHOST HAND (TUTORIAL LAYER) ---
        if (_showTutorial && !_isMatched)
          AnimatedBuilder(
            animation: _tutorialController,
            builder: (context, child) {
              return Opacity(
                opacity: _handOpacity.value,
                child: Transform.translate(
                  offset: _handPath.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Ghost of the item being moved
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white)
                        ),
                        child: Center(child: Text(correctItem, style: const TextStyle(fontSize: 30))),
                      ),
                      // The Hand Lottie
                      Lottie.asset('assets/animations/hand_gesture.json', height: 70),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildItemTile(String emoji, {bool isDragging = false}) {
    return Container(
      width: 85, height: 85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
      ),
      child: Center(child: Text(emoji, 
        style: TextStyle(fontSize: 45, decoration: isDragging ? TextDecoration.none : null))),
    );
  }
}