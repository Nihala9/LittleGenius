import 'package:flutter/material.dart';

class TracingAssets {
  static List<List<Offset>> getStrokes(String char) {
    // Math logic: centerX = 160, centerY = 210
    switch (char.toUpperCase()) {
      case 'A':
        return [
          [const Offset(160, 80), const Offset(120, 200), const Offset(80, 320)],  // 1. Left Leg
          [const Offset(160, 80), const Offset(200, 200), const Offset(240, 320)], // 2. Right Leg
          [const Offset(110, 220), const Offset(210, 220)],                        // 3. Crossbar
        ];
      case 'B':
        return [
          [const Offset(110, 80), const Offset(110, 320)], // 1. Spine
          [const Offset(110, 80), const Offset(180, 80), const Offset(210, 120), const Offset(180, 160), const Offset(110, 160)], // 2. Top
          [const Offset(110, 160), const Offset(200, 160), const Offset(230, 240), const Offset(200, 320), const Offset(110, 320)], // 3. Bottom
        ];
      case '1':
        return [
          [const Offset(120, 130), const Offset(160, 80)], // 1. Beak
          [const Offset(160, 80), const Offset(160, 320)], // 2. Body
        ];
      default:
        return [[const Offset(160, 80), const Offset(160, 320)]];
    }
  }
}