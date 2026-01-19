import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';
import '../../models/child_profile.dart';
import '../../services/auth_service.dart';
import 'add_child.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  final DatabaseService _db = DatabaseService();
  final String _parentId = FirebaseAuth.instance.currentUser!.uid;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // FIXED: Unified variable name
  String? selectedChildId;
  bool _isBedtimeLockOn = true;

  // --- BRAND PALETTE ---
  final Color _slate900 = const Color(0xFF0F172A);
  final Color _slate500 = const Color(0xFF64748B);
  final Color _geniusIndigo = const Color(0xFF4F46E5);
  final Color _mintDark = const Color(0xFF0D9488);
  final Color _warmOrange = const Color(0xFFEA580C);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChildProfile>>(
      stream: _db.getChildren(_parentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final children = snapshot.data ?? [];
        if (children.isEmpty) return _buildNoChildState();

        // Ensure selection logic is robust
        if (selectedChildId == null || !children.any((c) => c.id == selectedChildId)) {
          selectedChildId = children[0].id;
        }

        final currentChild = children.firstWhere((c) => c.id == selectedChildId);

        return LayoutBuilder(builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 1100;

          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: const Color(0xFFF8FAFC),
            drawer: isMobile ? _buildSidebar(currentChild) : null,
            body: Row(
              children: [
                if (!isMobile) _buildSidebar(currentChild),
                Expanded(
                  child: Column(
                    children: [
                      _buildTopNav(children, isMobile),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(32), 
                          child: _buildMainContent(currentChild, isMobile)
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  // --- 1. SIDEBAR NAVIGATION ---
  Widget _buildSidebar(ChildProfile child) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(children: [
        const SizedBox(height: 50),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.auto_awesome, color: _mintDark, size: 28),
          const SizedBox(width: 10),
          Text("GeniusAI", style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 20, color: _slate900)),
        ]),
        const SizedBox(height: 40),
        _navItem(Icons.grid_view_rounded, "Dashboard", true, () {}),
        _navItem(Icons.insights_rounded, "AI Insights", false, () {}),
        _navItem(Icons.bedtime_rounded, "Wellness", false, () {}),
        const Spacer(),
        // PROFILE MINI-CARD WITH POPUP MENU (CRUD)
        _buildProfileMenu(child),
      ]),
    );
  }

  Widget _buildProfileMenu(ChildProfile child) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        CircleAvatar(radius: 16, backgroundColor: Colors.white, child: Text(child.avatar, style: const TextStyle(fontSize: 18))),
        const SizedBox(width: 10),
        Expanded(child: Text(child.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _slate900))),
        PopupMenuButton<int>(
          icon: Icon(Icons.unfold_more_rounded, size: 16, color: _slate500),
          onSelected: (val) {
            if (val == 0) Navigator.push(context, MaterialPageRoute(builder: (c) => AddChildWizard(existingChild: child)));
            if (val == 1) _confirmDelete(child);
            if (val == 2) AuthService().logout().then((_) => Navigator.pushReplacementNamed(context, '/login'));
          },
          itemBuilder: (c) => [
            const PopupMenuItem(value: 0, child: Text("Edit Profile")),
            const PopupMenuItem(value: 1, child: Text("Delete Profile", style: TextStyle(color: Colors.red))),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 2, child: Text("Log Out")),
          ],
        )
      ]),
    );
  }

  // --- 2. TOP NAV ---
  Widget _buildTopNav(List<ChildProfile> children, bool isMobile) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(children: [
        if (isMobile) IconButton(icon: const Icon(Icons.menu_open_rounded), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
        Text("Parental Insights", style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 18, color: _slate900)),
        const Spacer(),
        _buildSwitcherButton(context, children),
      ]),
    );
  }

  // --- 3. MAIN CONTENT (COGNITIVE PROFILE & HEATMAP) ---
  Widget _buildMainContent(ChildProfile child, bool isMobile) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        CircleAvatar(radius: 35, backgroundColor: Colors.white, child: Text(child.avatar, style: const TextStyle(fontSize: 40))),
        const SizedBox(width: 20),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("${child.name}'s Progress", style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: _slate900)),
          Text("Today: ${child.usageToday}m used • Target: ${child.dailyLimit}m", style: TextStyle(color: _mintDark, fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
      ]),
      const SizedBox(height: 32),
      if (isMobile) ...[
        _buildCognitiveProfile(child),
        const SizedBox(height: 24),
        _buildWellness(child),
      ] else
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 3, child: _buildCognitiveProfile(child)),
          const SizedBox(width: 24),
          Expanded(flex: 2, child: _buildWellness(child)),
        ]),
      const SizedBox(height: 24),
      _card(title: "Mastery Heatmap", subtitle: "Alphabet Knowledge Tracing (BKT Algorithm)", child: _buildHeatmap(child)),
    ]);
  }

  Widget _buildCognitiveProfile(ChildProfile child) {
    return _card(title: "Cognitive Profile", subtitle: "MAB Learning Style Analysis", child: Row(children: [
      SizedBox(height: 150, width: 150, child: Stack(alignment: Alignment.center, children: [
        PieChart(PieChartData(sectionsSpace: 0, centerSpaceRadius: 55, sections: [
          PieChartSectionData(color: _mintDark, value: 88, radius: 12, showTitle: false),
          PieChartSectionData(color: const Color(0xFFF1F5F9), value: 12, radius: 12, showTitle: false),
        ])),
        Text("88%", style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: _slate900)),
      ])),
      const SizedBox(width: 30),
      Expanded(child: Column(children: [
        _skillBar("Verbal Logic", 0.92, Colors.blue),
        const SizedBox(height: 15),
        _skillBar("Spatial Focus", 0.76, _warmOrange),
      ]))
    ]));
  }

  Widget _buildHeatmap(ChildProfile child) {
    return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 13, mainAxisSpacing: 10, crossAxisSpacing: 10), itemCount: 26, itemBuilder: (context, i) {
      String l = String.fromCharCode(65 + i); 
      double score = child.masteryScores['Letter_$l'] ?? 0.0;
      Color cellColor = score >= 0.9 ? _warmOrange : const Color(0xFFF1F5F9);
      return Container(decoration: BoxDecoration(color: cellColor, borderRadius: BorderRadius.circular(10)), child: Center(child: Text(l, style: TextStyle(color: score >= 0.9 ? Colors.white : _slate500, fontWeight: FontWeight.bold, fontSize: 12))));
    });
  }

  Widget _buildWellness(ChildProfile child) {
    return _card(title: "Digital Wellness", child: Column(children: [
      Stack(alignment: Alignment.center, children: [
        SizedBox(height: 120, width: 120, child: CircularProgressIndicator(value: child.usageToday / child.dailyLimit, strokeWidth: 10, color: _geniusIndigo, backgroundColor: const Color(0xFFF1F5F9))),
        Text("${child.usageToday}m", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
      ]),
      const SizedBox(height: 15),
      SwitchListTile(
        dense: true, 
        title: const Text("Bedtime Lock", style: TextStyle(fontWeight: FontWeight.bold)), 
        value: _isBedtimeLockOn, 
        activeColor: _mintDark, 
        onChanged: (v) => setState(() => _isBedtimeLockOn = v),
      ),
    ]));
  }

  // --- UI HELPERS ---
  Widget _card({required String title, String? subtitle, required Widget child}) => Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFE2E8F0))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), if (subtitle != null) Text(subtitle, style: TextStyle(color: _slate500, fontSize: 11)), const SizedBox(height: 20), child]));
  
  Widget _skillBar(String l, double v, Color c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey)), const SizedBox(height: 6), LinearProgressIndicator(value: v, color: c, minHeight: 6, backgroundColor: const Color(0xFFF1F5F9))]);
  
  Widget _navItem(IconData i, String t, bool a, VoidCallback? o) => ListTile(onTap: o, leading: Icon(i, color: a ? _geniusIndigo : _slate500), title: Text(t, style: TextStyle(color: a ? _geniusIndigo : _slate500, fontSize: 14, fontWeight: a ? FontWeight.bold : FontWeight.normal)));
  
  Widget _buildSwitcherButton(BuildContext context, List<ChildProfile> children) => ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0, side: const BorderSide(color: Color(0xFFE2E8F0)), shape: const StadiumBorder()), onPressed: () => _showSwitcherDialog(context, children), icon: const Icon(Icons.swap_horiz, size: 16), label: const Text("Switch Profile"));

  void _showSwitcherDialog(BuildContext context, List<ChildProfile> children) {
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (context) => ListView(shrinkWrap: true, padding: const EdgeInsets.all(24), children: [
      const Text("Select Explorer", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ...children.map((c) => ListTile(leading: CircleAvatar(child: Text(c.avatar)), title: Text(c.name), onTap: () { setState(() => selectedChildId = c.id); Navigator.pop(context); })),
      ListTile(leading: const Icon(Icons.add_circle, color: Colors.blue), title: const Text("Add New Explorer"), onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/add-child'); }),
    ]));
  }

  Widget _buildNoChildState() => Scaffold(body: Center(child: ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/add-child'), child: const Text("Create First Profile"))));
  
  void _confirmDelete(ChildProfile child) { showDialog(context: context, builder: (c) => AlertDialog(title: const Text("Delete Profile?"), content: Text("Remove all data for ${child.name}?"), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")), TextButton(onPressed: () { _db.deleteChildProfile(child.id).then((_) { Navigator.pop(c); setState(() => selectedChildId = null); }); }, child: const Text("Delete", style: TextStyle(color: Colors.red)))])); }
}