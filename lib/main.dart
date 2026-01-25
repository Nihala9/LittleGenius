import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

// Screens & Services
import 'services/theme_service.dart';
import 'screens/splash_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/parent/profile_selector.dart';
import 'screens/parent/parent_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/parent/profile_wizard_screen.dart';
import 'utils/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize local storage
  final prefs = await SharedPreferences.getInstance();
  final String? savedChildId = prefs.getString('activeChildId');

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: LittleGeniusApp(savedChildId: savedChildId),
    ),
  );
}

class LittleGeniusApp extends StatelessWidget {
  final String? savedChildId;
  const LittleGeniusApp({super.key, this.savedChildId});

  @override
  Widget build(BuildContext context) {
    // We use a Consumer here to wrap the MaterialApp. 
    // This allows the app to listen to theme changes correctly.
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          title: 'LittleGenius',
          debugShowCheckedModeBanner: false,
          
          // Theme Configuration
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: AppColors.primaryBlue,
            scaffoldBackgroundColor: AppColors.backgroundWhite,
            fontFamily: 'Poppins',
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: AppColors.primaryBlue,
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            fontFamily: 'Poppins',
            useMaterial3: true,
          ),
          
          // Apply current mode from Service
          themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          
          // First screen to load
          home: SplashScreen(savedChildId: savedChildId),
          
          routes: {
            '/landing': (context) => const LandingScreen(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/profile_selector': (context) => const ProfileSelectorScreen(),
            '/parent_dashboard': (context) => const ParentDashboard(),
            '/admin_dashboard': (context) => const AdminDashboard(),
            '/add_child': (context) => const ProfileWizardScreen(),
          },
        );
      },
    );
  }
}