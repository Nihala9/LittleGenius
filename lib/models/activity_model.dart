import 'package:flutter/material.dart';

enum ActivityStatus { draft, published, archived }

class Activity {
  String id;
  String conceptId;
  String language;
  String activityMode;
  String title;
  String objective; // The field that was missing
  String type;
  String subject;
  String ageGroup;
  String difficulty;
  int estimatedTime;
  double masteryGoal;
  int retryLimit;
  int starReward;
  String badgeName;
  ActivityStatus status;
  DateTime createdAt;

  Activity({
    required this.id,
    required this.conceptId,
    required this.language,
    required this.activityMode,
    required this.title,
    required this.objective,
    required this.type,
    required this.subject,
    required this.ageGroup,
    required this.difficulty,
    required this.estimatedTime,
    this.masteryGoal = 0.9,
    this.retryLimit = 3,
    this.starReward = 10,
    this.badgeName = 'Explorer',
    this.status = ActivityStatus.draft,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'conceptId': conceptId,
      'language': language,
      'activityMode': activityMode,
      'title': title,
      'objective': objective,
      'type': type,
      'subject': subject,
      'ageGroup': ageGroup,
      'difficulty': difficulty,
      'estimatedTime': estimatedTime,
      'masteryGoal': masteryGoal,
      'retryLimit': retryLimit,
      'starReward': starReward,
      'badgeName': badgeName,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map, String docId) {
    return Activity(
      id: docId,
      conceptId: map['conceptId'] ?? '',
      language: map['language'] ?? 'en-US',
      activityMode: map['activityMode'] ?? 'Visual',
      title: map['title'] ?? 'Untitled',
      objective: map['objective'] ?? '',
      type: map['type'] ?? 'Game',
      subject: map['subject'] ?? 'Literacy',
      ageGroup: map['ageGroup'] ?? '3-7',
      difficulty: map['difficulty'] ?? 'Easy',
      estimatedTime: (map['estimatedTime'] ?? 5).toInt(),
      masteryGoal: (map['masteryGoal'] ?? 0.9).toDouble(),
      retryLimit: (map['retryLimit'] ?? 3).toInt(),
      starReward: (map['starReward'] ?? 10).toInt(),
      badgeName: map['badgeName'] ?? 'Explorer',
      status: ActivityStatus.values.byName(map['status'] ?? 'draft'),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }
}