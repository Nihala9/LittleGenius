class ChildProfile {
  String id;
  String parentId;
  String name;
  int age;
  String language; // e.g., 'en-US', 'ml-IN', 'hi-IN'
  String preferredMode; // MAB Algorithm result: 'Visual', 'Auditory', etc.
  int totalStars;
  Map<String, double> masteryScores; // New Field: { 'letter_A': 0.5, 'number_1': 0.2 }
  int dailyLimit; // New: daily limit in minutes
  int usageToday; // New: how many minutes used today


  ChildProfile({
    required this.id,
    required this.parentId,
    required this.name,
    required this.age,
    this.language = 'en-US',
    this.preferredMode = 'Visual', // Default starting mode
    this.totalStars = 0,
    required this.masteryScores,
    this.dailyLimit = 30, // Default 30 mins
    this.usageToday = 0,
  });

  // Convert Firebase Data to a Flutter Object
  factory ChildProfile.fromMap(Map<String, dynamic> map, String docId) {
    return ChildProfile(
      id: docId,
      parentId: map['parentId'] ?? '',
      name: map['name'] ?? '',
      age: map['age'] ?? 2,
      language: map['language'] ?? 'en-US',
      preferredMode: map['preferredMode'] ?? 'Visual',
      totalStars: map['totalStars'] ?? 0,
      masteryScores: Map<String, double>.from(map['masteryScores'] ?? {}),
      dailyLimit: map['dailyLimit'] ?? 30,
      usageToday: map['usageToday'] ?? 0,
    );
  }

  // Convert Flutter Object back to Firebase Data
  Map<String, dynamic> toMap() {
    return {
      'parentId': parentId,
      'name': name,
      'age': age,
      'language': language,
      'preferredMode': preferredMode,
      'totalStars': totalStars,
      'masteryScores': masteryScores,
      'dailyLimit': dailyLimit,
      'usageToday': usageToday,
    };
  }
}