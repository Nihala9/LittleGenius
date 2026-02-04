import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../utils/app_colors.dart';

class TracingActivity extends StatefulWidget {
  final String targetLetter; 
  final Function(bool) onComplete;

  const TracingActivity({super.key, required this.targetLetter, required this.onComplete});

  @override
  State<TracingActivity> createState() => _TracingActivityState();
}

class _TracingActivityState extends State<TracingActivity> with SingleTickerProviderStateMixin {
  List<Offset?> points = [];
  bool showTutorial = false;
  Timer? _idleTimer;
  
  late AnimationController _tutorialController;
  late Animation<double> _tutorialAnimation;

  @override
  void initState() {
    super.initState();
    _setupTutorial();
    _startIdleTimer();
  }

  void _setupTutorial() {
    _tutorialController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _tutorialAnimation = Tween<double>(begin: 0, end: 1).animate(_tutorialController);
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && points.isEmpty) setState(() => showTutorial = true);
    });
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _tutorialController.dispose();
    super.dispose();
  }

  // --- TRACING VALIDATION: SHAPE RECOGNITION ---
  void _evaluateTracing() {
    final validPoints = points.whereType<Offset>().toList();
    if (validPoints.length < 20) {
      widget.onComplete(false);
      return;
    }

    // 1. Calculate Bounding Box
    double minX = 300, maxX = 0, minY = 400, maxY = 0;
    for (var p in validPoints) {
      if (p.dx < minX) minX = p.dx; if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy; if (p.dy > maxY) maxY = p.dy;
    }

    double width = maxX - minX;
    double height = maxY - minY;

    // 2. SHAPE CHECK (Example for 'A')
    // A scribbler might draw a small circle (width == height)
    // An 'A' is taller than it is wide and covers specific area
    bool isTallerThanWide = height > (width * 1.2);
    bool coversEnoughArea = (width > 80 && height > 130);

    // 3. MID-POINT CHECK (Did they cross the middle of the 'A'?)
    bool crossedMiddle = validPoints.any((p) => p.dy > 180 && p.dy < 220);

    if (isTallerThanWide && coversEnoughArea && crossedMiddle) {
      widget.onComplete(true);
    } else {
      setState(() => points.clear());
      widget.onComplete(false); 
    }
  }

  @override
  Widget build(BuildContext context) {
    String letter = widget.targetLetter.substring(0, 1).toUpperCase();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FadeInDown(child: Text("Trace the '$letter'", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.childNavy))),
        const SizedBox(height: 30),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 300, height: 400,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), border: Border.all(color: AppColors.childBlue.withOpacity(0.15), width: 4)),
              child: Builder(builder: (canvasContext) {
                return GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      showTutorial = false;
                      _idleTimer?.cancel();
                      final RenderBox box = canvasContext.findRenderObject() as RenderBox;
                      final Offset localPos = box.globalToLocal(details.globalPosition);
                      if (localPos.dx >= 0 && localPos.dx <= 300 && localPos.dy >= 0 && localPos.dy <= 400) {
                        points.add(localPos);
                      }
                    });
                  },
                  onPanEnd: (details) {
                    points.add(null);
                    _evaluateTracing();
                  },
                  child: CustomPaint(painter: TracingPainter(points: points, letter: letter), size: const Size(300, 400)),
                );
              }),
            ),
            if (showTutorial) IgnorePointer(child: AnimatedBuilder(animation: _tutorialAnimation, builder: (context, child) {
              return CustomPaint(painter: TutorialPathPainter(progress: _tutorialAnimation.value, letter: letter), size: const Size(300, 400));
            })),
          ],
        ),
        const SizedBox(height: 30),
        IconButton(icon: const Icon(Icons.refresh_rounded, size: 40, color: Colors.grey), onPressed: () => setState(() => points.clear())),
      ],
    );
  }
}

class TracingPainter extends CustomPainter {
  final List<Offset?> points;
  final String letter;
  TracingPainter({required this.points, required this.letter});

  @override
  void paint(Canvas canvas, Size size) {
    TextPainter textPainter = TextPainter(text: TextSpan(text: letter, style: TextStyle(fontSize: 340, color: Colors.grey.shade100, fontWeight: FontWeight.w900)), textDirection: TextDirection.ltr)..layout();
    textPainter.paint(canvas, Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2));

    Paint paint = Paint()..color = AppColors.childBlue..strokeCap = StrokeCap.round..strokeWidth = 20.0;
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) canvas.drawLine(points[i]!, points[i + 1]!, paint);
    }
  }
  @override bool shouldRepaint(TracingPainter old) => true;
}

class TutorialPathPainter extends CustomPainter {
  final double progress;
  final String letter; 
  TutorialPathPainter({required this.progress, required this.letter});

  @override
  void paint(Canvas canvas, Size size) {
    Paint dotPaint = Paint()..color = AppColors.childPink;
    Paint glowPaint = Paint()..color = AppColors.childPink.withOpacity(0.3);
    
    Offset pos;
    // Logic for Letter 'A' (Triangular movement)
    if (progress < 0.4) { // Left down
      pos = Offset(size.width * 0.5 - (size.width * 0.3 * (progress / 0.4)), size.height * 0.2 + (size.height * 0.6 * (progress / 0.4)));
    } else if (progress < 0.8) { // Right down
      double p2 = (progress - 0.4) / 0.4;
      pos = Offset(size.width * 0.5 + (size.width * 0.3 * p2), size.height * 0.2 + (size.height * 0.6 * p2));
    } else { // Cross bar
      double p3 = (progress - 0.8) / 0.2;
      pos = Offset(size.width * 0.35 + (size.width * 0.3 * p3), size.height * 0.6);
    }

    canvas.drawCircle(pos, 15, glowPaint); 
    canvas.drawCircle(pos, 8, dotPaint); 
  }
  @override bool shouldRepaint(TutorialPathPainter old) => true;
}