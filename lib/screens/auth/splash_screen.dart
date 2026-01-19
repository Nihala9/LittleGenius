import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for AI Sync
import 'dart:async';
import 'landing_screen.dart'; 
import '../../services/auth_service.dart'; 
import '../../services/ai_engine.dart'; // Added to update the brain

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  // --- INTEGRATED INITIALIZATION PROCESS ---
  void _initializeApp() async {
    // 1. Minimum show time for branding (2 seconds)
    await Future.delayed(const Duration(seconds: 2));

    // 2. SYNC AI ENGINE WITH ADMIN RULES
    // This ensures the BKT/MAB logic is up-to-date before any game starts
    try {
      DocumentSnapshot aiSettings = await FirebaseFirestore.instance
          .collection('settings')
          .doc('ai_rules')
          .get();

      if (aiSettings.exists && aiSettings.data() != null) {
        AIEngine.syncRules(aiSettings.data() as Map<String, dynamic>);
        debugPrint("AI Engine: Successfully synchronized with Admin configurations.");
      }
    } catch (e) {
      debugPrint("AI Engine: Sync failed (using defaults). Error: $e");
    }

    // 3. AUTHENTICATION & ROLE-BASED ROUTING
    User? user = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (user != null) {
      // User is already logged in, fetch their role to decide which dashboard to show
      final role = await AuthService().getUserRole(user.uid);
      
      if (!mounted) return;

      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/parent');
      }
    } else {
      // No active session, go to the welcoming Landing Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LandingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Deep Indigo background for a professional "Space/Intelligence" feel
      backgroundColor: const Color(0xFF1E293B), 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Icon
            const Icon(Icons.auto_awesome, size: 80, color: Colors.orangeAccent),
            const SizedBox(height: 24),
            
            // App Title
            const Text(
              "LittleGenius",
              style: TextStyle(
                fontSize: 36, 
                fontWeight: FontWeight.w900, 
                color: Colors.white,
                letterSpacing: -1.0,
              ),
            ),
            
            // Tagline
            const Text(
              "INTELLIGENT ADAPTIVE LEARNING", 
              style: TextStyle(
                color: Colors.white38, 
                fontSize: 10, 
                fontWeight: FontWeight.bold, 
                letterSpacing: 2.0
              ),
            ),
            
            const SizedBox(height: 60),
            
            // Modern Slim Loading Indicator
            const SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                color: Colors.orangeAccent, 
                backgroundColor: Colors.white10,
                minHeight: 2,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Subtext indicating background processes
            const Text(
              "Syncing AI Engine...",
              style: TextStyle(color: Colors.white24, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}