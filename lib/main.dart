// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// --- Auth Screens ---
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';

// --- Admin Screens ---
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/concept_manager.dart'; // <--- ADD THIS LINE EXACTLY

// --- Parent Screens ---
import 'screens/parent/parent_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const LittleGeniusApp());
}

class LittleGeniusApp extends StatelessWidget {
  const LittleGeniusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LittleGenius',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        fontFamily: 'Poppins',
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/admin': (context) => const AdminDashboard(),
        '/parent': (context) => ParentDashboard(),
        '/concepts': (context) => const ConceptManager(), // This should work now
      },
    );
  }
}