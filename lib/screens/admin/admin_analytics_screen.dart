import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../services/theme_service.dart';
import '../../services/database_service.dart';
import '../../utils/app_colors.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  late Future<Map<String, dynamic>> _analyticsFuture;

  @override
  void initState() {
    super.initState();
    _analyticsFuture = DatabaseService().getPlatformAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context);

    return Scaffold(
      backgroundColor: theme.bgColor,
      appBar: AppBar(
        title: Text("PLATFORM ANALYTICS", 
          style: TextStyle(color: theme.textColor, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: theme.cardColor,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _analyticsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text("No analytics data available",
                style: TextStyle(color: theme.subTextColor)),
            );
          }

          final analytics = snapshot.data!;
          
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _analyticsFuture = DatabaseService().getPlatformAnalytics();
              });
              await _analyticsFuture;
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ====== SYSTEM USAGE SECTION ======
                Text("System Usage",
                  style: TextStyle(color: theme.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                
                // KPI Cards - Top Row
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard(theme, "Total Children", 
                        analytics['totalChildren'].toString(), Icons.people, AppColors.oceanBlue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKpiCard(theme, "Active Today",
                        analytics['activeToday'].toString(), Icons.online_prediction, Colors.green),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Engagement Rate
                _buildKpiCard(theme, "Engagement Rate",
                  "${(analytics['engagementRate'] as double).toStringAsFixed(1)}%", 
                  Icons.trending_up, Colors.orange, fullWidth: true),
                
                const SizedBox(height: 12),
                
                // Average Usage
                _buildKpiCard(theme, "Avg. Daily Usage",
                  "${analytics['avgUsagePerChild']} min/child", 
                  Icons.timer, AppColors.teal, fullWidth: true),

                const SizedBox(height: 30),
                
                // ====== LEARNING ANALYTICS SECTION ======
                Text("Learning Analytics",
                  style: TextStyle(color: theme.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                
                // Mastery & Awards
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard(theme, "Total Masteries",
                        analytics['totalMasteries'].toString(), Icons.verified, Colors.purple),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKpiCard(theme, "Stars Awarded",
                        analytics['totalStars'].toString(), Icons.star, Colors.amber),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Average Performance
                _buildKpiCard(theme, "Avg. Mastery Score",
                  "${analytics['avgScore']}%", 
                  Icons.assessment, Colors.indigo, fullWidth: true),
                const SizedBox(height: 12),
                
                _buildKpiCard(theme, "Avg. Masteries per Child",
                  analytics['avgMasteryPerChild'].toString(), 
                  Icons.campaign, AppColors.teal, fullWidth: true),

                const SizedBox(height: 30),
                
                // ====== PERFORMANCE CHARTS ======
                Text("Performance Distribution",
                  style: TextStyle(color: theme.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                
                _buildPerformanceChart(theme),
                
                const SizedBox(height: 30),
                
                // ====== TOP PERFORMERS ======
                Text("Top Performers",
                  style: TextStyle(color: theme.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                
                _buildPerformersList(theme, analytics['topPerformers'] ?? [], true),
                
                const SizedBox(height: 30),
                
                // ====== STRUGGLING LEARNERS ======
                Text("Struggling Learners",
                  style: TextStyle(color: theme.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                
                _buildPerformersList(theme, analytics['struggling'] ?? [], false),
                
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKpiCard(ThemeService theme, String title, String value, IconData icon, Color color, {bool fullWidth = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: theme.borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            radius: 28,
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: TextStyle(color: theme.subTextColor, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 5),
                Text(value,
                  style: TextStyle(color: theme.textColor, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart(ThemeService theme) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: theme.borderColor),
      ),
      child: BarChart(
        BarChartData(
          gridData: FlGridData(
            show: true,
            horizontalInterval: 20,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.borderColor,
              strokeWidth: 0.5,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const labels = ['All', 'Mastered', 'Learning'];
                  return Text(labels[value.toInt()], style: TextStyle(color: theme.subTextColor, fontSize: 11));
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: TextStyle(color: theme.subTextColor, fontSize: 10)),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 100, color: AppColors.oceanBlue, width: 20)]),
            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 75, color: Colors.green, width: 20)]),
            BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 45, color: Colors.orange, width: 20)]),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformersList(ThemeService theme, List<dynamic> performers, bool isTopPerformers) {
    if (performers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: theme.borderColor),
        ),
        child: Center(
          child: Text(
            "No data available",
            style: TextStyle(color: theme.subTextColor),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: performers.length,
      itemBuilder: (context, index) {
        final performer = performers[index] as Map<String, dynamic>;
        return _buildPerformerCard(
          theme,
          index + 1,
          performer['name'] ?? 'Unknown',
          performer['age'] ?? 0,
          (performer['averageScore'] ?? 0) as double,
          performer['masteries'] ?? 0,
          performer['stars'] ?? 0,
          isTopPerformers,
        );
      },
    );
  }

  Widget _buildPerformerCard(ThemeService theme, int rank, String name, int age, double avgScore, int masteries, int stars, bool isTop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor),
      ),
      child: Row(
        children: [
          // Rank Badge
          CircleAvatar(
            radius: 18,
            backgroundColor: isTop ? Colors.amber.withOpacity(0.2) : Colors.red.withOpacity(0.2),
            child: Text(
              "#$rank",
              style: TextStyle(
                color: isTop ? Colors.amber : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Child Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                  style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis),
                Text("Age $age • Score: ${(avgScore * 100).toStringAsFixed(0)}%",
                  style: TextStyle(color: theme.subTextColor, fontSize: 11)),
              ],
            ),
          ),
          
          // Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("$masteries Mastered",
                style: TextStyle(color: isTop ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
              Text("⭐ $stars",
                style: TextStyle(color: Colors.amber, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}