import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../services/theme_service.dart';
import '../../utils/app_colors.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context);

    return Scaffold(
      backgroundColor: theme.bgColor,
      appBar: AppBar(
        title: Text("GLOBAL PERFORMANCE", 
          style: TextStyle(color: theme.textColor, fontSize: 14, fontWeight: FontWeight.bold)),
        backgroundColor: theme.cardColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(25),
        children: [
          Text("Category Engagement", 
            style: TextStyle(color: theme.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildBarChart(theme),
          const SizedBox(height: 30),
          _buildSummaryTile(theme, "Total Mastery Events", "48,201", AppColors.primaryBlue),
          _buildSummaryTile(theme, "AI Redirections Triggered", "1,204", AppColors.accentOrange),
        ],
      ),
    );
  }

  Widget _buildBarChart(ThemeService theme) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor, 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.borderColor),
      ),
      child: BarChart(BarChartData(
        barGroups: [
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 10, color: Colors.blue, width: 15)]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 7, color: AppColors.accentOrange, width: 15)]),
          BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 12, color: AppColors.teal, width: 15)]),
        ],
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
      )),
    );
  }

  Widget _buildSummaryTile(ThemeService theme, String t, String v, Color c) => ListTile(
    title: Text(t, style: TextStyle(color: theme.subTextColor)),
    trailing: Text(v, style: TextStyle(color: c, fontSize: 18, fontWeight: FontWeight.bold)),
  );
}