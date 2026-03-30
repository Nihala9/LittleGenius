import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

// --- Services ---
import 'services/theme_service.dart';
import 'services/notification_service.dart'; 
import 'services/voice_service.dart';        

// --- Screens ---
import 'screens/splash_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/parent/profile_selector.dart';
import 'screens/parent/parent_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/parent/profile_wizard_screen.dart';
import 'screens/admin/admin_settings_screen.dart';

// --- Utils ---
import 'utils/app_colors.dart';

void main() async {
  // 1. Ensure Flutter bindings are ready
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase (Required before runApp)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Run the app inside a ChangeNotifierProvider for Global Theme Management
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: const LittleGeniusApp(),
    ),
  );
}

class LittleGeniusApp extends StatefulWidget {
  // Global Navigator Key: Allows NotificationService or AI Service 
  // to trigger navigation/dialogs without a BuildContext.
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
  // Initializes hardware and storage in parallel to prevent 
  // "App Scout Hangs" on heavy Android skins (MIUI/ColorOS).
  void _bootstrapApp() async {
    try {
      await Future.wait([
        // Retrieve last active session
        SharedPreferences.getInstance().then((prefs) {
          _savedChildId = prefs.getString('activeChildId');
        }),
        // Initialize Notification Channels and Permissions
        NotificationService().init(),
        // Warm up the TTS Engine for AI Tutor
        VoiceService().initTTS(),
      ]);
    } catch (e) {
      debugPrint("Initialization Error: $e");
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
          navigatorKey: LittleGeniusApp.navigatorKey, 
          debugShowCheckedModeBanner: false,
          
          // --- THEME CONFIGURATION ---
          // Uses Material 3 with a custom seed color based on the Parent Dashboard brand
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.ultraViolet,
              primary: AppColors.primaryBlue,
              secondary: AppColors.ultraViolet,
              surface: AppColors.backgroundWhite,
            ),
            fontFamily: 'Poppins',
            scaffoldBackgroundColor: AppColors.backgroundWhite,
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
            ),
          ),

          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.ultraViolet,
              brightness: Brightness.dark,
              primary: AppColors.primaryBlue,
              surface: const Color(0xFF0F172A),
            ),
            fontFamily: 'Poppins',
          ),
          
          themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          
          // Shows a clean loader until services are ready
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