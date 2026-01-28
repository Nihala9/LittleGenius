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

  void _confirmDelete(BuildContext context, String parentId, ChildProfile child) {
    showDialog(context: context, builder: (ctx) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Text("Delete Profile?", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), content: Text("Are you sure you want to delete ${child.name}?"), actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () async {
        await DatabaseService().deleteChildProfile(parentId, child.id);
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getString('activeChildId') == child.id) await prefs.remove('activeChildId');
        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/profile_selector', (r) => false);
      }, child: const Text("Delete", style: TextStyle(color: Colors.white))),
    ]));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final db = DatabaseService();

    return Scaffold(
      backgroundColor: AppColors.lemonChiffon,
      appBar: AppBar(title: const Text("PARENTAL CONTROL", style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.w900, fontSize: 14)), backgroundColor: Colors.white, foregroundColor: AppColors.ultraViolet, elevation: 0, centerTitle: true),
      body: StreamBuilder<List<ChildProfile>>(
        stream: db.streamChildProfiles(user!.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.ultraViolet));
          final profiles = snapshot.data!;
          final activeChild = profiles.firstWhere((p) => p.id == (specificChild?.id ?? (profiles.isNotEmpty ? profiles.first.id : "")), orElse: () => profiles.first);

          return ListView(padding: const EdgeInsets.all(25), children: [
            _buildIdentityCard(context, activeChild, user.uid),
            const SizedBox(height: 30),
            _buildActionTile(context, "AI Learning Insights", "View mastery analysis", Icons.auto_graph, () => Navigator.push(context, MaterialPageRoute(builder: (c) => ChildInsightsScreen(child: activeChild)))),
            _buildActionTile(context, "Switch Profile", "Change active user", Icons.swap_horizontal_circle, () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('activeChildId');
              Navigator.pushNamedAndRemoveUntil(context, '/profile_selector', (r) => false);
            }),
            _buildActionTile(context, "Delete Profile", "Remove this child", Icons.delete_forever, () => _confirmDelete(context, user.uid, activeChild), isCritical: true),
            const Divider(height: 40),
            _buildActionTile(context, "Logout Parent Account", "Sign out", Icons.logout, () async {
              await FirebaseAuth.instance.signOut();
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pushNamedAndRemoveUntil(context, '/landing', (r) => false);
            }, isCritical: true),
          ]);
        },
      ),
    );
  }

  Widget _buildIdentityCard(BuildContext context, ChildProfile child, String uid) {
    Color badgeColor = Color(int.parse(child.toMap()['profileColor'] ?? "0xFF80B3FF"));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.ultraViolet, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: AppColors.ultraViolet.withAlpha(80), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Row(children: [
        CircleAvatar(radius: 35, backgroundColor: badgeColor, child: Text(child.toMap()['profileEmoji'] ?? "⭐", style: const TextStyle(fontSize: 35))),
        const SizedBox(width: 20),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(child.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), Text("Age ${child.age} • ${child.language}", style: const TextStyle(color: Colors.white70, fontSize: 13))])),
        IconButton(icon: const Icon(Icons.edit_square, color: AppColors.lemonChiffon), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ProfileWizardScreen(existingChild: child)))),
      ]),
    );
  }

  Widget _buildActionTile(BuildContext context, String t, String s, IconData i, VoidCallback onTap, {bool isCritical = false}) => Card(elevation: 0, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), child: ListTile(onTap: onTap, leading: CircleAvatar(backgroundColor: isCritical ? Colors.red.shade50 : AppColors.lemonChiffon, child: Icon(i, color: isCritical ? Colors.red : AppColors.ultraViolet, size: 20)), title: Text(t, style: TextStyle(fontWeight: FontWeight.bold, color: isCritical ? Colors.red : AppColors.textDark)), subtitle: Text(s, style: const TextStyle(fontSize: 12)), trailing: const Icon(Icons.chevron_right, size: 16)));
}