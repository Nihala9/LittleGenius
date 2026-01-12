import 'package:flutter/material.dart';

class TracingView extends StatefulWidget {
  final String letter;
  final Function(bool) onComplete;

  const TracingView({super.key, required this.letter, required this.onComplete});

  @override
  State<TracingView> createState() => _TracingViewState();
}

class _TracingViewState extends State<TracingView> {
  List<Offset?> points = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Trace the Letter ${widget.letter}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.blueAccent, width: 4),
            borderRadius: BorderRadius.circular(20),
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
              painter: TracePainter(points: points, letter: widget.letter),
              size: Size.infinite,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: () => setState(() => points = []), child: const Text("Clear")),
            const SizedBox(width: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () => widget.onComplete(points.length > 50), // Simple check: did they draw enough?
              child: const Text("Done", style: TextStyle(color: Colors.white)),
            ),
          ],
        )
      ],
    );
  }
}

class TracePainter extends CustomPainter {
  final List<Offset?> points;
  final String letter;
  TracePainter({required this.points, required this.letter});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw Background Ghost Letter
    TextPainter textPainter = TextPainter(
      text: TextSpan(text: letter, style: TextStyle(fontSize: 250, color: Colors.grey.shade200, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - 80, size.height / 2 - 150));

    // Draw User Tracing
    Paint paint = Paint()
      ..color = Colors.blue
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}