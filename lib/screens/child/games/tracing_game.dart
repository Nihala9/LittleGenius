import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

class TracingGame extends StatefulWidget {
  final Function(bool) onComplete;
  const TracingGame({super.key, required this.onComplete});

  @override
  State<TracingGame> createState() => _TracingGameState();
}

class _TracingGameState extends State<TracingGame> {
  List<Offset?> points = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(30.0),
          child: Text("Trace the Letter!", 
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.lavender, width: 4),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 20)],
            ),
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  RenderBox renderBox = context.findRenderObject() as RenderBox;
                  points.add(renderBox.globalToLocal(details.globalPosition));
                });
              },
              onPanEnd: (details) => points.add(null),
              child: CustomPaint(
                painter: TracingPainter(points: points),
                size: Size.infinite,
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            OutlinedButton.icon(
              onPressed: () => setState(() => points = []), 
              icon: const Icon(Icons.refresh), 
              label: const Text("Clear"),
              style: OutlinedButton.styleFrom(minimumSize: const Size(120, 50)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal, 
                minimumSize: const Size(160, 50)
              ),
              onPressed: () => widget.onComplete(points.length > 30),
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text("I'm Done!", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 50),
      ],
    );
  }
}

class TracingPainter extends CustomPainter {
  final List<Offset?> points;
  TracingPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    // CRITICAL FIX: Create a local copy to prevent PlatformDispatcher modification errors
    final pointsCopy = List<Offset?>.from(points);

    // 1. Draw Ghost Letter
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'A',
        style: TextStyle(fontSize: 280, color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(size.width / 2 - 90, size.height / 2 - 160));

    // 2. Draw User Path
    Paint paint = Paint()
      ..color = AppColors.primaryBlue
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 12.0;

    for (int i = 0; i < pointsCopy.length - 1; i++) {
      if (pointsCopy[i] != null && pointsCopy[i + 1] != null) {
        canvas.drawLine(pointsCopy[i]!, pointsCopy[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(TracingPainter oldDelegate) => true;
}