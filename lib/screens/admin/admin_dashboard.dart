import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/theme_service.dart';
import '../../utils/app_colors.dart';
import 'admin_category_screen.dart';
import 'ai_tuning_screen.dart';
import 'account_help_screen.dart';
import 'content_review_screen.dart';
import 'admin_analytics_screen.dart';
import 'global_voices_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int totalStudents = 0;
  int totalLessons = 0;
  int totalActivities = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final students = await _firestore.collectionGroup('profiles').count().get();
    final concepts = await _firestore.collection('concepts').count().get();
    final activities = await _firestore.collection('activities').count().get();

    if (mounted) {
      setState(() {
        totalStudents = students.count ?? 0;
        totalLessons = concepts.count ?? 0;
        totalActivities = activities.count ?? 0;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context);

    return Scaffold(
      backgroundColor: theme.bgColor,
      appBar: AppBar(
        title: Text("ADMIN COMMAND CENTER", style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 13, color: theme.textColor)),
        backgroundColor: theme.cardColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(theme.isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round, color: AppColors.accentOrange),
            onPressed: () => theme.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/landing');
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader("System Overview", theme.textColor),
            _statsRow(theme),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15), child: Text("MANAGEMENT MODULES", style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.5))),
            _buildGrid(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String text, Color color) => Container(padding: const EdgeInsets.all(25), child: Text(text, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.bold)));

  Widget _statsRow(ThemeService theme) => SizedBox(height: 120, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.only(left: 20), children: [
    _statCard("Students", "$totalStudents", Icons.people, Colors.blue, theme),
    _statCard("Lessons", "$totalLessons", Icons.book, Colors.amber, theme),
    _statCard("Activities", "$totalActivities", Icons.bolt, Colors.purpleAccent, theme),
  ]));

  Widget _statCard(String l, String v, IconData i, Color c, ThemeService theme) => Container(
    width: 150, margin: const EdgeInsets.only(right: 15), padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: theme.borderColor)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(i, color: c, size: 20), const Spacer(), Text(v, style: TextStyle(color: theme.textColor, fontSize: 20, fontWeight: FontWeight.bold)), Text(l, style: TextStyle(color: theme.subTextColor, fontSize: 11))]),
  );

  Widget _buildGrid(BuildContext context, ThemeService theme) => GridView.count(
    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 20),
    crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15,
    children: [
      _item(context, "Lesson Manager", Icons.category, theme, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminCategoryScreen()))),
      _item(context, "AI Logic", Icons.psychology, theme, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AITuningScreen()))),
      _item(context, "Voices", Icons.record_voice_over, theme, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const GlobalVoicesScreen()))),
      _item(context, "Analytics", Icons.analytics, theme, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminAnalyticsScreen()))),
      _item(context, "Review", Icons.verified_user, theme, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ContentReviewScreen()))),
      _item(context, "Support", Icons.help, theme, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AccountHelpScreen()))),
    ],
  );

  Widget _item(BuildContext ctx, String t, IconData i, ThemeService theme, VoidCallback onTap) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(28),
    child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(28), border: Border.all(color: theme.borderColor)),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, size: 30, color: AppColors.primaryBlue), const SizedBox(height: 12), Text(t, textAlign: TextAlign.center, style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 13))])),
  );
}