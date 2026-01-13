import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import 'activity_manager.dart';
import 'activity_wizard.dart';
import 'concept_manager.dart';
import 'ai_configurator.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  Future<int> _getCount(String collection) async {
    if (collection == 'users') {
      var snapshot = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'parent').count().get();
      return snapshot.count ?? 0;
    }
    var snapshot = await FirebaseFirestore.instance.collection(collection).count().get();
    return snapshot.count ?? 0;
  }

  Future<String> _getAvgMastery() async {
    var snapshot = await FirebaseFirestore.instance.collection('children').get();
    if (snapshot.docs.isEmpty) return "0%";
    double total = 0; int count = 0;
    for (var doc in snapshot.docs) {
      Map<String, dynamic> scores = Map<String, dynamic>.from(doc.data()['masteryScores'] ?? {});
      scores.forEach((key, value) { total += (value as num).toDouble(); count++; });
    }
    return count == 0 ? "0%" : "${((total / count) * 100).toStringAsFixed(0)}%";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("LittleGenius Console", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white, foregroundColor: const Color(0xFF1E293B), elevation: 0,
      ),
      drawer: _buildAdminDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Dashboard Overview", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            FutureBuilder(
              future: Future.wait([_getCount('activities'), _getCount('children'), _getCount('users'), _getAvgMastery()]),
              builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                return GridView.count(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.1,
                  children: [
                    _buildKPICard("Content", snapshot.data![0].toString(), Icons.book_rounded, Colors.blue),
                    _buildKPICard("Students", snapshot.data![1].toString(), Icons.face_rounded, Colors.orange),
                    _buildKPICard("Parents", snapshot.data![2].toString(), Icons.people_rounded, Colors.green),
                    _buildKPICard("Avg score", snapshot.data![3].toString(), Icons.auto_graph_rounded, Colors.purple),
                  ],
                );
              },
            ),
            const SizedBox(height: 30),
            _buildActionTile(context, "Content Manager", "Manage global activities", Icons.library_books, const Color(0xFF6366F1), const ActivityManager()),
            _buildActionTile(context, "Concept Mapping", "Define AI goals & targets", Icons.map_rounded, const Color(0xFF0D9488), const ConceptManager()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ActivityWizard())),
        label: const Text("New Activity", style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add), backgroundColor: const Color(0xFF0D9488),
      ),
    );
  }

  Widget _buildKPICard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(children: [
        Icon(icon, color: color, size: 20), const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
          children: [Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11))]))
      ]),
    );
  }

  Widget _buildActionTile(BuildContext context, String title, String sub, IconData icon, Color color, Widget target) {
    return Card(
      elevation: 0, margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFF1F5F9))),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => target)),
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      ),
    );
  }

  Widget _buildAdminDrawer(BuildContext context) {
    return Drawer(
      child: Column(children: [
        Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(20, 60, 20, 30), color: const Color(0xFF1E293B),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.auto_awesome, color: Colors.indigoAccent, size: 35),
            SizedBox(height: 10), Text("LittleGenius", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ])),
        ListTile(leading: const Icon(Icons.grid_view_rounded), title: const Text("Overview"), onTap: () => Navigator.pop(context)),
        ListTile(leading: const Icon(Icons.map_rounded), title: const Text("Concepts"), onTap: () => Navigator.pushNamed(context, '/concepts')),
        const Spacer(),
        ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("Sign Out"), onTap: () => AuthService().logout().then((_) => Navigator.pushReplacementNamed(context, '/login'))),
      ]),
    );
  }
}