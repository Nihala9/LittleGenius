class LearningLog {
  String activityId;
  String conceptId; // e.g., 'letter_A'
  String activityMode; // e.g., 'Tracing' or 'Matching'
  bool isSuccess;
  int timeSpent; // in seconds
  DateTime timestamp;

  LearningLog({
    required this.activityId,
    required this.conceptId,
    required this.activityMode,
    required this.isSuccess,
    required this.timeSpent,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'activityId': activityId,
      'conceptId': conceptId,
      'activityMode': activityMode,
      'isSuccess': isSuccess,
      'timeSpent': timeSpent,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}