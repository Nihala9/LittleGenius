import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Services
import 'services/theme_service.dart';

// Auth Screens
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';

// Admin Screens
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/activity_manager.dart';
import 'screens/admin/concept_manager.dart';

// Parent Screens
import 'screens/parent/parent_dashboard.dart';
import 'screens/parent/add_child.dart'; // Matches your new filename

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: const LittleGeniusApp(),
    ),
  );
}

class LittleGeniusApp extends StatelessWidget {
  const LittleGeniusApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LittleGenius',
      themeMode: themeService.themeMode,
      
      // PROFESSIONAL LIGHT THEME (Slate 50)
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF5D5FEF),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        cardColor: Colors.white,
      ),

      // PROFESSIONAL DARK THEME (Slate 950)
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF5D5FEF),
        scaffoldBackgroundColor: const Color(0xFF020617),
        cardColor: const Color(0xFF0F172A),
      ),

      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/admin': (context) => const AdminDashboard(),
        '/parent': (context) => const ParentDashboard(),
        '/add-child': (context) => const AddChildWizard(), // Corrected class name
        '/concepts': (context) => const ConceptManager(),
        '/inventory': (context) => const ActivityManager(),
      },
    );
  }
}