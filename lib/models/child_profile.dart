class ChildProfile {
  String id, parentId, name, avatar, language, preferredMode, quietHours;
  int age, totalStars, dailyLimit, usageToday;
  Map<String, double> masteryScores;

  ChildProfile({
    required this.id, required this.parentId, required this.name,
    required this.age, required this.avatar, required this.language,
    required this.dailyLimit, required this.usageToday,
    required this.preferredMode, required this.totalStars,
    required this.masteryScores,
    this.quietHours = "19:00",
  });

  Map<String, dynamic> toMap() => {
    'parentId': parentId, 'name': name, 'age': age, 'avatar': avatar,
    'language': language, 'dailyLimit': dailyLimit, 'usageToday': usageToday,
    'preferredMode': preferredMode, 'totalStars': totalStars,
    'masteryScores': masteryScores, 'quietHours': quietHours,
  };

  factory ChildProfile.fromMap(Map<String, dynamic> map, String docId) => ChildProfile(
    id: docId, parentId: map['parentId'] ?? '', name: map['name'] ?? '',
    age: map['age'] ?? 4, avatar: map['avatar'] ?? '🦁',
    language: map['language'] ?? 'en-US', dailyLimit: map['dailyLimit'] ?? 30,
    usageToday: map['usageToday'] ?? 0, preferredMode: map['preferredMode'] ?? 'Visual',
    totalStars: map['totalStars'] ?? 0, quietHours: map['quietHours'] ?? "19:00",
    masteryScores: Map<String, double>.from(map['masteryScores'] ?? {}),
  );
}