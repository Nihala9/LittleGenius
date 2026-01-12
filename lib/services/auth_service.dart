import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Sign Up
  Future<User?> signUp(String email, String password, String role) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      // Store user role in Firestore
      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          'email': email,
          'role': role, // 'parent' or 'admin'
          'createdAt': DateTime.now(),
        });
      }
      return user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Login
  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Get User Role (To decide which dashboard to show)
  Future<String> getUserRole(String uid) async {
    DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
    return doc['role'] ?? 'parent';
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}