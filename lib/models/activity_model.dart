enum ActivityStatus { draft, published, archived }

class Activity {
  String id;
  String title;
  String objective; // e.g., "Recognize numbers 1-10"
  String subject;   // Math, Reading, Science
  String type;      // Quiz, Game, Puzzle, Story
  String ageGroup;  // 3-4, 5-6, 7-8
  String difficulty;// Easy, Medium, Hard
  int estimatedTime; // In minutes
  String language;
  ActivityStatus status;
  DateTime createdAt;

  Activity({
    required this.id,
    required this.title,
    required this.objective,
    required this.subject,
    required this.type,
    required this.ageGroup,
    required this.difficulty,
    required this.estimatedTime,
    required this.language,
    this.status = ActivityStatus.draft,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'objective': objective,
      'subject': subject,
      'type': type,
      'ageGroup': ageGroup,
      'difficulty': difficulty,
      'estimatedTime': estimatedTime,
      'language': language,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map, String docId) {
    return Activity(
      id: docId,
      title: map['title'] ?? '',
      objective: map['objective'] ?? '',
      subject: map['subject'] ?? 'Math',
      type: map['type'] ?? 'Game',
      ageGroup: map['ageGroup'] ?? '3-4',
      difficulty: map['difficulty'] ?? 'Easy',
      estimatedTime: map['estimatedTime'] ?? 5,
      language: map['language'] ?? 'en-US',
      status: ActivityStatus.values.byName(map['status'] ?? 'draft'),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}