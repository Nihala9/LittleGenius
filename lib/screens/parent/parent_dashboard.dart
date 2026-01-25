import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/database_service.dart';
import '../../models/child_model.dart';
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
      appBar: AppBar(title: const Text("Parent Dashboard"), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: StreamBuilder<List<ChildProfile>>(
        stream: db.streamChildProfiles(user!.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final profiles = snapshot.data!;
          final activeChild = specificChild ?? (profiles.isNotEmpty ? profiles.first : null);

          if (activeChild == null) return const Center(child: Text("Please create a profile first."));

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _header(activeChild, context),
              const SizedBox(height: 20),
              _action(context, "AI Learning Insights", Icons.auto_graph, () => Navigator.push(context, MaterialPageRoute(builder: (c) => ChildInsightsScreen(child: activeChild)))),
              _action(context, "Switch Child", Icons.people_outline, () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('activeChildId');
                Navigator.pushNamedAndRemoveUntil(context, '/profile_selector', (r) => false);
              }),
              const Divider(),
              _action(context, "Logout Parent Account", Icons.logout, () async {
                await FirebaseAuth.instance.signOut();
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.pushNamedAndRemoveUntil(context, '/landing', (r) => false);
              }, color: Colors.red),
            ],
          );
        },
      ),
    );
  }

  Widget _header(ChildProfile c, BuildContext context) => Container(
    padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
    child: Row(children: [
      CircleAvatar(radius: 30, backgroundImage: NetworkImage(c.avatarUrl)),
      const SizedBox(width: 15),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text("Native Language: ${c.language}")])),
      IconButton(icon: const Icon(Icons.edit), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (cContext) => ProfileWizardScreen(existingChild: c)))),
    ]),
  );

  Widget _action(BuildContext context, String t, IconData i, VoidCallback onTap, {Color? color}) => ListTile(
    leading: Icon(i, color: color ?? Colors.indigo),
    title: Text(t, style: TextStyle(color: color)),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}