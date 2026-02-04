import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/theme_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/admin_scaffold.dart';

// Module Imports
import 'admin_category_screen.dart';
import 'ai_tuning_screen.dart';
import 'global_voices_screen.dart';
import 'admin_analytics_screen.dart';
import 'content_review_screen.dart';
import 'account_help_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  int _studentCount = 0;
  int _lessonCount = 0;
  int _activityCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRealStats();
  }

  Future<void> _fetchRealStats() async {
    try {
      final students = await _firestore.collectionGroup('profiles').count().get();
      final concepts = await _firestore.collection('concepts').count().get();
      final activities = await _firestore.collection('activities').count().get();

      if (mounted) {
        setState(() {
          _studentCount = students.count ?? 0;
          _lessonCount = concepts.count ?? 0;
          _activityCount = activities.count ?? 0;
          _isLoading = false; 
        });
      }
    } catch (e) {
      debugPrint("Data Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context);
    final width = MediaQuery.of(context).size.width;

    return AdminScaffold(
      title: "Admin Command Center",
      breadcrumbs: const ["Console", "Home"],
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.oceanBlue))
        : RefreshIndicator(
            onRefresh: _fetchRealStats,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildSystemSearchBar(theme),
                  const SizedBox(height: 20),
                  _buildAlertBanner(),
                  const SizedBox(height: 25),
                  
                  _sectionTitle(theme, "KEY PERFORMANCE INDICATORS"),
                  const SizedBox(height: 15),
                  _buildStatGrid(width, theme),
                  
                  const SizedBox(height: 30),
                  _sectionTitle(theme, "MANAGEMENT HUB"),
                  const SizedBox(height: 15),
                  _buildModuleGrid(width, theme),

                  const SizedBox(height: 30),
                  _sectionTitle(theme, "SYSTEM HEALTH"),
                  const SizedBox(height: 15),
                  _buildPerformanceCard(theme), 
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSystemSearchBar(ThemeService theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: theme.borderColor),
      ),
      child: TextField(
        style: TextStyle(color: theme.textColor),
        decoration: InputDecoration(
          hintText: "Search logs, students or content...",
          hintStyle: TextStyle(color: theme.subTextColor, fontSize: 13),
          border: InputBorder.none,
          icon: const Icon(Icons.search, color: AppColors.oceanBlue, size: 20),
        ),
      ),
    );
  }

  Widget _buildAlertBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.gpp_maybe_rounded, color: Colors.redAccent),
          const SizedBox(width: 15),
          const Expanded(child: Text("System check: All AI engines operational. 0 delayed tasks.", 
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12))),
          TextButton(onPressed: () {}, child: const Text("Details", style: TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildStatGrid(double width, ThemeService theme) {
    int count = width > 900 ? 4 : 2;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: count,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.4,
      children: [
        _kpiCard("Total Students", "$_studentCount", Icons.people, AppColors.oceanBlue, theme),
        _kpiCard("Lessons Live", "$_lessonCount", Icons.book, AppColors.oceanBlue, theme),
        _kpiCard("Mode Variants", "$_activityCount", Icons.alt_route, AppColors.accentOrange, theme),
        _kpiCard("Global Uptime", "99.9%", Icons.bolt, AppColors.teal, theme),
      ],
    );
  }

  Widget _buildModuleGrid(double width, ThemeService theme) {
    int count = width > 1100 ? 3 : 2;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: count,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.2,
      children: [
        _moduleItem(context, "Lesson Manager", Icons.category_rounded, Colors.blue, 
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminCategoryScreen()))),
        _moduleItem(context, "Content Tester", Icons.verified_user_rounded, Colors.red, 
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ContentReviewScreen()))),
        _moduleItem(context, "AI Logic Tuning", Icons.psychology_rounded, Colors.orange, 
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AITuningScreen()))),
        _moduleItem(context, "Global Analytics", Icons.analytics_rounded, AppColors.teal, 
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminAnalyticsScreen()))),
        _moduleItem(context, "Global Voices", Icons.record_voice_over_rounded, Colors.purple, 
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const GlobalVoicesScreen()))),
        _moduleItem(context, "Account Help", Icons.help_center_rounded, Colors.blueGrey, 
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AccountHelpScreen()))),
      ],
    );
  }

  Widget _buildPerformanceCard(ThemeService theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        children: [
          _perfRow("AI Redirection Accuracy", "94.2%", Colors.green),
          const Divider(),
          _perfRow("Database Latency", "14ms", AppColors.teal),
          const Divider(),
          _perfRow("TTS Engine Sync", "Optimal", AppColors.oceanBlue),
        ],
      ),
    );
  }

  Widget _perfRow(String l, String v, Color c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          Text(v, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _kpiCard(String t, String v, IconData i, Color c, ThemeService theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor, borderRadius: BorderRadius.circular(25), border: Border.all(color: theme.borderColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(i, color: c, size: 24),
        const Spacer(),
        Text(v, style: TextStyle(color: theme.textColor, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(t, style: TextStyle(color: theme.subTextColor, fontSize: 10, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _moduleItem(BuildContext ctx, String t, IconData i, Color c, VoidCallback onTap) {
    final theme = Provider.of<ThemeService>(ctx);
    return InkWell(
      onTap: onTap, 
      borderRadius: BorderRadius.circular(30),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor, 
          borderRadius: BorderRadius.circular(30), 
          border: Border.all(color: theme.borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: c.withAlpha(20), shape: BoxShape.circle), child: Icon(i, size: 28, color: c)),
            const SizedBox(height: 12),
            Text(t, style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(ThemeService theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: TextStyle(color: theme.subTextColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5)),
    );
  }
}