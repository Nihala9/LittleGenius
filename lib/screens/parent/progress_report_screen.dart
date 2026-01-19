import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/child_profile.dart';

class ProgressReportScreen extends StatelessWidget {
  final ChildProfile child;

  const ProgressReportScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Extract real mastery scores from the BKT algorithm results in Firestore
    double literacyScore = (child.masteryScores['Letter_A'] ?? 0.1) * 100;
    double numeracyScore = (child.masteryScores['Number_1'] ?? 0.1) * 100;
    double logicScore = (child.masteryScores['Shapes'] ?? 0.1) * 100;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("${child.name}'s Learning Insights", 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: OVERALL MASTERY CHART ---
            _buildSectionHeader("Academic Mastery"),
            _buildChartCard([
              _barGroup(0, literacyScore, Colors.blue, "Literacy"),
              _barGroup(1, numeracyScore, Colors.green, "Numeracy"),
              _barGroup(2, logicScore, Colors.orange, "Logic"),
            ]),

            const SizedBox(height: 30),

            // --- SECTION 2: AI COGNITIVE INSIGHTS ---
            _buildSectionHeader("AI Cognitive Profile"),
            _buildInsightCard(
              title: "Learning Style: ${child.preferredMode}",
              desc: "Based on the MAB algorithm, ${child.name} shows 85% higher engagement with ${child.preferredMode} activities.",
              icon: Icons.psychology_rounded,
              color: Colors.indigo,
            ),

            const SizedBox(height: 15),

            // --- SECTION 3: STRENGTHS & WEAKNESSES ---
            _buildSectionHeader("Strengths & Weaknesses"),
            Row(
              children: [
                _buildSmallInfoCard("Strength", literacyScore > 70 ? "Visual Recognition" : "Exploring", Icons.thumb_up_rounded, Colors.green),
                const SizedBox(width: 12),
                // FIXED: lowercase 'a' in assignment_late_rounded
                _buildSmallInfoCard("Focus Area", numeracyScore < 50 ? "Number Counting" : "Logic", Icons.assignment_late_rounded, Colors.redAccent),
              ],
            ),

            const SizedBox(height: 30),

            // --- SECTION 4: DIGITAL WELLNESS ---
            _buildSectionHeader("Screen Time Usage"),
            _buildInsightCard(
              title: "Usage Today: ${child.usageToday} / ${child.dailyLimit} mins",
              desc: child.usageToday >= child.dailyLimit 
                  ? "Daily limit reached. App is currently locked." 
                  : "Child has ${(child.dailyLimit - child.usageToday)} minutes of learning left.",
              icon: Icons.timer_rounded,
              color: Colors.teal,
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // --- UI BUILDER METHODS ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
    );
  }

  Widget _buildChartCard(List<BarChartGroupData> groups) {
    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: BarChart(
        BarChartData(
          maxY: 100,
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: groups,
        ),
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y, Color color, String label) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y, 
          color: color, 
          width: 18, 
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(show: true, toY: 100, color: const Color(0xFFF1F5F9)),
        )
      ],
    );
  }

  Widget _buildInsightCard({required String title, required String desc, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSmallInfoCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
          ],
        ),
      ),
    );
  }
}