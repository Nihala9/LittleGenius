import 'package:flutter/material.dart';
import '../../models/child_model.dart';
import '../../services/database_service.dart';
import '../../utils/app_colors.dart';

class ChildInsightsScreen extends StatefulWidget {
  final ChildProfile child;
  const ChildInsightsScreen({super.key, required this.child});

  @override
  State<ChildInsightsScreen> createState() => _ChildInsightsScreenState();
}

class _ChildInsightsScreenState extends State<ChildInsightsScreen> {
  final _db = DatabaseService();
  Map<String, String> _conceptNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Load human-readable names for the concept IDs (e.g., "id123" -> "Letter A")
  void _loadData() async {
    _conceptNames = await _db.getConceptNames();
    if (mounted) setState(() => _isLoading = false);
  }

  // AI Logic: Categorize the child's current level
  String _getMasteryLevel(double score) {
    if (score >= 0.8) return "Mastery Level";
    if (score >= 0.5) return "Improving Fast";
    return "Needs Practice";
  }

  // AI Insight Generator: Explains strengths and weaknesses
  String _getAIInsight(String conceptId, double score) {
    String name = _conceptNames[conceptId] ?? "this lesson";
    if (score >= 0.8) {
      return "Excellent! ${widget.child.name} has strong recognition of $name. We are now focusing on speed and precision.";
    } else if (score >= 0.4) {
      return "Good progress with $name. The AI has noted occasional hesitation and is using more ${widget.child.preferredMode} activities to reinforce the shape.";
    } else {
      return "Struggling with $name. The AI engine has detected a pattern of errors and is slowing down the pace to build a stronger foundation.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final scores = widget.child.masteryScores;
    final hasData = scores.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text("${widget.child.name}'s Report"),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.childNavy,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !hasData
              ? _buildNoDataView()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverallProgressCard(),
                      const SizedBox(height: 25),
                      
                      const Text("Tutor Observations", 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.childNavy)),
                      const SizedBox(height: 12),
                      _buildTutorObservationCard(),
                      
                      const SizedBox(height: 30),
                      const Text("Activity Performance", 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.childNavy)),
                      const SizedBox(height: 15),
                      
                      // Map the mastery scores from the Child Model to UI Tiles
                      ...scores.entries.map((entry) => _buildReportTile(entry.key, entry.value)),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  // --- UI: TOP PROGRESS SUMMARY ---
  Widget _buildOverallProgressCard() {
    double totalMastery = widget.child.masteryScores.values.reduce((a, b) => a + b) / 
                          widget.child.masteryScores.length;

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: AppColors.ultraViolet,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: AppColors.ultraViolet.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white24,
            backgroundImage: AssetImage(widget.child.avatarUrl),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Overall Achievement", style: TextStyle(color: Colors.white70, fontSize: 13)),
                Text("${(totalMastery * 100).toInt()}% Total Mastery", 
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(_getMasteryLevel(totalMastery).toUpperCase(), 
                    style: const TextStyle(color: AppColors.childGreen, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- UI: AI GENERATED INSIGHTS ---
  Widget _buildTutorObservationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology_rounded, size: 35, color: Colors.orange),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Learning Style Insight", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                const SizedBox(height: 4),
                Text(
                  "The AI has observed that ${widget.child.name} is a strong '${widget.child.preferredMode}' learner. We are optimizing future tasks to match this style.",
                  style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- UI: ACTIVITY WISE PERFORMANCE REPORT ---
  Widget _buildReportTile(String conceptId, double score) {
    String name = _conceptNames[conceptId] ?? "Lesson Item";
    Color progressColor = score >= 0.8 ? AppColors.childGreen : (score >= 0.4 ? AppColors.childBlue : Colors.redAccent);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.childNavy)),
              Text("${(score * 100).toInt()}%", style: TextStyle(color: progressColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: score,
              minHeight: 10,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),
          const SizedBox(height: 15),
          // AI Interpretation of the data
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome, size: 14, color: AppColors.childPink),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getAIInsight(conceptId, score),
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600, fontStyle: FontStyle.italic, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.analytics_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text("Waiting for data...", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
            child: Text("Once your child completes an activity, the AI will generate a detailed performance report here.",
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}