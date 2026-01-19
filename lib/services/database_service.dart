import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/child_profile.dart';
import '../models/activity_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- PARENT SECTION ---

  Future<void> addChildProfile(ChildProfile child) async {
    try {
      await _db.collection('children').add(child.toMap());
    } catch (e) {
      print("Error adding child: $e");
    }
  }

  Stream<List<ChildProfile>> getChildren(String parentId) {
    return _db
        .collection('children')
        .where('parentId', isEqualTo: parentId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChildProfile.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> updateChildProfile(ChildProfile child) async {
    try {
      await _db.collection('children').doc(child.id).update(child.toMap());
    } catch (e) {
      print("Error updating child profile: $e");
    }
  }

  Future<void> deleteChildProfile(String childId) async {
    try {
      await _db.collection('children').doc(childId).delete();
    } catch (e) {
      print("Error deleting child: $e");
    }
  }

  // UPDATED: Standardized method for AI Engine
  Future<void> updateChildAIStats(
      String childId, String preferredMode, Map<String, double> masteryScores) async {
    try {
      await _db.collection('children').doc(childId).update({
        'preferredMode': preferredMode,
        'masteryScores': masteryScores,
      });
    } catch (e) {
      print("Error updating AI stats: $e");
    }
  }

  // --- ADMIN SECTION ---

  Future<void> addActivity(Activity activity) async {
    try {
      await _db.collection('activities').add(activity.toMap());
    } catch (e) {
      print("Error publishing activity: $e");
    }
  }

  Stream<List<Activity>> getAllActivities() {
    return _db.collection('activities').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Activity.fromMap(doc.data(), doc.id)).toList());
  }
}