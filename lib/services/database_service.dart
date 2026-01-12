import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/child_profile.dart';
import '../models/activity_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- PARENT SECTION ---

  // Add a new child profile
  Future<void> addChildProfile(ChildProfile child) async {
    try {
      await _db.collection('children').add(child.toMap());
    } catch (e) {
      print("Error adding child: $e");
    }
  }

  // Fetch children belonging to a specific parent
  Stream<List<ChildProfile>> getChildren(String parentId) {
    return _db
        .collection('children')
        .where('parentId', isEqualTo: parentId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChildProfile.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Update child AI results (Mastery and Mode)
  Future<void> updateChildAIStats(String childId, String preferredMode, Map<String, double> masteryScores) async {
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

  // ADMIN: Add a new global learning activity
  Future<void> addActivity(Activity activity) async {
    try {
      await _db.collection('activities').add(activity.toMap());
    } catch (e) {
      print("Error publishing activity: $e");
    }
  }

  // ADMIN: Fetch all activities globally for the Content Library
  Stream<List<Activity>> getAllActivities() {
    return _db.collection('activities').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Activity.fromMap(doc.data(), doc.id)).toList());
  }
}