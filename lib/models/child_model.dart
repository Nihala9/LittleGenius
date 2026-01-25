class ChildProfile {
  String id;
  String name;
  int age;
  String language;
  String avatarUrl; // Changed from local path to URL
  String preferredMode;
  int totalStars;
  Map<String, double> masteryScores;

  ChildProfile({
    required this.id, required this.name, required this.age, 
    required this.language, required this.avatarUrl, 
    this.preferredMode = "Visual", this.totalStars = 0, 
    this.masteryScores = const {},
  });

  factory ChildProfile.fromMap(Map<String, dynamic> data, String id) {
    return ChildProfile(
      id: id,
      name: data['name'] ?? '',
      age: data['age'] ?? 3,
      language: data['language'] ?? 'English',
      avatarUrl: data['avatarUrl'] ?? 'https://api.dicebear.com/7.x/bottts/png?seed=default',
      preferredMode: data['preferredMode'] ?? 'Visual',
      totalStars: data['totalStars'] ?? 0,
      masteryScores: Map<String, double>.from(data['masteryScores'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name, 'age': age, 'language': language, 
      'avatarUrl': avatarUrl, 'preferredMode': preferredMode, 
      'totalStars': totalStars, 'masteryScores': masteryScores,
    };
  }
}