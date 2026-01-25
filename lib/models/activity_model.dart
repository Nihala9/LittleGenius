class Activity {
  String id;
  String conceptId;   // e.g., "letter_a"
  String title;
  String activityMode; // "Tracing", "AudioMatch", "Puzzle"
  String language;
  int difficulty;

  Activity({
    required this.id,
    required this.conceptId,
    required this.title,
    required this.activityMode,
    required this.language,
    required this.difficulty,
  });

  factory Activity.fromMap(Map<String, dynamic> data, String id) {
    return Activity(
      id: id,
      conceptId: data['conceptId'] ?? '',
      title: data['title'] ?? '',
      activityMode: data['activityMode'] ?? 'Visual',
      language: data['language'] ?? 'English',
      difficulty: data['difficulty'] ?? 1,
    );
  }
}