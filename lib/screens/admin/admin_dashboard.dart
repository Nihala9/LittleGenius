import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import 'activity_manager.dart';
import 'activity_wizard.dart';
import 'ai_configurator.dart';
import 'concept_manager.dart'; // IMPORT the new manager

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  // --- DATABASE AGGREGATION LOGIC ---

  Future<int> _getCount(String collection) async {
    if (collection == 'users') {
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'parent')
          .count()
          .get();
      return snapshot.count ?? 0;
    } else {
      var snapshot = await FirebaseFirestore.instance.collection(collection).count().get();
      return snapshot.count ?? 0;
    }
  }

  Future<String> _getAvgMastery() async {
    var snapshot = await FirebaseFirestore.instance.collection('children').get();
    if (snapshot.docs.isEmpty) return "0%";
    double total = 0;
    int count = 0;
    for (var doc in snapshot.docs) {
      Map<String, dynamic> scores = doc.data()['masteryScores'] ?? {};
      scores.forEach((key, value) {
        total += (value as num).toDouble();
        count++;
      });
    }
    return count == 0 ? "0%" : "${((total / count) * 100).toStringAsFixed(0)}%";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("LittleGenius Admin", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => AuthService().logout().then((_) => Navigator.pushReplacementNamed(context, '/login')),
          ),
        ],
      ),
      drawer: _buildAdminDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("System Overview", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text("Real-time analytics from AI Engine", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 25),

            // LIVE KPI GRID
            FutureBuilder(
              future: Future.wait([
                _getCount('activities'),
                _getCount('children'),
                _getCount('users'),
                _getAvgMastery(),
              ]),
              builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                if (!snapshot.hasData) return const Center(child: LinearProgressIndicator());
                
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1, 
                  children: [
                    _buildKPICard("Learning Content", snapshot.data![0].toString(), Icons.menu_book, Colors.blue),
                    _buildKPICard("Active Children", snapshot.data![1].toString(), Icons.face, Colors.orange),
                    _buildKPICard("Registered Parents", snapshot.data![2].toString(), Icons.people_alt, Colors.green),
                    _buildKPICard("Avg. Learning Score", snapshot.data![3].toString(), Icons.auto_awesome, Colors.purple),
                  ],
                );
              },
            ),

            const SizedBox(height: 35),
            const Text("Quick Management", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // 1. CONTENT MANAGER
            _buildActionCard(context, "Content Lifecycle Management", "Edit or publish activities.", Icons.library_books, Colors.indigo, const ActivityManager()),
            
            // 2. CONCEPT MANAGER (The New Addition)
            _buildActionCard(context, "Educational Concept Mapping", "Define learning goals and AI targets.", Icons.map_outlined, Colors.teal, const ConceptManager()),

            // 3. AI RULES
            _buildActionCard(context, "AI Personalization Rules", "Configure AI thresholds.", Icons.psychology, const Color(0xFFE11D48), const AIConfigurator()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ActivityWizard())),
        label: const Text("Launch Activity Wizard"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildKPICard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(backgroundColor: color.withOpacity(0.1), radius: 18, child: Icon(icon, color: color, size: 18)),
          const SizedBox(height: 8),
          FittedBox(child: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String sub, IconData icon, Color color, Widget target) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => target)),
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 12),
      ),
    );
  }

  Widget _buildAdminDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Colors.indigo),
            accountName: Text("Admin"),
            accountEmail: Text("admin@littlegenius.ai"),
            currentAccountPicture: CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.admin_panel_settings, color: Colors.indigo)),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined), 
            title: const Text("Overview"), 
            onTap: () => Navigator.pop(context)
          ),
          ListTile(
            leading: const Icon(Icons.map_outlined), 
            title: const Text("Concept Manager"), 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ConceptManager()))
          ),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined), 
            title: const Text("Activity Manager"), 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ActivityManager()))
          ),
          ListTile(
            leading: const Icon(Icons.settings_suggest_outlined), 
            title: const Text("AI Rules"), 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AIConfigurator()))
          ),
        ],
      ),
    );
  }
}