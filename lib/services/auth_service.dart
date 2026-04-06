import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Add this to pubspec.yaml

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // --- 1. REGISTER PARENT (Email/Password) ---
  Future<String?> registerUser(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      
      // Save role as 'parent' in Firestore
      await _db.collection('users').doc(result.user!.uid).set({
        'email': email,
        'role': 'parent',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    } catch (e) {
      return "An unexpected error occurred.";
    }
  }

  // --- 2. LOGIN (Email/Password) ---
  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      
      DocumentSnapshot doc = await _db.collection('users').doc(result.user!.uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("Login Error: $e");
      return null;
    }
  }

  // --- 3. FORGOT PASSWORD (Send Reset Email) ---
  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    }
  }

  // --- 4. GOOGLE SIGN IN ---
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      // Trigger the Google authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      // Obtain auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign into Firebase
      UserCredential result = await _auth.signInWithCredential(credential);
      
      // Check if user exists in Firestore
      DocumentSnapshot doc = await _db.collection('users').doc(result.user!.uid).get();
      
      if (!doc.exists) {
        // Create new profile for Google user
        await _db.collection('users').doc(result.user!.uid).set({
          'email': result.user!.email,
          'role': 'parent',
          'createdAt': FieldValue.serverTimestamp(),
        });
        return {'email': result.user!.email, 'role': 'parent'};
      }
      
      return doc.data() as Map<String, dynamic>;
    } catch (e) {
      print("Google Sign In Error: $e");
      return null;
    }
  }

  // --- 5. LOGOUT ---
  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  // --- HELPER: CLEAN ERROR MESSAGES ---
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found': return "No account found with this email.";
      case 'wrong-password': return "Incorrect password.";
      case 'email-already-in-use': return "This email is already registered.";
      case 'invalid-email': return "The email address is not valid.";
      case 'weak-password': return "The password is too weak.";
      default: return e.message ?? "Authentication failed.";
    }
  }
}