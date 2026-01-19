import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- SIGN UP METHOD ---
  // This creates a user in Firebase Auth AND a role document in Firestore
  Future<User?> signUp(String email, String password, String role) async {
    try {
      // 1. Create the user in Firebase Authentication
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      User? user = result.user;

      // 2. Create a corresponding document in the 'users' collection
      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'role': role, // 'parent' or 'admin'
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return user;
    } catch (e) {
      print("Sign Up Error: ${e.toString()}");
      return null;
    }
  }

  // --- LOGIN METHOD ---
  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      return result.user;
    } catch (e) {
      print("Login Error: ${e.toString()}");
      return null;
    }
  }

  // --- GET USER ROLE ---
  // Used by Login and Splash screens to redirect to the correct dashboard
  Future<String> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc['role'] ?? 'parent';
      }
      return 'parent'; // Fallback
    } catch (e) {
      return 'parent';
    }
  }

  // --- LOGOUT ---
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get current user stream
  Stream<User?> get userState => _auth.authStateChanges();
}