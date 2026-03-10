import 'package:flutter/material.dart';

class FinishedStroke {
  final List<Offset?> points;
  final Color color;
  FinishedStroke(this.points, this.color);
}

class WorkbookPainter extends CustomPainter {
  final List<FinishedStroke> completed;
  final List<Offset?> current;
  final Color activeColor;
  final String letter;

  WorkbookPainter({
    required this.completed,
    required this.current,
    required this.activeColor,
    required this.letter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 30);

    // 1. DRAW THE HOLLOW BUBBLE CHARACTER
    TextPainter tp = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontSize: 340, 
          fontWeight: FontWeight.w900,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 14
            ..color = Colors.black.withValues(alpha: 0.8),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    Offset pos = Offset(center.dx - tp.width / 2, center.dy - tp.height / 2);
    tp.paint(canvas, pos); // Black Outline
    
    tp.text = TextSpan(
      text: letter, 
      style: const TextStyle(fontSize: 340, fontWeight: FontWeight.w900, color: Colors.white)
    );
    tp.layout(); tp.paint(canvas, pos); // White Fill Layer

    // 2. DRAW USER INK (Magic Marker Look)
    Paint ink = Paint()..strokeCap = StrokeCap.round..strokeWidth = 28.0;
    
    // Draw previous completed strokes
    for (var s in completed) {
      ink.color = s.color.withValues(alpha: 0.6);
      for (int i = 0; i < s.points.length - 1; i++) {
        if (s.points[i] != null && s.points[i+1] != null) {
          canvas.drawLine(s.points[i]!, s.points[i+1]!, ink);
        }
      }
    }
    
    // Draw active stroke
    ink.color = activeColor;
    for (int i = 0; i < current.length - 1; i++) {
      if (current[i] != null && current[i+1] != null) {
        canvas.drawLine(current[i]!, current[i+1]!, ink);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}