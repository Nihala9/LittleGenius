import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

class TracingActivity extends StatefulWidget {
  final String targetLetter;
  final Function(bool) onComplete;

  const TracingActivity({super.key, required this.targetLetter, required this.onComplete});

  @override
  State<TracingActivity> createState() => _TracingActivityState();
}

class _TracingActivityState extends State<TracingActivity> {
  List<Offset?> points = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Trace the Letter", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Container(
          width: 300, height: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.childBlue, width: 2),
          ),
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                RenderBox renderBox = context.findRenderObject() as RenderBox;
                points.add(renderBox.globalToLocal(details.globalPosition));
              });
            },
            onPanEnd: (details) {
              points.add(null);
              // Basic logic: If they drew something, count as success for now
              if (points.length > 20) widget.onComplete(true);
            },
            child: CustomPaint(
              painter: TracingPainter(points: points, letter: widget.targetLetter[0]),
              size: Size.infinite,
            ),
          ),
        ),
        const SizedBox(height: 20),
        IconButton(
          icon: const Icon(Icons.refresh, size: 40, color: Colors.grey),
          onPressed: () => setState(() => points.clear()),
        )
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
    // 1. Draw Background Guide Letter
    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(fontSize: 250, color: Colors.grey.shade200, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - 80, size.height / 2 - 150));

    // 2. Draw Child's Finger Strokes
    Paint paint = Paint()
      ..color = AppColors.childBlue
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 12.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(TracingPainter oldDelegate) => true;
}