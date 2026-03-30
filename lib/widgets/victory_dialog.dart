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
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          // 1. MAIN WOODEN BOX
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 95, 20, 30),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF9E7),
              borderRadius: BorderRadius.circular(45),
              border: Border.all(color: const Color(0xFFB07D4D), width: 10),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "LEVEL ${levelName.toUpperCase()}",
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF7B5233)),
                ),
                const SizedBox(height: 15),

                // 2. STARS (Overflow Fixed with FittedBox)
                SizedBox(
                  width: double.infinity,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (index) {
                          bool isFilled = index < stars;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: BounceInDown(
                              delay: Duration(milliseconds: 200 * index),
                              child: Icon(
                                Icons.star_rounded,
                                size: index == 1 ? 95 : 75,
                                color: isFilled ? const Color(0xFFFFC107) : Colors.grey.shade300,
                                shadows: isFilled ? [const Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))] : [],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // 3. SCORE DISPLAY (Under 100)
                const Text("TOTAL POINTS", 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF7B5233))),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: score.toDouble()),
                      duration: const Duration(seconds: 2),
                      builder: (context, value, child) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 54, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                        );
                      },
                    ),
                    const Text(" / 100", 
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
                
                // Perfect Score Message
                if (score == 100)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: FadeIn(child: const Text("✨ PERFECT! ✨", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w900))),
                  ),

                const SizedBox(height: 35),

                // 4. BUTTONS
                Row(
                  children: [
                    Expanded(child: _pillBtn("REPLAY", const Color(0xFF3498DB), onReplay)),
                    const SizedBox(width: 15),
                    Expanded(child: _pillBtn("NEXT", const Color(0xFF76D72F), onNext)),
                  ],
                ),
              ],
            ),
          ),

          // 5. GREEN RIBBON
          Positioned(
            top: -35,
            child: ElasticInDown(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFF76D72F),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10)],
                ),
                child: const Text(
                  "COMPLETE",
                  style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 4),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
          ],
        ),
        child: Center(
          child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
        ),
      ),
    );
  }
}