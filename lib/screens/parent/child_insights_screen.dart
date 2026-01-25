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

  void _loadData() async {
    _conceptNames = await _db.getConceptNames();
    if (mounted) setState(() => _isLoading = false);
  }

  // --- AI FEEDBACK LOGIC ---
  // Transforms raw scores into human-readable advice for parents
  String _getAIAdvice(double score) {
    if (score >= 0.8) return "Mastered! Your child is ready for advanced challenges.";
    if (score >= 0.4) return "Great progress. The AI is focusing on reinforcing this concept.";
    return "Exploring. The AI is trying different activity modes to find the best fit.";
  }

  String _getMasteryLabel(double score) {
    if (score >= 0.8) return "GENIUS";
    if (score >= 0.4) return "SCHOLAR";
    return "EXPLORER";
  }

  @override
  Widget build(BuildContext context) {
    final hasData = widget.child.masteryScores.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text("${widget.child.name}'s Insights"),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !hasData
              ? _buildNoDataView()
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildOverviewCard(),
                    const SizedBox(height: 30),
                    const Text("Concept Breakdown", 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    
                    // Generate a card for every concept the child has practiced
                    ...widget.child.masteryScores.entries.map((entry) {
                      return _buildConceptInsightCard(entry.key, entry.value);
                    }),

                    const SizedBox(height: 20),
                    _buildAISummaryCard(),
                  ],
                ),
    );
  }

  // 1. TOP OVERALL SCORE CARD
  Widget _buildOverviewCard() {
    double totalMastery = widget.child.masteryScores.values.reduce((a, b) => a + b) / 
                          widget.child.masteryScores.length;

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: AppColors.primaryBlue.withOpacity(0.3), blurRadius: 15)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            backgroundImage: NetworkImage(widget.child.avatarUrl),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Overall Mastery", style: TextStyle(color: Colors.white70, fontSize: 14)),
              Text("${(totalMastery * 100).toInt()}%", 
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              Text("Status: ${_getMasteryLabel(totalMastery)}", 
                style: const TextStyle(color: AppColors.accentOrange, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  // 2. DETAILED CONCEPT CARDS
  Widget _buildConceptInsightCard(String id, double score) {
    String name = _conceptNames[id] ?? "Learning Lesson";
    
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("${(score * 100).toInt()}%", 
                style: TextStyle(color: score < 0.3 ? Colors.red : AppColors.primaryBlue, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: score,
              minHeight: 10,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation(score < 0.3 ? Colors.redAccent : AppColors.primaryBlue),
            ),
          ),
          const SizedBox(height: 15),
          // AI Interpretation
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 16, color: AppColors.accentOrange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_getAIAdvice(score), 
                  style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontStyle: FontStyle.italic)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. AI STYLE SUMMARY
  Widget _buildAISummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.accentOrange.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(20),
        color: AppColors.accentOrange.withOpacity(0.05),
      ),
      child: Column(
        children: [
          const Text("Smarty Cat's Observations", 
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentOrange)),
          const SizedBox(height: 10),
          Text(
            "The AI has noticed ${widget.child.name} responds best to '${widget.child.preferredMode}' activities. We are prioritizing this mode to keep learning fun and effective!",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, height: 1.4),
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
          const Icon(Icons.psychology_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text("The AI is still learning!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
            child: Text("Once your child completes their first adventure, detailed performance insights will appear here.",
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}