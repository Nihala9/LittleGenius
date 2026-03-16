import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/theme_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/admin_scaffold.dart';

// Module Imports
import 'admin_category_screen.dart';
import 'ai_tuning_screen.dart';
import 'admin_analytics_screen.dart';
import 'content_review_screen.dart';
import 'account_help_screen.dart';
import 'admin_story_manager.dart'; 

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  int _studentCount = 0;
  int _lessonCount = 0;
  int _totalStars = 0;
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
      
      // Calculate total rewards issued across all child profiles
      final starQuery = await _firestore.collectionGroup('profiles').get();
      int stars = 0;
      for (var doc in starQuery.docs) {
        stars += (doc.data()['totalStars'] as int? ?? 0);
      }

      if (mounted) {
        setState(() {
          _studentCount = students.count ?? 0;
          _lessonCount = concepts.count ?? 0;
          _totalStars = stars;
          _isLoading = false; 
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context);

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
                  const SizedBox(height: 15),
                  _buildSystemSearchBar(theme),
                  const SizedBox(height: 30),
                  
                  _sectionTitle(theme, "PLATFORM VITAL SIGNS"),
                  const SizedBox(height: 20),
                  
                  // --- REFINED KPI GRID (NO UNUSED VARIABLES) ---
                  _buildKpiGrid(theme),
                  
                  const SizedBox(height: 40),
                  _sectionTitle(theme, "MANAGEMENT HUB"),
                  const SizedBox(height: 20),
                  _buildModuleGrid(theme),

                  const SizedBox(height: 30),
                  _sectionTitle(theme, "SYSTEM HEALTH"),
                  const SizedBox(height: 15),
                  _buildHealthMonitor(theme), 
                  
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
    );
  }

  // --- 1. KPI GRID ---
  Widget _buildKpiGrid(ThemeService theme) {
    return Column(
      children: [
        // Primary Metric: Full Width Hero Card
        _kpiHeroCard(
          "Active Students", 
          "$_studentCount", 
          Icons.people_alt_rounded, 
          AppColors.oceanBlue, 
          "Total registered profiles",
          theme
        ),
        const SizedBox(height: 15),
        // Secondary Metrics: Side-by-side
        Row(
          children: [
            Expanded(
              child: _kpiMiniCard("Stars Won", "$_totalStars", Icons.stars_rounded, Colors.amber, theme)
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _kpiMiniCard("Live Items", "$_lessonCount", Icons.auto_stories_rounded, AppColors.teal, theme)
            ),
          ],
        ),
      ],
    );
  }

  Widget _kpiHeroCard(String title, String value, IconData icon, Color color, String footer, ThemeService theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withAlpha(180)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: color.withAlpha(40), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
              Icon(icon, color: Colors.white24, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(footer, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _kpiMiniCard(String title, String value, IconData icon, Color color, ThemeService theme) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(color: theme.textColor, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: theme.subTextColor, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // --- 2. MANAGEMENT HUB ---
  Widget _buildModuleGrid(ThemeService theme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2, 
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.3,
      children: [
        _moduleItem("Lessons", Icons.category_rounded, Colors.blue, 
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminCategoryScreen()))),
        _moduleItem("Tester", Icons.verified_user_rounded, Colors.red, 
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ContentReviewScreen()))),
        _moduleItem("Stories", Icons.video_library_rounded, Colors.redAccent, 
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminStoryManager()))),
        _moduleItem("AI Tuning", Icons.psychology_rounded, Colors.orange, 
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AITuningScreen()))),
        _moduleItem("Analytics", Icons.analytics_rounded, AppColors.teal, 
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminAnalyticsScreen()))),
        _moduleItem("Accounts", Icons.help_center_rounded, Colors.blueGrey, 
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AccountHelpScreen()))),
      ],
    );
  }

  Widget _moduleItem(String t, IconData i, Color c, VoidCallback onTap) {
    final theme = Provider.of<ThemeService>(context);
    return InkWell(
      onTap: onTap, 
      borderRadius: BorderRadius.circular(25),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor, 
          borderRadius: BorderRadius.circular(25), 
          border: Border.all(color: theme.borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(i, size: 26, color: c),
            const SizedBox(height: 10),
            Text(t, style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // --- 3. HEALTH & SEARCH ---

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
          hintText: "Search content or students...",
          hintStyle: TextStyle(color: theme.subTextColor, fontSize: 14),
          border: InputBorder.none,
          icon: const Icon(Icons.search, color: AppColors.oceanBlue, size: 20),
        ),
      ),
    );
  }

  Widget _buildHealthMonitor(ThemeService theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        children: [
          _healthRow("AI Logic Engine", "Optimal", Colors.green),
          const Divider(height: 30),
          _healthRow("Cloud Database", "12ms", AppColors.teal),
        ],
      ),
    );
  }

  Widget _healthRow(String l, String v, Color c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: c)),
            const SizedBox(width: 8),
            Text(v, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _sectionTitle(ThemeService theme, String title) {
    return Text(title, style: TextStyle(color: theme.subTextColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5));
  }
}