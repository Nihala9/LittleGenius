import 'package:cloud_firestore/cloud_firestore.dart';

class ChildProfile {
  String id;
  String name;
  String? parentName;
  int age;
  String childClass;
  String language;
  String avatarUrl;
  String preferredMode;
  int totalStars;
  int dailyLimit;
  Map<String, double> masteryScores;
  List<String> badges; 
  int minutesSpentToday;
  int streak;
  DateTime? lastSessionDate;

  ChildProfile({
    required this.id,
    required this.name,
    this.parentName,
    required this.age,
    required this.childClass,
    required this.language,
    required this.avatarUrl,
    this.preferredMode = "Tracing",
    this.totalStars = 0,
    this.dailyLimit = 30,
    this.masteryScores = const {},
    this.badges = const [],
    this.minutesSpentToday = 0,
    this.streak = 0,
    this.lastSessionDate,
  });

  factory ChildProfile.fromMap(Map<String, dynamic> data, String id) {
    // Safely convert mastery scores Map from Firestore
    // Firestore numbers can be int or double, so we use 'as num' then 'toDouble'
    Map<String, double> convertedScores = {};
    if (data['masteryScores'] != null) {
      (data['masteryScores'] as Map<String, dynamic>).forEach((key, value) {
        convertedScores[key] = (value as num).toDouble();
      });
    }

    return ChildProfile(
      id: id,
      name: data['name'] ?? '',
      parentName: data['parentName'],
      age: data['age'] ?? 3,
      childClass: data['childClass'] ?? 'Pre-School',
      language: data['language'] ?? 'English',
      avatarUrl: data['avatarUrl'] ?? 'assets/icons/profiles/p1.png',
      preferredMode: data['preferredMode'] ?? 'Tracing',
      totalStars: data['totalStars'] ?? 0,
      dailyLimit: data['dailyLimit'] ?? 30,
      masteryScores: convertedScores,
      badges: List<String>.from(data['badges'] ?? []),
      minutesSpentToday: data['minutesSpentToday'] ?? 0,
      streak: data['streak'] ?? 0,
      lastSessionDate: data['lastSessionDate'] != null 
          ? (data['lastSessionDate'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'parentName': parentName,
      'age': age,
      'childClass': childClass,
      'language': language,
      'avatarUrl': avatarUrl,
      'preferredMode': preferredMode,
      'totalStars': totalStars,
      'dailyLimit': dailyLimit,
      'masteryScores': masteryScores,
      'badges': badges,
      'minutesSpentToday': minutesSpentToday,
      'streak': streak,
      'lastSessionDate': lastSessionDate != null 
          ? Timestamp.fromDate(lastSessionDate!) 
          : FieldValue.serverTimestamp(),
    };
  }
}