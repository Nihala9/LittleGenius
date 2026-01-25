import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../models/child_model.dart';
import '../utils/app_colors.dart';
import 'landing_screen.dart';
import 'parent/profile_selector.dart';
import 'child/child_home_screen.dart'; // Target for returning kids
import 'admin/admin_dashboard.dart';

class SplashScreen extends StatefulWidget {
  final String? savedChildId; // Accept the ID from main.dart

  const SplashScreen({super.key, this.savedChildId});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final DatabaseService _db = DatabaseService();

  @override
  void initState() {
    super.initState();
    _handleRedirect();
  }

  void _handleRedirect() async {
    // 1. Show branding for 3 seconds
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // User not logged in -> Intro/Landing
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const LandingScreen())
      );
    } else {
      try {
        // 2. Fetch User Role (Admin or Parent)
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          _goToLanding();
          return;
        }

        String role = userDoc['role'] ?? 'parent';

        if (role == 'admin') {
          // GO TO ADMIN
          if (!mounted) return;
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (context) => const AdminDashboard())
          );
        } else {
          // GO TO PARENT/CHILD FLOW
          _handleParentRedirect(user.uid);
        }
      } catch (e) {
        _goToLanding();
      }
    }
  }

  void _handleParentRedirect(String uid) async {
    // Check if we have a saved child session to resume
    if (widget.savedChildId != null) {
      try {
        ChildProfile profile = await _db.getLatestChildProfile(uid, widget.savedChildId!);
        if (!mounted) return;
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => ChildHomeScreen(child: profile))
        );
      } catch (e) {
        _goToProfileSelector();
      }
    } else {
      _goToProfileSelector();
    }
  }

  void _goToProfileSelector() {
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => const ProfileSelectorScreen())
    );
  }

  void _goToLanding() {
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => const LandingScreen())
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.asset('assets/images/splash.jpg', width: 160, height: 160, fit: BoxFit.cover),
            ),
            const SizedBox(height: 30),
            const Text("LittleGenius", 
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
            const Text("Learn • Play • Grow", 
              style: TextStyle(color: Colors.white70, fontSize: 18)),
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const LinearProgressIndicator(
                  minHeight: 6,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}