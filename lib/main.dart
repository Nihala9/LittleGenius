import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

// Screens & Services
import 'services/theme_service.dart';
import 'services/notification_service.dart'; // Added
import 'services/voice_service.dart';        // Added
import 'screens/splash_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/parent/profile_selector.dart';
import 'screens/parent/parent_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/parent/profile_wizard_screen.dart';
import 'screens/admin/admin_settings_screen.dart';
import 'utils/app_colors.dart';

void main() async {
  // 1. Ensure Flutter bindings are ready
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase (Required before runApp)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 3. Run the app immediately. 
  // This prevents the "APP_SCOUT_HANG" on MIUI by showing the UI thread is active.
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: const LittleGeniusApp(),
    ),
  );
}

class LittleGeniusApp extends StatefulWidget {
  // Global Navigator Key: Allows NotificationService to navigate 
  // to specific screens without a BuildContext.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  const LittleGeniusApp({super.key});

  @override
  State<LittleGeniusApp> createState() => _LittleGeniusAppState();
}

class _LittleGeniusAppState extends State<LittleGeniusApp> {
  String? _savedChildId;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _bootstrapApp();
  }

  // --- ASYNC INITIALIZATION ENGINE ---
  // We do all heavy hardware/storage setup here while 
  // a lightweight loading indicator is shown.
  void _bootstrapApp() async {
    try {
      // Initialize multiple services in parallel to save time
      await Future.wait([
        // Load local preferences
        SharedPreferences.getInstance().then((prefs) {
          _savedChildId = prefs.getString('activeChildId');
        }),
        // Initialize Notification hardware/permissions
        NotificationService().init(),
        // Warm up the AI Voice engine
        VoiceService().initTTS(),
      ]);
    } catch (e) {
      debugPrint("Bootstrap Error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoaded = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          title: 'LittleGenius',
          // Link the global navigator key
          navigatorKey: LittleGeniusApp.navigatorKey, 
          debugShowCheckedModeBanner: false,
          
          // --- THEME CONFIGURATION ---
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
          
          themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          
          // Wait for bootstrap before showing the Splash/Logo
          home: !_isLoaded 
            ? const Scaffold(body: Center(child: CircularProgressIndicator())) 
            : SplashScreen(savedChildId: _savedChildId),
          
          // --- GLOBAL ROUTES ---
          routes: {
            '/landing': (context) => const LandingScreen(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/profile_selector': (context) => const ProfileSelectorScreen(),
            '/parent_dashboard': (context) => const ParentDashboard(),
            '/admin_dashboard': (context) => const AdminDashboard(),
            '/add_child': (context) => const ProfileWizardScreen(),
            '/admin_settings': (context) => const AdminSettingsScreen(), 
          },
        );
      },
    );
  }
}