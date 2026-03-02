import 'package:flutter/material.dart';

class LineMatchingPainter extends CustomPainter {
  final List<dynamic> completedLines; 
  final Offset? currentStart;
  final Offset? currentEnd;
  final Color activeColor;

  LineMatchingPainter({
    required this.completedLines,
    this.currentStart,
    this.currentEnd,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (currentStart == null || currentEnd == null) return;

    final paint = Paint()
      ..color = activeColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;

    final glowPaint = Paint()
      ..color = activeColor.withOpacity(0.2)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16.0;

    // Draw lines
    canvas.drawLine(currentStart!, currentEnd!, glowPaint);
    canvas.drawLine(currentStart!, currentEnd!, paint);

    // Draw endpoint dot
    canvas.drawCircle(currentEnd!, 10, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(LineMatchingPainter oldDelegate) => true;
}