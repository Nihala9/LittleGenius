class ChildProfile {
  String id;
  String name;
  int age;
  String childClass;
  String language;
  String avatarUrl;
  String preferredMode;
  int totalStars;
  int dailyLimit;
  Map<String, double> masteryScores;
  List<String> badges; // Added to store earned achievement IDs

  ChildProfile({
    required this.id, required this.name, required this.age, 
    required this.childClass, required this.language, required this.avatarUrl,
    this.preferredMode = "Tracing", this.totalStars = 0, 
    this.dailyLimit = 30, this.masteryScores = const {},
    this.badges = const [],
  });

  factory ChildProfile.fromMap(Map<String, dynamic> data, String id) {
    return ChildProfile(
      id: id,
      name: data['name'] ?? '',
      age: data['age'] ?? 3,
      childClass: data['childClass'] ?? 'Pre-School',
      language: data['language'] ?? 'English',
      avatarUrl: data['avatarUrl'] ?? 'assets/icons/profiles/p1.png',
      preferredMode: data['preferredMode'] ?? 'Tracing',
      totalStars: data['totalStars'] ?? 0,
      dailyLimit: data['dailyLimit'] ?? 30,
      masteryScores: Map<String, double>.from(data['masteryScores'] ?? {}),
      badges: List<String>.from(data['badges'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name, 'age': age, 'childClass': childClass, 'language': language, 
      'avatarUrl': avatarUrl, 'preferredMode': preferredMode, 
      'totalStars': totalStars, 'dailyLimit': dailyLimit, 
      'masteryScores': masteryScores, 'badges': badges,
    };
  }
}