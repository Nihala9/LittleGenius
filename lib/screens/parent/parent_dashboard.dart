import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/database_service.dart';
import '../../models/child_model.dart';
import '../../utils/app_colors.dart';
import 'child_insights_screen.dart';
import 'profile_wizard_screen.dart';

class ParentDashboard extends StatelessWidget {
  final ChildProfile? specificChild;
  const ParentDashboard({super.key, this.specificChild});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final db = DatabaseService();

    return Scaffold(
      backgroundColor: AppColors.lemonChiffon, // Approachable warm background
      appBar: AppBar(
        title: const Text("PARENTAL CONTROL", 
          style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.w900, fontSize: 14)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ultraViolet,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<ChildProfile>>(
        stream: db.streamChildProfiles(user!.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.ultraViolet));
          
          final profiles = snapshot.data!;
          final activeChild = specificChild ?? (profiles.isNotEmpty ? profiles.first : null);

          if (activeChild == null) return _buildNoChildView(context);

          return ListView(
            padding: const EdgeInsets.all(25),
            children: [
              _buildChildIdentityCard(context, activeChild),
              const SizedBox(height: 30),
              
              const Text("CORE PROGRESS", 
                style: TextStyle(color: AppColors.ultraViolet, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
              const SizedBox(height: 15),
              _buildMasteryStats(activeChild),
              
              const SizedBox(height: 30),
              const Text("MANAGEMENT", 
                style: TextStyle(color: AppColors.ultraViolet, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
              const SizedBox(height: 15),
              
              _buildActionTile(
                context, "AI Learning Insights", "View mastery & AI analysis", Icons.auto_graph, 
                () => Navigator.push(context, MaterialPageRoute(builder: (c) => ChildInsightsScreen(child: activeChild)))
              ),
              _buildActionTile(
                context, "Switch Child Profile", "Change the active user", Icons.swap_horizontal_circle_outlined, 
                () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('activeChildId');
                  Navigator.pushNamedAndRemoveUntil(context, '/profile_selector', (r) => false);
                }
              ),
              _buildActionTile(
                context, "Logout Account", "Sign out of LittleGenius", Icons.logout, 
                () async {
                  await FirebaseAuth.instance.signOut();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  Navigator.pushNamedAndRemoveUntil(context, '/landing', (r) => false);
                },
                isCritical: true,
              ),
            ],
          );
        },
      ),
    );
  }

  // 1. HEADER: CHILD IDENTITY CARD
  Widget _buildChildIdentityCard(BuildContext context, ChildProfile child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.ultraViolet, // Primary Brand Color
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: AppColors.ultraViolet.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35, 
            backgroundColor: Colors.white24,
            backgroundImage: NetworkImage(child.avatarUrl),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(child.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                Text("Age ${child.age} • ${child.language}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_square, color: AppColors.lemonChiffon),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ProfileWizardScreen(existingChild: child))),
          ),
        ],
      ),
    );
  }

  // 2. PROGRESS: STRUCTURED MASTERY STATS
  Widget _buildMasteryStats(ChildProfile child) {
    // Logic for average calculation
    double avg = child.masteryScores.isEmpty ? 0 : 
      child.masteryScores.values.reduce((a, b) => a + b) / child.masteryScores.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: Column(
        children: [
          _statRow("General Knowledge", avg),
          const Divider(height: 30),
          _statRow("Star Collection", (child.totalStars / 500).clamp(0.0, 1.0), label: "${child.totalStars} Stars"),
        ],
      ),
    );
  }

  Widget _statRow(String title, double val, {String? label}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
            Text(label ?? "${(val * 100).toInt()}%", style: const TextStyle(color: AppColors.ultraViolet, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: val,
            minHeight: 10,
            backgroundColor: AppColors.lemonChiffon,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.ultraViolet),
          ),
        )
      ],
    );
  }

  // 3. ACTIONS: LIST TILES
  Widget _buildActionTile(BuildContext context, String title, String sub, IconData icon, VoidCallback onTap, {bool isCritical = false}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: isCritical ? Colors.red.shade50 : AppColors.lemonChiffon,
          child: Icon(icon, color: isCritical ? Colors.red : AppColors.ultraViolet, size: 20),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isCritical ? Colors.red : AppColors.textDark)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 16),
      ),
    );
  }

  Widget _buildNoChildView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.child_care, size: 80, color: AppColors.ultraViolet),
          const SizedBox(height: 20),
          const Text("No child profile selected.", style: TextStyle(fontWeight: FontWeight.bold)),
          TextButton(onPressed: () => Navigator.pushNamed(context, '/profile_selector'), child: const Text("Go to Selector"))
        ],
      ),
    );
  }
}