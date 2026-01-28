import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/child_model.dart';
import '../models/concept_model.dart';
import '../models/activity_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- PARENT & CHILD PROFILE LOGIC ---
  Stream<List<ChildProfile>> streamChildProfiles(String parentId) {
    return _db.collection('parents').doc(parentId).collection('profiles')
        .snapshots().map((l) => l.docs.map((d) => ChildProfile.fromMap(d.data(), d.id)).toList());
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

  // --- AI PERFORMANCE LOGIC ---
  Future<void> updateMastery(String parentId, String childId, String conceptId, double score) async {
    await _db.collection('parents').doc(parentId).collection('profiles').doc(childId)
        .update({'masteryScores.$conceptId': score});
  }

  Future<void> updatePreferredMode(String childId, String mode) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _db.collection('parents').doc(uid).collection('profiles').doc(childId).update({'preferredMode': mode});
    }
  }

  // --- ADMIN CONTENT: CATEGORY CRUD ---
  Stream<List<Map<String, dynamic>>> streamCategories() {
    return _db.collection('categories')
        .orderBy('name') // Alphabetical A-Z
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Future<void> addCategory(Map<String, dynamic> data) async => await _db.collection('categories').add(data);
  Future<void> updateCategory(String id, Map<String, dynamic> data) async => await _db.collection('categories').doc(id).update(data);
  Future<void> deleteCategory(String id) async => await _db.collection('categories').doc(id).delete();

  // --- ADMIN CONTENT: CONCEPT CRUD ---
  Future<void> addConcept(Concept c) async => await _db.collection('concepts').add(c.toMap());
  
  // UPDATED: Now sorts by Name (A-Z) instead of Order
  Stream<List<Concept>> streamConcepts() {
    return _db.collection('concepts').orderBy('name').snapshots()
        .map((l) => l.docs.map((d) => Concept.fromMap(d.data(), d.id)).toList());
  }

  // UPDATED: Filtered concepts also sort by Name (A-Z)
  Stream<List<Concept>> streamConceptsByCategory(String category) {
    return _db.collection('concepts')
        .where('category', isEqualTo: category)
        .orderBy('name') // Alphabetical sorting for lessons
        .snapshots()
        .map((l) => l.docs.map((d) => Concept.fromMap(d.data(), d.id)).toList());
  }

  Future<void> updateConcept(String id, Map<String, dynamic> data) async {
    await _db.collection('concepts').doc(id).update(data);
  }

  Future<void> deleteConcept(String id) async => await _db.collection('concepts').doc(id).delete();

  // --- ADMIN CONTENT: ACTIVITY CRUD ---
  Future<void> addActivity(Activity a) async {
    await _db.collection('activities').add({
      'conceptId': a.conceptId, 'title': a.title, 'activityMode': a.activityMode,
      'language': a.language, 'difficulty': a.difficulty, 'isPublished': false,
    });
  }

  Future<void> updateActivity(String id, Map<String, dynamic> data) async => await _db.collection('activities').doc(id).update(data);
  Future<void> deleteActivity(String id) async => await _db.collection('activities').doc(id).delete();

  Stream<List<Activity>> streamActivitiesForConcept(String cid) {
    return _db.collection('activities').where('conceptId', isEqualTo: cid)
        .snapshots().map((l) => l.docs.map((d) => Activity.fromMap(d.data(), d.id)).toList());
  }

  // --- SPRINT 1: VISIBILITY & GLOBAL MONITORING ---
  Future<void> toggleConceptVisibility(String id, bool status) async {
    await _db.collection('concepts').doc(id).update({'isPublished': status});
  }

  // UPDATED: Published stream also follows alphabetical order
  Stream<List<Concept>> streamPublishedConceptsByCategory(String category) {
    return _db.collection('concepts')
        .where('category', isEqualTo: category)
        .where('isPublished', isEqualTo: true)
        .orderBy('name') // Sorting A-Z for the child's explorer view
        .snapshots()
        .map((l) => l.docs.map((d) => Concept.fromMap(d.data(), d.id)).toList());
  }

  // --- GLOBAL MONITORING (FOR ADMIN) ---
  Stream<QuerySnapshot> streamAllParents() {
    return _db.collection('users').where('role', isEqualTo: 'parent').snapshots();
  }

  Stream<List<Activity>> streamAllActivities() {
    return _db.collection('activities').snapshots().map((l) => 
        l.docs.map((d) => Activity.fromMap(d.data(), d.id)).toList());
  }

  // --- AI CONFIG & ANALYTICS ---
  Future<void> updateAIConfig(Map<String, dynamic> config) async {
    await _db.collection('settings').doc('ai_config').set(config, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>> getAIConfig() async {
    var doc = await _db.collection('settings').doc('ai_config').get();
    return doc.data() ?? {'pGuess': 0.2, 'pSlip': 0.1, 'masteryThreshold': 0.8};
  }

  Future<Map<String, String>> getConceptNames() async {
    var snap = await _db.collection('concepts').get();
    return {for (var d in snap.docs) d.id: d.data()['name'] ?? 'Lesson'};
  }
}