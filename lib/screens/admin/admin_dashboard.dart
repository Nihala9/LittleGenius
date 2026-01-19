import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; 
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import 'activity_wizard.dart'; // USED in FAB
import 'activity_manager.dart'; // USED in Sidebar
import 'concept_manager.dart';  // USED in Sidebar
import 'ai_configurator.dart';  // USED in Sidebar

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Color brandIndigo = const Color(0xFF5D5FEF);

  // --- REAL DATA AGGREGATION LOGIC ---
  Future<Map<String, dynamic>> _fetchDashboardData() async {
    try {
      final childrenSnap = await FirebaseFirestore.instance.collection('children').get();
      final activitySnap = await FirebaseFirestore.instance.collection('activities').get();
      final parentSnap = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'parent').get();
      
      double totalMasterySum = 0; 
      int scoreCount = 0; 
      int interventions = 0; 

      for (var doc in childrenSnap.docs) {
        Map<String, dynamic> scores = Map<String, dynamic>.from(doc.data()['masteryScores'] ?? {});
        scores.forEach((k, v) { 
          totalMasterySum += (v as num).toDouble(); // FIXED: Variable is used
          scoreCount++; 
        });
        if (doc.data()['preferredMode'] != 'Visual') interventions++;
      }

      return {
        "learners": childrenSnap.docs.length,
        "parents": parentSnap.docs.length, // Added Parents count
        "mastery": scoreCount == 0 ? 0.0 : (totalMasterySum / scoreCount),
        "aiRate": childrenSnap.docs.isEmpty ? 0 : (interventions / childrenSnap.docs.length * 100).round(),
        "totalLessons": activitySnap.docs.length,
      };
    } catch (e) {
      return {"learners": 0, "parents": 0, "mastery": 0.0, "aiRate": 0, "totalLessons": 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeService = Provider.of<ThemeService>(context);

    return LayoutBuilder(builder: (context, constraints) {
      bool isMobile = constraints.maxWidth < 1100;

      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: themeService.isDarkMode ? const Color(0xFF020617) : const Color(0xFFF1F2F7),
        drawer: isMobile ? _buildSidebar(context, theme, themeService.isDarkMode) : null,
        body: Row(
          children: [
            if (!isMobile) _buildSidebar(context, theme, themeService.isDarkMode),
            Expanded(
              child: Column(
                children: [
                  _buildTopHeader(theme, themeService, isMobile),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: _buildMainView(theme, isMobile),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ActivityWizard())),
          label: const Text("New Activity"),
          icon: const Icon(Icons.add),
          backgroundColor: brandIndigo,
        ),
      );
    });
  }

  // --- 1. TOP HEADER ---
  Widget _buildTopHeader(ThemeData theme, ThemeService ts, bool isMobile) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(children: [
        if (isMobile) IconButton(icon: const Icon(Icons.menu_rounded), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
        Text(DateFormat('EEEE, MMM d').format(DateTime.now()), // FIXED: Using 'intl'
            style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
        const Spacer(),
        SizedBox(
          width: 250,
          child: TextField(decoration: InputDecoration(hintText: "Search...", prefixIcon: const Icon(Icons.search, size: 18), border: InputBorder.none, filled: true, fillColor: theme.scaffoldBackgroundColor, contentPadding: EdgeInsets.zero)),
        ),
        IconButton(icon: Icon(ts.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 20), onPressed: ts.toggleTheme),
        const Icon(Icons.notifications_none_rounded, color: Colors.grey),
        const VerticalDivider(indent: 25, endIndent: 25, width: 40),
        _buildProfileDropdown(),
      ]),
    );
  }

  // --- 2. MAIN VIEW ---
  Widget _buildMainView(ThemeData theme, bool isMobile) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("System Overview", style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold)),
      const SizedBox(height: 32),
      _buildKPISection(theme),
      const SizedBox(height: 32),
      
      // THE ENGAGEMENT CHART (EXACT MATCH TO YOUR IMAGE)
      isMobile 
          ? Column(children: [_buildEngagementChart(theme), const SizedBox(height: 24), _buildDonutChart(theme)])
          : Row(children: [
              Expanded(flex: 2, child: _buildEngagementChart(theme)),
              const SizedBox(width: 24),
              Expanded(child: _buildDonutChart(theme)),
            ]),
    ]);
  }

  // --- 3. KPI SECTION ---
  Widget _buildKPISection(ThemeData theme) => FutureBuilder<Map<String, dynamic>>(
    future: _fetchDashboardData(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const LinearProgressIndicator();
      final d = snapshot.data!;
      return Wrap(spacing: 16, runSpacing: 16, children: [
        _AdminStatCard("ACTIVE LEARNERS", d['learners'].toString(), Icons.child_care, Colors.green),
        _AdminStatCard("TOTAL PARENTS", d['parents'].toString(), Icons.people, Colors.blue), // Parents card added
        _AdminStatCard("AVG. MASTERY", "${(d['mastery'] * 100).toStringAsFixed(1)}%", Icons.auto_graph, Colors.orange),
        _AdminStatCard("AI INTERVENTION", "${d['aiRate']}%", Icons.auto_awesome, Colors.purple),
      ]);
    },
  );

  // --- 4. ENGAGEMENT CHART (MATCHING YOUR IMAGE) ---
  Widget _buildEngagementChart(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: theme.dividerColor.withOpacity(0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Engagement", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text("Last 30 days", style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("+15.2%", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18)),
                  Text("GROWTH", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 200,
            child: LineChart(LineChartData(
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    const style = TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold);
                    switch (value.toInt()) {
                      case 0: return const Text('WK 1', style: style);
                      case 2: return const Text('WK 2', style: style);
                      case 4: return const Text('WK 3', style: style);
                      case 6: return const Text('WK 4', style: style);
                    }
                    return const Text('');
                  },
                )),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: const [FlSpot(0, 1), FlSpot(1, 2.8), FlSpot(2, 2.5), FlSpot(3, 3.8), FlSpot(4, 2), FlSpot(5, 3), FlSpot(6, 4.5)],
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 4,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(colors: [Colors.blue.withOpacity(0.2), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  ),
                )
              ],
            )),
          ),
        ],
      ),
    );
  }

  // --- 5. SIDEBAR (NO UNUSED IMPORTS) ---
  Widget _buildSidebar(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      width: 260, color: const Color(0xFF0F172A),
      child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(24, 60, 24, 40), child: Row(children: [
          const Icon(Icons.auto_awesome, color: Colors.blue, size: 30),
          const SizedBox(width: 12),
          const Text("LittleGenius", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        ])),
        _sidebarTile(Icons.grid_view_rounded, "Dashboard", true, () {}),
        _sidebarTile(Icons.map_outlined, "Concepts", false, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ConceptManager()))),
        _sidebarTile(Icons.library_books_outlined, "Inventory", false, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ActivityManager()))),
        _sidebarTile(Icons.psychology_outlined, "AI Tuning", false, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AIConfigurator()))),
        const Spacer(),
        _buildSidebarFooter(),
      ]),
    );
  }

  Widget _buildDonutChart(ThemeData theme) => _cardWrapper(theme: theme, title: "Activity Modes", child: SizedBox(height: 180, child: PieChart(PieChartData(centerSpaceRadius: 40, sections: [PieChartSectionData(color: Colors.blue, value: 40, title: '40%', radius: 10), PieChartSectionData(color: Colors.orange, value: 30, title: '30%', radius: 10), PieChartSectionData(color: Colors.purple, value: 30, title: '30%', radius: 10)]))));
  Widget _sidebarTile(IconData i, String t, bool a, VoidCallback o) => ListTile(onTap: o, leading: Icon(i, color: a ? Colors.white : Colors.white38), title: Text(t, style: TextStyle(color: a ? Colors.white : Colors.white38, fontSize: 14)));
  Widget _cardWrapper({required ThemeData theme, required String title, required Widget child}) => Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: theme.dividerColor.withOpacity(0.05))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), const SizedBox(height: 20), child]));
  Widget _buildProfileDropdown() => PopupMenuButton(onSelected: (v) => AuthService().logout().then((_) => Navigator.pushReplacementNamed(context, '/login')), itemBuilder: (context) => [const PopupMenuItem(value: 'logout', child: Text("Logout", style: TextStyle(color: Colors.red)))], child: const CircleAvatar(radius: 16, backgroundColor: Colors.blueGrey, child: Icon(Icons.person, color: Colors.white, size: 16)));
  Widget _buildSidebarFooter() => Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text("DEVELOPER", style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)), Text("Nihala Jebin", style: TextStyle(color: Colors.white70, fontSize: 12)), Text("KMC24MCA-2028", style: TextStyle(color: Colors.white38, fontSize: 10))]));
}

// --- STAT CARD WITH BORDER-ONLY HIGHLIGHT ---
class _AdminStatCard extends StatefulWidget {
  final String title, value; final IconData icon; final Color color;
  const _AdminStatCard(this.title, this.value, this.icon, this.color);
  @override State<_AdminStatCard> createState() => _AdminStatCardState();
}

class _AdminStatCardState extends State<_AdminStatCard> {
  bool isHovered = false;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 220, padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          // ONLY BORDER HIGHLIGHTS ON HOVER
          border: Border.all(color: isHovered ? widget.color : theme.dividerColor.withOpacity(0.1), width: isHovered ? 2.5 : 1.0),
          boxShadow: [if (isHovered) BoxShadow(color: widget.color.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(widget.icon, color: widget.color, size: 24),
            const SizedBox(height: 16),
            Text(widget.value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            Text(widget.title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}