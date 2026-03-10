import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';
import '../../models/child_model.dart';
import '../../models/concept_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/parent_scaffold.dart';
import 'profile_wizard_screen.dart';

class ParentDashboard extends StatefulWidget {
  final ChildProfile? specificChild;
  const ParentDashboard({super.key, this.specificChild});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  final db = DatabaseService();

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
                
                final analysis = _analyzePerformance(activeChild, concepts);

                return ParentScaffold(
                  title: "Overview",
                  activeRoute: "overview",
                  child: activeChild,
                  body: ListView(
                    padding: const EdgeInsets.all(25),
                    children: [
                      _buildIdentityCard(context, activeChild),
                      const SizedBox(height: 25),
                      
                      _sectionTitle("TODAY'S APP TIME"),
                      _buildUsageMonitor(activeChild),
                      
                      const SizedBox(height: 25),

                      _sectionTitle("PLAY TOGETHER AT HOME"),
                      _buildDynamicAdvice(analysis['weakestCategory']),

                      const SizedBox(height: 25),

                      _sectionTitle("SMART LEARNING REPORT"),
                      _buildDynamicObservation(activeChild, analysis),

                      const SizedBox(height: 25),

                      _sectionTitle("SUBJECT PROGRESS"),
                      _buildDynamicCategoryBreakdown(activeChild, categories, concepts),
                      const SizedBox(height: 50),
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

  Map<String, dynamic> _analyzePerformance(ChildProfile child, List<Concept> concepts) {
    if (child.masteryScores.isEmpty) {
      return {'weakestCategory': 'General', 'averageMastery': 0.0};
    }

    String weakest = "General";
    double lowestAvg = 1.1;
    double totalSum = 0;

    child.masteryScores.forEach((id, score) {
      totalSum += score;
      if (score < lowestAvg) {
        lowestAvg = score;
        weakest = concepts.firstWhere(
          (c) => c.id == id, 
          orElse: () => Concept(id: '', name: '', category: 'General', order: 0)
        ).category;
      }
    });

    return {
      'weakestCategory': weakest,
      'averageMastery': totalSum / child.masteryScores.length,
    };
  }

  Widget _buildDynamicObservation(ChildProfile child, Map<String, dynamic> analysis) {
    double avg = analysis['averageMastery'] ?? 0.0;
    String weakest = analysis['weakestCategory'] ?? "new lessons";
    String msg;

    if (avg >= 0.8) {
      msg = "${child.name} is a superstar! They are mastering new concepts very quickly.";
    } else if (avg >= 0.5) {
      msg = "${child.name} is doing a wonderful job! They are ready for more challenges.";
    } else if (avg >= 0.2) {
      msg = "${child.name} is making great progress. We are using more games to help with $weakest.";
    } else {
      msg = "${child.name} is making steady progress. We are focusing on $weakest to build confidence.";
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF5FF),
        borderRadius: BorderRadius.circular(25),
        // FIXED: withOpacity -> withValues
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.face_retouching_natural, color: Colors.blue, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Text(msg, 
              style: const TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500, color: Colors.blueGrey)
            )
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicAdvice(String category) {
    Map<String, String> adviceMap = {
      'Alphabets': 'Try drawing letters with your child in a tray of sand or flour.',
      'Numbers': 'Ask your child to help you count 5 spoons or fruits at home.',
      'Animals': 'Ask your child to make the sound of their favorite animal.',
      'Shapes': 'Look for circular or square objects together in the room.',
      'General': 'Read a picture book together before bedtime.',
    };

    String task = adviceMap[category] ?? adviceMap['General']!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.ultraViolet, Colors.deepPurple.shade400],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        // FIXED: withOpacity -> withValues
        boxShadow: [BoxShadow(color: AppColors.ultraViolet.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb, color: Colors.amber, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Focus Area: $category", style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                const Text("Today's Home Activity", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 5),
                Text(task, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicCategoryBreakdown(ChildProfile child, List<Map<String, dynamic>> categories, List<Concept> allConcepts) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(25),
        // FIXED: withOpacity -> withValues
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)]
      ),
      child: Column(
        children: [
          if (categories.isEmpty) const Text("No subjects added in Admin yet."),
          ...categories.map((cat) {
            String catName = cat['name'];
            List<String> conceptIds = allConcepts.where((c) => c.category == catName).map((c) => c.id).toList();
            double total = 0; int count = 0;
            for (var id in conceptIds) { 
              if (child.masteryScores.containsKey(id)) { 
                total += child.masteryScores[id]!; 
                count++; 
              } 
            }
            double avg = count == 0 ? 0 : total / count;

            return Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: _statRow(catName, avg),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildUsageMonitor(ChildProfile child) {
    double progress = (child.minutesSpentToday / child.dailyLimit).clamp(0, 1).toDouble();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Minutes Used", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("${child.minutesSpentToday} / ${child.dailyLimit} mins", style: const TextStyle(color: AppColors.ultraViolet, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress, 
              minHeight: 10, 
              backgroundColor: const Color(0xFFFEFACD), 
              valueColor: const AlwaysStoppedAnimation(AppColors.childBlue)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityCard(BuildContext context, ChildProfile child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.ultraViolet, 
        borderRadius: BorderRadius.circular(30),
        // FIXED: withOpacity -> withValues
        boxShadow: [BoxShadow(color: AppColors.ultraViolet.withValues(alpha: 0.2), blurRadius: 10)]
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 35, backgroundImage: AssetImage(child.avatarUrl)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(child.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                Text("Class Level: ${child.childClass}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.lemonChiffon), 
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ProfileWizardScreen(existingChild: child)))
          ),
        ],
      ),
    );
  }

  Widget _statRow(String title, double val) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3A455E), fontSize: 13)),
            Text("${(val * 100).toInt()}% Done", style: const TextStyle(color: Color(0xFF5F4A8B), fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: val, 
            minHeight: 8, 
            backgroundColor: const Color(0xFFFEFACD), 
            valueColor: const AlwaysStoppedAnimation(Color(0xFF4FAAFD))
          ),
        )
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5), 
      child: Text(title, style: const TextStyle(color: Color(0xFF5F4A8B), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2))
    );
  }

  Widget _buildNoChildView(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBEE),
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.pushNamed(context, '/add_child'), 
          child: const Text("Create a Child Profile")
        )
      ),
    );
  }
}