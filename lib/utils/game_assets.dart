// lib/utils/game_assets.dart - Expanded
class GameAssets {
  static Map<String, dynamic> getConceptData(String name) {
    Map<String, Map<String, dynamic>> data = {
      'A': {'item': '🍎', 'word': 'Apple', 'color': 'Red'},
      'B': {'item': '⚽', 'word': 'Ball', 'color': 'Blue'},
      'C': {'item': '🐱', 'word': 'Cat', 'color': 'Orange'},
      'D': {'item': '🐶', 'word': 'Dog', 'color': 'Brown'},
      '1': {'item': '☝️', 'word': 'One', 'color': 'Yellow'},
      '2': {'item': '✌️', 'word': 'Two', 'color': 'Green'},
      // Add more as needed
    };
    return data[name.toUpperCase()] ?? {'item': '🌟', 'word': 'Star', 'color': 'Gold'};
  }

  static List<String> getDistractors(String correctName) {
    List<String> all = ['A', 'B', 'C', 'D', '1', '2', '3'];
    all.remove(correctName);
    all.shuffle();
    return all.take(3).toList(); // Return 3 wrong answers
  }
}