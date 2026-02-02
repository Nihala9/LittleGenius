import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/database_service.dart';
import '../../models/child_model.dart';
import '../../utils/app_colors.dart';
import 'child_insights_screen.dart';
import 'profile_wizard_screen.dart';
import 'screen_time_settings.dart'; // ADDED IMPORT

class ParentDashboard extends StatelessWidget {
  final ChildProfile? specificChild;
  const ParentDashboard({super.key, this.specificChild});

  void _confirmDelete(BuildContext context, String parentId, ChildProfile child) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Profile?", 
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete ${child.name}? This will permanently erase all progress."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DatabaseService().deleteChildProfile(parentId, child.id);
              final prefs = await SharedPreferences.getInstance();
              if (prefs.getString('activeChildId') == child.id) {
                await prefs.remove('activeChildId');
              }
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/profile_selector', (r) => false);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final db = DatabaseService();

    return Scaffold(
      backgroundColor: AppColors.lemonChiffon,
      appBar: AppBar(
        title: const Text("PARENTAL CONTROL", 
            style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.w900, fontSize: 14)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ultraViolet,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<ChildProfile>>(
        stream: db.streamChildProfiles(user!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.ultraViolet));
          }
          
          final profiles = snapshot.data ?? [];
          final activeChild = profiles.firstWhere(
            (p) => p.id == (specificChild?.id ?? (profiles.isNotEmpty ? profiles.first.id : "")),
            orElse: () => profiles.isNotEmpty ? profiles.first : ChildProfile(
              id: '', name: 'No Profile', age: 0, childClass: '', language: '', avatarUrl: 'assets/icons/profiles/p1.png'
            ),
          );

          if (activeChild.id.isEmpty) return _buildNoChildView(context);

          return ListView(
            padding: const EdgeInsets.all(25),
            children: [
              _buildIdentityCard(context, activeChild),
              const SizedBox(height: 30),
              
              const Text("CORE PROGRESS", 
                  style: TextStyle(color: AppColors.ultraViolet, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
              const SizedBox(height: 15),
              _buildStats(activeChild),
              
              const SizedBox(height: 30),
              const Text("MANAGEMENT", 
                  style: TextStyle(color: AppColors.ultraViolet, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
              const SizedBox(height: 15),
              
              _buildActionTile(
                context, 
                "AI Learning Insights", 
                "View mastery & performance analysis", 
                Icons.auto_graph, 
                () => Navigator.push(context, MaterialPageRoute(builder: (c) => ChildInsightsScreen(child: activeChild))),
              ),

              // --- NEW SCREEN TIME TILE ---
              _buildActionTile(
                context, 
                "Screen Time Settings", 
                "Set daily usage limits for ${activeChild.name}", 
                Icons.timer_rounded, 
                () => Navigator.push(context, MaterialPageRoute(builder: (c) => ScreenTimeSettingsScreen(child: activeChild))),
              ),
              
              _buildActionTile(
                context, 
                "Switch Child Profile", 
                "Return to profile selection", 
                Icons.swap_horizontal_circle_outlined, 
                () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('activeChildId');
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(context, '/profile_selector', (r) => false);
                }
              ),

              _buildActionTile(
                context, 
                "Delete Profile", 
                "Permanently remove this child", 
                Icons.delete_forever_rounded, 
                () => _confirmDelete(context, user.uid, activeChild),
                isRed: true,
              ),

              const Divider(height: 40),

              _buildActionTile(
                context, 
                "Logout Parent Account", 
                "Sign out of LittleGenius", 
                Icons.logout, 
                () async {
                  await FirebaseAuth.instance.signOut();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(context, '/landing', (r) => false);
                },
                isRed: true,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIdentityCard(BuildContext context, ChildProfile child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.ultraViolet,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35, 
            backgroundColor: Colors.white,
            backgroundImage: AssetImage(child.avatarUrl),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(child.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                Text("${child.childClass} • ${child.language}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_square, color: AppColors.lemonChiffon),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (c) => ProfileWizardScreen(existingChild: child))),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(ChildProfile child) {
    double avg = child.masteryScores.isEmpty ? 0 : 
        child.masteryScores.values.reduce((a, b) => a + b) / child.masteryScores.length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: Column(
        children: [
          _statRow("General Mastery", avg),
          const Divider(height: 30),
          _statRow("Star Progress", (child.totalStars / 1000).clamp(0.0, 1.0), label: "${child.totalStars} Stars"),
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

  Widget _buildActionTile(BuildContext context, String t, String s, IconData i, VoidCallback onTap, {bool isRed = false}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: isRed ? Colors.red.withAlpha(20) : AppColors.lemonChiffon,
          child: Icon(i, color: isRed ? Colors.red : AppColors.ultraViolet, size: 20),
        ),
        title: Text(t, style: TextStyle(fontWeight: FontWeight.bold, color: isRed ? Colors.red : AppColors.textDark)),
        subtitle: Text(s, style: const TextStyle(fontSize: 12)),
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
          const Text("No profile found.", style: TextStyle(fontWeight: FontWeight.bold)),
          TextButton(onPressed: () => Navigator.pushNamed(context, '/add_child'), child: const Text("Create a Profile"))
        ],
      ),
    );
  }
}