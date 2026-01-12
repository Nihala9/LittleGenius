import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'landing_screen.dart'; // Same folder
import '../../services/auth_service.dart'; // Corrected path

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    // Show splash for 3 seconds
    await Future.delayed(const Duration(seconds: 3));

    User? user = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (user != null) {
      // User is already logged in, we need to check their role to route correctly
      final role = await AuthService().getUserRole(user.uid);
      if (!mounted) return;

      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/parent');
      }
    } else {
      // Not logged in, go to Landing Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LandingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[900],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, size: 100, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              "LittleGenius",
              style: TextStyle(
                fontSize: 36, 
                fontWeight: FontWeight.bold, 
                color: Colors.white,
                letterSpacing: 1.5
              ),
            ),
            const Text("AI PERSONALIZED LEARNING", 
              style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w300)),
            const SizedBox(height: 50),
            const SizedBox(
              width: 150,
              child: LinearProgressIndicator(
                color: Colors.orange, 
                backgroundColor: Colors.white12,
                minHeight: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}