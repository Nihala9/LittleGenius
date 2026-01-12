import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/child_profile.dart';

class ProgressReportScreen extends StatelessWidget {
  final ChildProfile child;

  const ProgressReportScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Extract mastery scores (e.g., {'Letter_A': 0.85})
    double literacyScore = (child.masteryScores['Letter_A'] ?? 0.1) * 100;
    double numeracyScore = (child.masteryScores['Number_1'] ?? 0.1) * 100;

    return Scaffold(
      appBar: AppBar(title: Text("${child.name}'s Progress")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("AI Learning Mastery", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // MASTERY CHART
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(show: true),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: literacyScore, color: Colors.blue)]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: numeracyScore, color: Colors.green)]),
                  ],
                ),
              ),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [Text("Literacy"), Text("Numeracy")],
            ),

            const SizedBox(height: 40),

            // AI COGNITIVE INSIGHTS (MAB Algorithm Result)
            const Text("AI Cognitive Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.psychology, size: 40, color: Colors.orange),
                      title: Text("Preferred Learning Style: ${child.preferredMode}"),
                      subtitle: Text("LittleGenius AI has identified that ${child.name} responds best to ${child.preferredMode} activities."),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text("Learning History", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            // A simple placeholder for activity logs
            const ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text("Completed: Letter A Adventure"),
              subtitle: Text("Mastery reached 92%"),
            ),
          ],
        ),
      ),
    );
  }
}