import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/database_service.dart';
import '../../models/child_model.dart';
import '../../models/concept_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/parent_scaffold.dart';
import 'profile_wizard_screen.dart';
import 'child_insights_screen.dart';

class ParentDashboard extends StatefulWidget {
  final ChildProfile? specificChild;
  const ParentDashboard({super.key, this.specificChild});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  final db = DatabaseService();

  // Helper for dynamic colors in the category list
  Color _getDynamicCategoryColor(String name) {
    if (name.contains("Math") || name.contains("Numbers")) return Colors.blueAccent;
    if (name.contains("Reading") || name.contains("Alpha")) return Colors.purpleAccent;
    if (name.contains("Animals")) return Colors.green.shade400;
    if (name.contains("Shapes")) return Colors.orangeAccent;
    return Colors.teal;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Please Login")));

    return StreamBuilder<List<ChildProfile>>(
      stream: db.streamChildProfiles(user.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
        final profiles = snapshot.data ?? [];
        final activeChild = profiles.firstWhere(
          (p) => p.id == (widget.specificChild?.id ?? ""),
          orElse: () => profiles.isNotEmpty ? profiles.first : ChildProfile(
            id: '', name: 'No Profile', age: 0, childClass: '', language: '', avatarUrl: 'assets/icons/profiles/p1.png'
          ),
        );

        if (activeChild.id.isEmpty) return _buildNoChildView(context);

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: db.streamCategories(),
          builder: (context, catSnapshot) {
            return StreamBuilder<List<Concept>>(
              stream: db.streamConcepts(),
              builder: (context, conceptSnapshot) {
                final categories = catSnapshot.data ?? [];
                final concepts = conceptSnapshot.data ?? [];
                
                return ParentScaffold(
                  title: "Dashboard",
                  activeRoute: "overview",
                  child: activeChild,
                  body: Stack(
                    children: [
                      ListView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
                        children: [
                          _buildHeader(activeChild),
                          const SizedBox(height: 25),
                          _buildQuickStats(activeChild),
                          const SizedBox(height: 25),
                          _buildMasteryCard(activeChild, categories, concepts),
                          const SizedBox(height: 25),
                          _buildActivityChartSection(),
                          const SizedBox(height: 25),
                          _buildRecentActivity(activeChild, concepts),
                        ],
                      ),

                      // PREMIUM THEMED BUTTON
                      Positioned(
                        bottom: 20, left: 20, right: 20,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.ultraViolet,
                            foregroundColor: AppColors.lemonChiffon,
                            minimumSize: const Size(double.infinity, 65),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 8,
                            shadowColor: AppColors.ultraViolet.withOpacity(0.4),
                          ),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (c) => ChildInsightsScreen(child: activeChild)
                            ));
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("VIEW LEARNING INSIGHTS", 
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                              SizedBox(width: 10),
                              Icon(Icons.auto_awesome, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            );
          }
        );
      },
    );
  }

  // --- 1. PREMIUM HEADER ---
  Widget _buildHeader(ChildProfile child) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hello, ${child.parentName ?? 'Parent'}", 
              style: const TextStyle(
                fontSize: 28, 
                fontWeight: FontWeight.w900, 
                fontFamily: 'serif',
                color: AppColors.childNavy,
                letterSpacing: -0.5,
              )
            ),
            Text(
              "${child.name} is shining bright today!", 
              style: TextStyle(fontSize: 14, color: Colors.blueGrey.shade600, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ProfileWizardScreen(existingChild: child))),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.lemonChiffon,
              backgroundImage: AssetImage(child.avatarUrl),
            ),
          ),
        ),
      ],
    );
  }

  // --- 2. QUICK STATS ---
  Widget _buildQuickStats(ChildProfile child) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _statItem("STREAK", "${child.streak}", Icons.local_fire_department, Colors.orange, Colors.orange.shade50),
        _statItem("MINUTES", "${child.minutesSpentToday}", Icons.timer_rounded, Colors.blue, Colors.blue.shade50),
        _statItem("STARS", "${child.totalStars}", Icons.stars_rounded, Colors.amber, Colors.amber.shade50),
      ],
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color, Color bg) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.28,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  // --- 3. MASTERY CARD (ALL CATEGORIES) ---
  Widget _buildMasteryCard(ChildProfile child, List<Map<String, dynamic>> categories, List<Concept> concepts) {
    double totalMastery = child.masteryScores.isEmpty ? 0.0 : 
      child.masteryScores.values.reduce((a, b) => a + b) / child.masteryScores.length;

    final activeCategories = categories.where((cat) {
      final ids = concepts.where((c) => c.category == cat['name']).map((c) => c.id).toList();
      return ids.any((id) => child.masteryScores.containsKey(id));
    }).toList();

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)],
      ),
      child: Column(
        children: [
          CircularPercentIndicator(
            radius: 60.0, lineWidth: 12.0, percent: totalMastery,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("${(totalMastery * 100).toInt()}%", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const Text("TOTAL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              ],
            ),
            progressColor: Colors.pinkAccent, backgroundColor: Colors.pink.shade50,
            circularStrokeCap: CircularStrokeCap.round, animation: true,
          ),
          const SizedBox(height: 25),
          const Align(alignment: Alignment.centerLeft, child: Text("Subject Breakdown", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          const SizedBox(height: 15),
          ...activeCategories.map((cat) {
            double avg = _calculateCategoryAvg(child, cat['name'], concepts);
            return _colorfulProgress(cat['name'], avg, _getDynamicCategoryColor(cat['name']));
          }),
        ],
      ),
    );
  }

  // --- 4. MODERN PARENT-FRIENDLY GRAPH ---
  Widget _buildActivityChartSection() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(35),
        boxShadow: [BoxShadow(color: AppColors.ultraViolet.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Weekly Journey", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.childNavy)),
                  Text("Minutes spent learning", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.lemonChiffon, borderRadius: BorderRadius.circular(12)),
                child: const Row(children: [Icon(Icons.check_circle, size: 14, color: AppColors.ultraViolet), SizedBox(width: 4), Text("Healthy Zone", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.ultraViolet))]),
              )
            ],
          ),
          const SizedBox(height: 30),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, m) => Text("${v.toInt()}m", style: const TextStyle(color: Colors.grey, fontSize: 10)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                    return Text(days[v.toInt() % 7], style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12));
                  })),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 15), FlSpot(1, 25), FlSpot(2, 20), FlSpot(3, 40), FlSpot(4, 30), FlSpot(5, 45), FlSpot(6, 35)],
                    isCurved: true, color: AppColors.ultraViolet, barWidth: 5, isStrokeCapRound: true,
                    dotData: FlDotData(show: true, getDotPainter: (s, p, b, i) => FlDotCirclePainter(radius: 4, color: Colors.white, strokeWidth: 3, strokeColor: AppColors.ultraViolet)),
                    belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [AppColors.ultraViolet.withOpacity(0.2), AppColors.lemonChiffon.withOpacity(0.4), Colors.white.withOpacity(0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 5. RECENT ADVENTURES ---
  Widget _buildRecentActivity(ChildProfile child, List<Concept> concepts) {
    final recentEntries = child.masteryScores.entries.toList().reversed.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Recent Activity", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.childNavy)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ChildInsightsScreen(child: child))),
              child: const Text("View All", style: TextStyle(color: AppColors.ultraViolet, fontWeight: FontWeight.bold)),
            )
          ],
        ),
        if (recentEntries.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No adventures yet!")))
        else
          ...recentEntries.map((entry) {
            final concept = concepts.firstWhere((c) => c.id == entry.key, orElse: () => Concept(id: '', name: 'Learning...', category: 'General', order: 0));
            return _activityTile(concept.name, concept.category, entry.value);
          }),
      ],
    );
  }

  // --- UI HELPER: PROGRESS BARS ---
  Widget _colorfulProgress(String label, double val, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text("${(val * 100).toInt()}%", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          LinearPercentIndicator(
            lineHeight: 10.0, percent: val, progressColor: color, backgroundColor: color.withOpacity(0.1),
            barRadius: const Radius.circular(20), padding: EdgeInsets.zero, animation: true,
          ),
        ],
      ),
    );
  }

  // --- UI HELPER: RECENT ACTIVITY TILES ---
  Widget _activityTile(String title, String category, double score) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        border: Border.all(color: AppColors.ultraViolet.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            height: 50, width: 50, decoration: BoxDecoration(color: AppColors.lemonChiffon, borderRadius: BorderRadius.circular(15)),
            child: const Center(child: Icon(Icons.auto_awesome_rounded, color: AppColors.ultraViolet, size: 24)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(category.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.ultraViolet.withOpacity(0.6))),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text("${(score * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.ultraViolet)),
            const Text("MASTERED", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
          ]),
        ],
      ),
    );
  }

  double _calculateCategoryAvg(ChildProfile child, String catName, List<Concept> concepts) {
    final ids = concepts.where((c) => c.category == catName).map((c) => c.id).toList();
    if (ids.isEmpty) return 0.0;
    double sum = 0; int count = 0;
    for (var id in ids) { if (child.masteryScores.containsKey(id)) { sum += child.masteryScores[id]!; count++; } }
    return count == 0 ? 0.0 : sum / count;
  }

  Widget _buildNoChildView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lemonChiffon,
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.ultraViolet),
          onPressed: () => Navigator.pushNamed(context, '/add_child'), 
          child: const Text("CREATE PROFILE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
        )
      ),
    );
  }
}