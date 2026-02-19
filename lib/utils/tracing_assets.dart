import 'package:flutter/material.dart';

class TracingAssets {
  static List<List<Offset>> getStrokes(String char) {
    switch (char.toUpperCase()) {
      case 'A':
        return [
          [const Offset(80, 320), const Offset(115, 200), const Offset(150, 80)],  // Stroke 1
          [const Offset(150, 80), const Offset(185, 200), const Offset(220, 320)], // Stroke 2
          [const Offset(110, 220), const Offset(190, 220)],                        // Stroke 3
        ];
      case 'B':
        return [
          [const Offset(100, 80), const Offset(100, 200), const Offset(100, 320)], // Vertical line
          [const Offset(100, 80), const Offset(180, 100), const Offset(100, 150)], // Top hump
          [const Offset(100, 150), const Offset(200, 230), const Offset(100, 320)],// Bottom hump
        ];
      case 'C':
        return [
          [const Offset(220, 120), const Offset(150, 80), const Offset(80, 200), const Offset(150, 320), const Offset(220, 280)],
        ];
      case '1':
        return [
          [const Offset(150, 80), const Offset(150, 200), const Offset(150, 320)],
        ];
      default: // Default to a simple square path if unknown
        return [[const Offset(100, 100), const Offset(200, 100), const Offset(200, 200), const Offset(100, 200)]];
    }
  }
}