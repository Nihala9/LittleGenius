import 'package:flutter/material.dart';

class GameAssets {
  static final Map<String, Map<String, dynamic>> _library = {
    // --- ALPHABETS (Upper to Lower + Examples) ---
    'A': {'item': 'A', 'match': 'a', 'category': 'Alphabets', 'word': 'Apple', 'extra': '🐜', 'extraWord': 'Ant', 'color': Color(0xFF00BCD4)},
    'B': {'item': 'B', 'match': 'b', 'category': 'Alphabets', 'word': 'Ball', 'extra': '🎒', 'extraWord': 'Bag', 'color': Color(0xFFFF9800)},
    'C': {'item': 'C', 'match': 'c', 'category': 'Alphabets', 'word': 'Cat', 'extra': '🚗', 'extraWord': 'Car', 'color': Color(0xFF8BC34A)},
    'D': {'item': 'D', 'match': 'd', 'category': 'Alphabets', 'word': 'Dog', 'extra': '🍩', 'extraWord': 'Donut', 'color': Color(0xFFE91E63)},

    // --- NUMBERS (Number to Quantity) ---
    '1': {'item': '1', 'match': '🍎', 'category': 'Numbers', 'word': 'One', 'extra': '☝️', 'extraWord': 'Finger', 'color': Color(0xFF9C27B0)},
    '2': {'item': '2', 'match': '🍎🍎', 'category': 'Numbers', 'word': 'Two', 'extra': '✌️', 'extraWord': 'Fingers', 'color': Color(0xFFFFC107)},
    '3': {'item': '3', 'match': '🍎🍎🍎', 'category': 'Numbers', 'word': 'Three', 'extra': '🤟', 'extraWord': 'Fingers', 'color': Color(0xFF03A9F4)},

    // --- SHAPES (Shadow Matching) ---
    'Circle': {'item': '⭕', 'match': 'shadow', 'category': 'Shapes', 'word': 'Circle', 'extra': '🏀', 'extraWord': 'Ball', 'color': Color(0xFFFF5722)},
    'Square': {'item': '⬛', 'match': 'shadow', 'category': 'Shapes', 'word': 'Square', 'extra': '🎁', 'extraWord': 'Box', 'color': Color(0xFF3F51B5)},

    // --- ANIMALS (Shadow Matching) ---
    'Lion': {'item': '🦁', 'match': 'shadow', 'category': 'Animals', 'word': 'Lion', 'extra': '🥩', 'extraWord': 'Meat', 'color': Color(0xFF795548)},
    'Elephant': {'item': '🐘', 'match': 'shadow', 'category': 'Animals', 'word': 'Elephant', 'extra': '🌿', 'extraWord': 'Leaves', 'color': Color(0xFF607D8B)},
  };

  static Map<String, dynamic> getConceptData(String name) {
    String lookup = _library.keys.firstWhere(
      (k) => k.toLowerCase() == name.toLowerCase(),
      orElse: () => '',
    );
    return _library[lookup] ?? {
      'item': name, 
      'match': name,
      'category': 'General', 
      'word': name,
      'extra': '🌟',
      'extraWord': 'Star',
      'color': Colors.blue
    };
  }

  static List<String> getDistractors(String correctName, String category) {
    List<String> pool = _library.entries
        .where((e) => e.value['category'] == category && e.key.toLowerCase() != correctName.toLowerCase())
        .map((e) => e.key)
        .toList();

    if (pool.length < 2) {
      pool.addAll(_library.keys.where((k) => k.toLowerCase() != correctName.toLowerCase()));
    }

    pool.shuffle();
    return pool.take(2).toList(); 
  }
}
    // // --- ALPHABETS (Association: Upper to Lower) ---
    // 'A': {'item': 'A', 'match': 'a', 'category': 'Alphabets', 'word': 'Apple'},
    // 'B': {'item': 'B', 'match': 'b', 'category': 'Alphabets', 'word': 'Ball'},
    // 'C': {'item': 'C', 'match': 'c', 'category': 'Alphabets', 'word': 'Cat'},
    // 'D': {'item': 'D', 'match': 'd', 'category': 'Alphabets', 'word': 'Dog'},
    // 'E': {'item': 'E', 'match': 'e', 'category': 'Alphabets', 'word': 'Elephant'},

    // // --- NUMBERS (Association: Number to Dice/Quantity) ---
    // '1': {'item': '1', 'match': '🍎', 'category': 'Numbers', 'word': 'One'},
    // '2': {'item': '2', 'match': '🍎🍎', 'category': 'Numbers', 'word': 'Two'},
    // '3': {'item': '3', 'match': '🍎🍎🍎', 'category': 'Numbers', 'word': 'Three'},
    // '4': {'item': '4', 'match': '🍎🍎🍎🍎', 'category': 'Numbers', 'word': 'Four'},
    // '5': {'item': '5', 'match': '🍎🍎🍎🍎🍎', 'category': 'Numbers', 'word': 'Five'},

    // // --- SHAPES (Association: Shadow Matching) ---
    // 'Circle': {'item': '⭕', 'match': 'shadow', 'category': 'Shapes', 'word': 'Circle'},
    // 'Square': {'item': '⬛', 'match': 'shadow', 'category': 'Shapes', 'word': 'Square'},
    // 'Triangle': {'item': '🔺', 'match': 'shadow', 'category': 'Shapes', 'word': 'Triangle'},
    // 'Star': {'item': '⭐', 'match': 'shadow', 'category': 'Shapes', 'word': 'Star'},
    // 'Heart': {'item': '❤️', 'match': 'shadow', 'category': 'Shapes', 'word': 'Heart'},

    // // --- ANIMALS (Association: Shadow Matching) ---
    // 'Lion': {'item': '🦁', 'match': 'shadow', 'category': 'Animals', 'word': 'Lion'},
    // 'Tiger': {'item': '🐯', 'match': 'shadow', 'category': 'Animals', 'word': 'Tiger'},
    // 'Elephant': {'item': '🐘', 'match': 'shadow', 'category': 'Animals', 'word': 'Elephant'},
    // 'Monkey': {'item': '🐒', 'match': 'shadow', 'category': 'Animals', 'word': 'Monkey'},
    // 'Panda': {'item': '🐼', 'match': 'shadow', 'category': 'Animals', 'word': 'Panda'},
  