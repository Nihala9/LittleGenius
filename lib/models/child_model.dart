class ChildProfile {
  String id;
  String name;
  int age;
  String language;
  String avatarUrl;
  String buddyType; 
  final String profileEmoji; // NEW: For sibling identity
  final String profileColor; // NEW: For sibling identity
  String preferredMode;
  int totalStars;
  int dailyLimit;
  Map<String, double> masteryScores;

  ChildProfile({
    required this.id, required this.name, required this.age, 
    required this.language, required this.avatarUrl, required this.buddyType,
     required this.profileEmoji, required this.profileColor,
    this.preferredMode = "Tracing", this.totalStars = 0, 
    this.dailyLimit = 30, this.masteryScores = const {},
  });

  factory ChildProfile.fromMap(Map<String, dynamic> data, String id) {
    return ChildProfile(
      id: id,
      name: data['name'] ?? '',
      age: data['age'] ?? 3,
      language: data['language'] ?? 'English',
      avatarUrl: data['avatarUrl'] ?? '',
      buddyType: data['buddyType'] ?? 'Robo-B1',
      profileEmoji: data['profileEmoji'] ?? '⭐', // Read from DB
      profileColor: data['profileColor'] ?? '0xFF80B3FF', // Read from DB
      preferredMode: data['preferredMode'] ?? 'Tracing',
      totalStars: data['totalStars'] ?? 0,
      dailyLimit: data['dailyLimit'] ?? 30,
      masteryScores: Map<String, double>.from(data['masteryScores'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name, 'age': age, 'language': language, 
      'avatarUrl': avatarUrl, 'buddyType': buddyType,
      'profileEmoji': profileEmoji, 'profileColor': profileColor,
      'preferredMode': preferredMode, 'totalStars': totalStars,
      'dailyLimit': dailyLimit, 'masteryScores': masteryScores,
    };
  }
}