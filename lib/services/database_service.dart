import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/child_model.dart';
import '../models/concept_model.dart';
import '../models/activity_model.dart';
import '../models/story_model.dart';
import 'notification_service.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==========================================
  // 1. PARENT & CHILD PROFILE LOGIC
  // ==========================================
  
  Stream<List<ChildProfile>> streamChildProfiles(String parentId) {
    return _db.collection('parents').doc(parentId).collection('profiles')
        .snapshots().map((l) => l.docs.map((d) => ChildProfile.fromMap(d.data(), d.id)).toList());
  }

  Stream<ChildProfile> streamSingleChild(String parentId, String childId) {
    return _db.collection('parents').doc(parentId).collection('profiles').doc(childId)
        .snapshots().map((doc) => ChildProfile.fromMap(doc.data()!, doc.id));
  }

  Future<ChildProfile> getLatestChildProfile(String parentId, String childId) async {
    var doc = await _db.collection('parents').doc(parentId).collection('profiles').doc(childId).get();
    return ChildProfile.fromMap(doc.data()!, doc.id);
  }

  Future<void> updateChildProfile(String parentId, String childId, Map<String, dynamic> data) async {
    if (childId == "new") {
      await _db.collection('parents').doc(parentId).collection('profiles').add(data);
    } else {
      await _db.collection('parents').doc(parentId).collection('profiles').doc(childId).update(data);
    }
  }

  Future<void> deleteChildProfile(String parentId, String childId) async {
    await _db.collection('parents').doc(parentId).collection('profiles').doc(childId).delete();
  }

  // ==========================================
  // 2. REWARDS & PROGRESS LOGIC
  // ==========================================

  Future<void> addStars(String parentId, String childId, int count) async {
    await _db.collection('parents').doc(parentId).collection('profiles').doc(childId).update({
      'totalStars': FieldValue.increment(count)
    });
  }

  Future<void> updateMastery(String parentId, String childId, String conceptId, double score, String childName, String category) async {
    await _db.collection('parents').doc(parentId).collection('profiles').doc(childId)
        .update({'masteryScores.$conceptId': score});

    if (score >= 0.5 && score < 0.55) {
      _logNotification(parentId, "Milestone Reached! 🌟", "$childName earned stars in $category!", 'progress');
      NotificationService().notifyProgress(childName, category, 2);
    } else if (score >= 0.8 && score < 0.85) {
      _logNotification(parentId, "Mastery Achieved! 🏆", "$childName mastered $category!", 'progress');
      NotificationService().notifyProgress(childName, category, 3);
    }
  }

  Future<void> updatePreferredMode(String childId, String mode) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await _db.collection('parents').doc(uid).collection('profiles').doc(childId).update({'preferredMode': mode});
      }
    } catch (e) { debugPrint("DB Error: $e"); }
  }

  // ==========================================
  // 3. ADMIN CONTENT MANAGEMENT
  // ==========================================

  // --- CATEGORIES ---
  Stream<List<Map<String, dynamic>>> streamCategories() {
    return _db.collection('categories').orderBy('order').snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Future<void> addCategory(Map<String, dynamic> data) async => await _db.collection('categories').add(data);
  Future<void> updateCategory(String id, Map<String, dynamic> data) async => await _db.collection('categories').doc(id).update(data);
  Future<void> deleteCategory(String id) async => await _db.collection('categories').doc(id).delete();

  // --- CONCEPTS (Lessons) ---
  
  // FIX: This method was missing, required by ContentReviewScreen
  Stream<List<Concept>> streamConcepts() {
    return _db.collection('concepts').orderBy('order').snapshots()
        .map((l) => l.docs.map((d) => Concept.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<Concept>> streamConceptsByCategory(String category) {
    return _db.collection('concepts').where('category', isEqualTo: category).orderBy('order').snapshots()
        .map((l) => l.docs.map((d) => Concept.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<Concept>> streamPublishedConceptsByCategory(String category) {
    return _db.collection('concepts').where('category', isEqualTo: category).where('isPublished', isEqualTo: true).orderBy('order').snapshots()
        .map((l) => l.docs.map((d) => Concept.fromMap(d.data(), d.id)).toList());
  }

  Future<void> addConcept(Concept c) async => await _db.collection('concepts').add(c.toMap());
  Future<void> updateConcept(String id, Map<String, dynamic> data) async => await _db.collection('concepts').doc(id).update(data);
  Future<void> deleteConcept(String id) async => await _db.collection('concepts').doc(id).delete();
  Future<void> toggleConceptVisibility(String id, bool status) async => await _db.collection('concepts').doc(id).update({'isPublished': status});

  // --- ACTIVITIES (Game Modes) ---
  
  Future<void> addActivity(Activity a) async => await _db.collection('activities').add(a.toMap());
  Future<void> updateActivity(String id, Map<String, dynamic> data) async => await _db.collection('activities').doc(id).update(data);
  Future<void> deleteActivity(String id) async => await _db.collection('activities').doc(id).delete();

  Stream<List<Activity>> streamActivitiesForConcept(String cid) {
    return _db.collection('activities').where('conceptId', isEqualTo: cid).snapshots()
        .map((l) => l.docs.map((d) => Activity.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<Activity>> streamAllActivities() {
    return _db.collection('activities').snapshots()
        .map((l) => l.docs.map((d) => Activity.fromMap(d.data(), d.id)).toList());
  }

  // --- STORIES (Magic Story Library) ---
  
  Future<void> addStory(KidStory story) async => await _db.collection('stories').add(story.toMap());
  Future<void> deleteStory(String id) async => await _db.collection('stories').doc(id).delete();
  
  Stream<List<KidStory>> streamStories() {
    return _db.collection('stories').snapshots()
        .map((l) => l.docs.map((d) => KidStory.fromMap(d.data(), d.id)).toList());
  }

  // ==========================================
  // 4. MONITORING & NOTIFICATIONS
  // ==========================================

  Stream<QuerySnapshot> streamAllParents() {
    return _db.collection('users').where('role', isEqualTo: 'parent').snapshots();
  }

  Future<void> _logNotification(String uid, String title, String body, String type) async {
    await _db.collection('parents').doc(uid).collection('notifications').add({
      'title': title, 'body': body, 'type': type, 'timestamp': FieldValue.serverTimestamp(), 'isRead': false,
    });
  }

  Stream<int> streamUnreadCount(String uid) {
    return _db.collection('parents').doc(uid).collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots().map((snap) => snap.docs.length);
  }

  Future<void> markNotificationsAsRead(String uid) async {
    final snapshots = await _db.collection('parents').doc(uid)
        .collection('notifications').where('isRead', isEqualTo: false).get();
    if (snapshots.docs.isEmpty) return;
    final batch = _db.batch();
    for (var doc in snapshots.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> logStruggleAlert(String uid, String childId, String childName, String conceptName, String category) async {
    String title = "Help Needed: $conceptName 💡";
    String body = "$childName is finding $conceptName tricky. Try an offline game together!";
    NotificationService().notifyStruggle(childName, conceptName, category);
    await _logNotification(uid, title, body, 'struggle');
  }

  // ==========================================
  // 5. USAGE TRACKING (Screen Time)
  // ==========================================

  Future<void> updateUsageHeartbeat(String childId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final docRef = _db.collection('parents').doc(uid).collection('profiles').doc(childId);
      final doc = await docRef.get();
      if (doc.exists) {
        final data = doc.data()!;
        DateTime now = DateTime.now();
        DateTime lastDate = data['lastSessionDate'] != null ? (data['lastSessionDate'] as Timestamp).toDate() : DateTime.now().subtract(const Duration(days: 1));
        bool isNewDay = lastDate.day != now.day || lastDate.month != now.month || lastDate.year != now.year;
        int limit = data['dailyLimit'] ?? 30;
        String name = data['name'] ?? "Child";
        int currentStreak = data['streak'] ?? 0;

        if (isNewDay) {
          DateTime yesterday = DateTime(now.year, now.month, now.day - 1);
          bool wasActiveYesterday = lastDate.year == yesterday.year && lastDate.month == yesterday.month && lastDate.day == yesterday.day;
          int newStreak = wasActiveYesterday ? currentStreak + 1 : 1;
          await docRef.update({'minutesSpentToday': 1, 'lastSessionDate': Timestamp.fromDate(now), 'streak': newStreak});
        } else {
          await docRef.update({'minutesSpentToday': FieldValue.increment(1), 'lastSessionDate': Timestamp.fromDate(now)});
          final freshDoc = await docRef.get();
          int newMins = freshDoc.data()?['minutesSpentToday'] ?? 0;
          if (newMins == (limit * 0.8).toInt()) {
            NotificationService().notifyUsageLimit(name, newMins, limit);
            _logNotification(uid, "Almost there! ⏳", "$name used 80% of time.", "usage");
          } else if (newMins >= limit) {
            NotificationService().notifyUsageLimit(name, newMins, limit);
            _logNotification(uid, "Time Up! 🛑", "$name reached the daily limit.", "usage");
          }
        }
      }
    } catch (e) { debugPrint("Heartbeat Error: $e"); }
  }

  // ==========================================
  // 6. ANALYTICS (Admin Console)
  // ==========================================

  Future<Map<String, dynamic>> getPlatformAnalytics() async {
    try {
      final allProfiles = await _db.collectionGroup('profiles').get();
      final docs = allProfiles.docs;
      int totalChildren = docs.length;
      int activeToday = 0;
      double totalStars = 0;
      int totalMasteries = 0;
      double totalUsageMinutes = 0;
      List<Map<String, dynamic>> childPerformance = [];
      DateTime today = DateTime.now();
      
      for (var doc in docs) {
        final data = doc.data();
        totalStars += (data['totalStars'] ?? 0).toDouble();
        totalUsageMinutes += (data['minutesSpentToday'] ?? 0).toDouble();
        
        if (data['lastSessionDate'] != null) {
          DateTime lastSession = (data['lastSessionDate'] as Timestamp).toDate();
          if (lastSession.year == today.year && lastSession.month == today.month && lastSession.day == today.day) {
            activeToday++;
          }
        }
        
        Map<String, double> masteryScores = {};
        if (data['masteryScores'] != null) {
          (data['masteryScores'] as Map<String, dynamic>).forEach((key, value) {
            masteryScores[key] = (value as num).toDouble();
          });
        }
        
        int childMasteries = masteryScores.values.where((score) => score >= 0.8).length;
        totalMasteries += childMasteries;
        
        childPerformance.add({
          'name': data['name'] ?? 'Unknown',
          'averageScore': masteryScores.isNotEmpty ? masteryScores.values.reduce((a, b) => a + b) / masteryScores.length : 0,
        });
      }
      
      childPerformance.sort((a, b) => (b['averageScore'] as double).compareTo(a['averageScore'] as double));

      return {
        'totalChildren': totalChildren,
        'activeToday': activeToday,
        'engagementRate': totalChildren > 0 ? (activeToday / totalChildren) * 100 : 0,
        'totalStars': totalStars.toInt(),
        'totalMasteries': totalMasteries,
        'avgUsagePerChild': totalChildren > 0 ? (totalUsageMinutes / totalChildren).toInt() : 0,
        'topPerformers': childPerformance.take(5).toList(),
        'avgScore': totalChildren > 0 ? (totalStars / totalChildren).toStringAsFixed(1) : "0",
      };
    } catch (e) { return {}; }
  }

  Future<Map<String, String>> getConceptNames() async {
    var snap = await _db.collection('concepts').get();
    return {for (var d in snap.docs) d.id: d.data()['name'] ?? 'Lesson'};
  }

  Future<void> updateAIConfig(Map<String, dynamic> config) async => await _db.collection('settings').doc('ai_config').set(config, SetOptions(merge: true));
  
  Future<Map<String, dynamic>> getAIConfig() async { 
    var doc = await _db.collection('settings').doc('ai_config').get(); 
    return doc.data() ?? {'pGuess': 0.2, 'pSlip': 0.1, 'masteryThreshold': 0.8, 'redirectionLimit': 2}; 
  }
}