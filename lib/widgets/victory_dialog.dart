import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class VictoryDialog extends StatelessWidget {
  final String levelName;
  final int stars;
  final int score;
  final VoidCallback onNext;
  final VoidCallback onReplay;

  const VictoryDialog({
    super.key,
    required this.levelName,
    required this.stars,
    required this.score,
    required this.onNext,
    required this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300), // Strict outer limit
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            // 1. THE WOODEN BOX
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(15, 80, 15, 20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF9E7),
                borderRadius: BorderRadius.circular(45),
                border: Border.all(color: const Color(0xFFB07D4D), width: 10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- LEVEL NAME ---
                  Text(
                    "LEVEL ${levelName.toUpperCase()}",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF7B5233),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // --- STARS ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      bool isFilled = index < stars;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: BounceInDown(
                          delay: Duration(milliseconds: 150 * index),
                          child: Icon(
                            Icons.star_rounded,
                            size: index == 1 ? 80 : 60,
                            color: isFilled ? const Color(0xFFFFC107) : Colors.grey.shade300,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // --- THE SCORE SECTION ---
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: score.toDouble()),
                    duration: const Duration(seconds: 2),
                    builder: (context, value, child) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "TOTAL POINTS",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF7B5233),
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: value.toInt().toString(),
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                const TextSpan(
                                  text: " / 100",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    },
                  ),
                  
                  const SizedBox(height: 25),

                  // --- BUTTONS ---
                  Row(
                    children: [
                      Expanded(
                        child: _buildButton("REPLAY", const Color(0xFF3498DB), onReplay),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildButton("NEXT", const Color(0xFF76D72F), onNext),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. THE TOP GREEN RIBBON
            Positioned(
              top: -30,
              child: ElasticInDown(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF76D72F),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 10)],
                  ),
                  child: const Text(
                    "COMPLETE",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for buttons to ensure they also don't overflow
  Widget _buildButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 4),
        ),
        child: Center(
          child: FittedBox(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}