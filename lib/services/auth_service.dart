import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Register Parent
  Future<String?> registerUser(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      
      // Save role as 'parent' in Firestore
      await _db.collection('users').doc(result.user!.uid).set({
        'email': email,
        'role': 'parent', // Default role
        'createdAt': DateTime.now(),
      });
      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }

  // Login (Checks role and returns it)
  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      
      // Fetch user role from Firestore
      DocumentSnapshot doc = await _db.collection('users').doc(result.user!.uid).get();
      return doc.data() as Map<String, dynamic>;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }
}