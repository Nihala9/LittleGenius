import 'package:flutter/material.dart';
import '../../models/child_model.dart';
import '../../services/database_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/parent_scaffold.dart';

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

  // --- SMART HEURISTIC LOGIC (Replaces Gemini) ---
  // This analyzes the data locally to give "AI-like" insights
  Map<String, String> _getSmartAnalysis() {
    final scores = widget.child.masteryScores;
    if (scores.isEmpty) return {};

    String strongestId = scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    String weakestId = scores.entries.reduce((a, b) => a.value < b.value ? a : b).key;

    String strongestName = _conceptNames[strongestId] ?? "Lessons";
    String weakestName = _conceptNames[weakestId] ?? "New Topics";

    String lang = widget.child.language;

    if (lang == "Malayalam") {
      return {
        "strength": "${widget.child.name} ഇപ്പോൾ $strongestName-ൽ വളരെ മിടുക്കനാണ്!",
        "struggle": "$weakestName മനസ്സിലാക്കാൻ അല്പം കൂടി പരിശീലനം ആവശ്യമാണ്.",
        "tip": "അമ്മയോ അച്ഛനോ കൂടെയിരുന്ന് $weakestName വരയ്ക്കാൻ സഹായിക്കുന്നത് നന്നായിരിക്കും."
      };
    } else if (lang == "Arabic") {
      return {
        "strength": "${widget.child.name} ممتاز جداً في $strongestName!",
        "struggle": "يحتاج إلى مزيد من التدريب في $weakestName.",
        "tip": "جرب ممارسة $weakestName معه في المنزل باستخدام الورقة والقلم."
      };
    } else if (lang == "Hindi") {
      return {
        "strength": "${widget.child.name} $strongestName में बहुत अच्छा कर रहा है!",
        "struggle": "$weakestName में थोड़े और अभ्यास की आवश्यकता है।",
        "tip": "खेल-खेल में $weakestName का अभ्यास कराना उनके लिए मददगार होगा।"
      };
    } else {
      return {
        "strength": "${widget.child.name} is showing mastery in $strongestName!",
        "struggle": "Currently finding $weakestName a bit challenging.",
        "tip": "Try an offline tracing activity for $weakestName to build confidence."
      };
    }
  }

  String _getMasteryLevel(double score) {
    if (score >= 0.8) return "Mastery Level";
    if (score >= 0.5) return "Improving Fast";
    return "Needs Practice";
  }

  String _getQuickInsight(String conceptId, double score) {
    String name = _conceptNames[conceptId] ?? "this lesson";
    if (score >= 0.8) {
      return "Excellent! Recognition of $name is now instinctive.";
    } else if (score >= 0.4) {
      return "Good progress. The tutor is focusing on ${widget.child.preferredMode} to help.";
    } else {
      return "Focusing on fundamentals. Slowing down the pace to ensure $name is understood.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final scores = widget.child.masteryScores;
    final hasData = scores.isNotEmpty;

    return ParentScaffold(
      title: "Learning Reports",
      activeRoute: "reports",
      child: widget.child,
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
                      
                      _sectionHeader("Smart Analysis", Icons.psychology_rounded),
                      _buildSmartAnalysisCard(),
                      
                      const SizedBox(height: 30),
                      _sectionHeader("Subject Breakdown", Icons.analytics_outlined),
                      const SizedBox(height: 15),
                      
                      ...scores.entries.map((entry) => _buildReportTile(entry.key, entry.value)),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.ultraViolet, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.childNavy)),
      ],
    );
  }

  Widget _buildOverallProgressCard() {
    double totalMastery = widget.child.masteryScores.values.reduce((a, b) => a + b) / 
                          widget.child.masteryScores.length;

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: AppColors.ultraViolet,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: AppColors.ultraViolet.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
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
                const Text("Global Progress", style: TextStyle(color: Colors.white70, fontSize: 13)),
                Text("${(totalMastery * 100).toInt()}% Mastery", 
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
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

  Widget _buildSmartAnalysisCard() {
    final analysis = _getSmartAnalysis();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.ultraViolet.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _analysisItem(Icons.star_rounded, Colors.amber, analysis['strength'] ?? "Analyzing progress..."),
          const Divider(height: 30),
          _analysisItem(Icons.info_outline_rounded, Colors.blue, analysis['struggle'] ?? "Keep playing to see trends."),
          const Divider(height: 30),
          _analysisItem(Icons.lightbulb_outline, Colors.orange, "Teacher's Tip: ${analysis['tip'] ?? "Consistency is key to learning!"}"),
        ],
      ),
    );
  }

  Widget _analysisItem(IconData icon, Color color, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 15),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.childNavy, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _buildReportTile(String conceptId, double score) {
    String name = _conceptNames[conceptId] ?? "Lesson Item";
    Color progressColor = score >= 0.8 ? AppColors.childGreen : (score >= 0.4 ? AppColors.childBlue : Colors.redAccent);

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome, size: 16, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getQuickInsight(conceptId, score),
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
          const Text("No learning data yet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
            child: Text("Start some activities in the child profile to see progress reports here!",
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}