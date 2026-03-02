class Activity {
  String id;
  String conceptId;   
  String title;
  String activityMode; 
  int difficulty;
  String? imageUrl; 

  Activity({
    required this.id,
    required this.conceptId,
    required this.title,
    required this.activityMode,
    required this.difficulty,
    this.imageUrl,
  });

  factory Activity.fromMap(Map<String, dynamic> data, String id) {
    return Activity(
      id: id,
      conceptId: data['conceptId'] ?? '',
      title: data['title'] ?? '',
      activityMode: data['activityMode'] ?? 'Tracing',
      difficulty: data['difficulty'] ?? 1,
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conceptId': conceptId,
      'title': title,
      'activityMode': activityMode,
      'difficulty': difficulty,
      'imageUrl': imageUrl,
    };
  }
}