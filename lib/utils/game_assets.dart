class GameAssets {
  // Master Library expanded with 'match' data for interactive learning
  static final Map<String, Map<String, dynamic>> _library = {
    // --- ALPHABETS (Association: Upper to Lower) ---
    'A': {'item': 'A', 'match': 'a', 'category': 'Alphabets', 'word': 'Apple'},
    'B': {'item': 'B', 'match': 'b', 'category': 'Alphabets', 'word': 'Ball'},
    'C': {'item': 'C', 'match': 'c', 'category': 'Alphabets', 'word': 'Cat'},
    'D': {'item': 'D', 'match': 'd', 'category': 'Alphabets', 'word': 'Dog'},
    'E': {'item': 'E', 'match': 'e', 'category': 'Alphabets', 'word': 'Elephant'},

    // --- NUMBERS (Association: Number to Dice/Quantity) ---
    '1': {'item': '1', 'match': '🍎', 'category': 'Numbers', 'word': 'One'},
    '2': {'item': '2', 'match': '🍎🍎', 'category': 'Numbers', 'word': 'Two'},
    '3': {'item': '3', 'match': '🍎🍎🍎', 'category': 'Numbers', 'word': 'Three'},
    '4': {'item': '4', 'match': '🍎🍎🍎🍎', 'category': 'Numbers', 'word': 'Four'},
    '5': {'item': '5', 'match': '🍎🍎🍎🍎🍎', 'category': 'Numbers', 'word': 'Five'},

    // --- SHAPES (Association: Shadow Matching) ---
    'Circle': {'item': '⭕', 'match': 'shadow', 'category': 'Shapes', 'word': 'Circle'},
    'Square': {'item': '⬛', 'match': 'shadow', 'category': 'Shapes', 'word': 'Square'},
    'Triangle': {'item': '🔺', 'match': 'shadow', 'category': 'Shapes', 'word': 'Triangle'},
    'Star': {'item': '⭐', 'match': 'shadow', 'category': 'Shapes', 'word': 'Star'},
    'Heart': {'item': '❤️', 'match': 'shadow', 'category': 'Shapes', 'word': 'Heart'},

    // --- ANIMALS (Association: Shadow Matching) ---
    'Lion': {'item': '🦁', 'match': 'shadow', 'category': 'Animals', 'word': 'Lion'},
    'Tiger': {'item': '🐯', 'match': 'shadow', 'category': 'Animals', 'word': 'Tiger'},
    'Elephant': {'item': '🐘', 'match': 'shadow', 'category': 'Animals', 'word': 'Elephant'},
    'Monkey': {'item': '🐒', 'match': 'shadow', 'category': 'Animals', 'word': 'Monkey'},
    'Panda': {'item': '🐼', 'match': 'shadow', 'category': 'Animals', 'word': 'Panda'},
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
      'word': name
    };
  }

  static List<String> getDistractors(String correctName, String category) {
    List<String> pool = _library.entries
        .where((e) => e.value['category'] == category && e.key.toLowerCase() != correctName.toLowerCase())
        .map((e) => e.key)
        .toList();

    // Fallback if category is empty
    if (pool.length < 2) {
      pool.addAll(_library.keys.where((k) => k.toLowerCase() != correctName.toLowerCase()));
    }

    pool.shuffle();
    return pool.take(2).toList(); 
  }
}