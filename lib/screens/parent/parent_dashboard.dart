import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';
import '../../models/child_model.dart';
import '../../models/concept_model.dart';
import '../../utils/app_colors.dart';
import 'profile_wizard_screen.dart';
import '../../widgets/parent_scaffold.dart'; // The sidebar scaffold

class ParentDashboard extends StatefulWidget {
  final ChildProfile? specificChild;
  const ParentDashboard({super.key, this.specificChild});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final db = DatabaseService();

    if (user == null) return const Scaffold(body: Center(child: Text("Please Login")));

    return StreamBuilder<List<ChildProfile>>(
      stream: db.streamChildProfiles(user.uid),
      builder: (context, snapshot) {
        // 1. Show loading while waiting for Firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final profiles = snapshot.data ?? [];
        
        // 2. Identify which child's data to show
        final activeChild = profiles.firstWhere(
          (p) => p.id == (widget.specificChild?.id ?? ""),
          orElse: () => profiles.isNotEmpty ? profiles.first : ChildProfile(
            id: '', name: 'No Profile', age: 0, childClass: '', language: '', avatarUrl: 'assets/icons/profiles/p1.png'
          ),
        );

        // 3. Handle case where no profile exists at all
        if (activeChild.id.isEmpty) return _buildNoChildView(context);

        // 4. Wrap everything in the ParentScaffold to show the Sidebar
        return ParentScaffold(
          title: "Overview",
          activeRoute: "/parent_dashboard", // Highlights "Overview" in sidebar
          child: activeChild,
          body: ListView(
            padding: const EdgeInsets.all(25),
            children: [
              // IDENTITY HEADER
              _buildIdentityCard(context, activeChild),
              const SizedBox(height: 25),
              
              // REAL-TIME USAGE
              _sectionTitle("DAILY APP USAGE"),
              _buildUsageMonitor(activeChild),
              
              const SizedBox(height: 25),

              // AI RECOMMENDATIONS
              _sectionTitle("PLAY TOGETHER ADVICE"),
              _buildAIOfflineRecommendation(db, activeChild),

              const SizedBox(height: 25),

              // QUALITATIVE FEEDBACK
              _sectionTitle("AI TUTOR OBSERVATIONS"),
              _buildAIInsightSummary(activeChild),

              const SizedBox(height: 25),

              // DYNAMIC SUBJECT LIST (Admin added subjects show up here)
              _sectionTitle("SUBJECT PROGRESS"),
              _buildDynamicCategoryBreakdown(db, activeChild, context),
              const SizedBox(height: 50),
            ],
          ),
        );
      },
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildIdentityCard(BuildContext context, ChildProfile child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.ultraViolet, 
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: AppColors.ultraViolet.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))]
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
                Text("Level: ${child.childClass}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
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

  Widget _buildUsageMonitor(ChildProfile child) {
    // Calculate progress (e.g. 10 mins / 30 mins = 0.33)
    double progress = (child.minutesSpentToday / child.dailyLimit).clamp(0.0, 1.0);
    bool isOverLimit = child.minutesSpentToday >= child.dailyLimit;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("App Usage Today", style: TextStyle(fontWeight: FontWeight.bold)),
              // DISPLAY THE REAL MINUTES FROM DATABASE
              Text("${child.minutesSpentToday} / ${child.dailyLimit} mins", 
                style: TextStyle(
                  color: isOverLimit ? Colors.red : AppColors.ultraViolet, 
                  fontWeight: FontWeight.bold
                )),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress, 
              minHeight: 10, 
              backgroundColor: const Color(0xFFFEFACD), 
              valueColor: AlwaysStoppedAnimation(isOverLimit ? Colors.red : AppColors.childBlue)
            ),
          ),
          if (isOverLimit)
             const Padding(
               padding: EdgeInsets.only(top: 8),
               child: Text("Time is up! App is currently locked.", style: TextStyle(color: Colors.red, fontSize: 11)),
             )
        ],
      ),
    );
  }

  Widget _buildAIInsightSummary(ChildProfile child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFEBF5FF), borderRadius: BorderRadius.circular(25)),
      child: const Row(
        children: [
          Icon(Icons.face_retouching_natural, color: Colors.blue, size: 30),
          SizedBox(width: 15),
          Expanded(child: Text("Your child is building a great foundation. Keep up the daily practice!", style: TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildDynamicCategoryBreakdown(DatabaseService db, ChildProfile child, BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: db.streamCategories(),
      builder: (context, catSnapshot) {
        return StreamBuilder<List<Concept>>(
          stream: db.streamConcepts(),
          builder: (context, conceptSnapshot) {
            if (!catSnapshot.hasData || !conceptSnapshot.hasData) return const SizedBox(height: 100);
            
            final validCategories = catSnapshot.data!;
            final allConcepts = conceptSnapshot.data!;

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
              child: Column(
                children: [
                  ...validCategories.map((category) {
                    String catName = category['name'];
                    List<String> conceptIds = allConcepts.where((c) => c.category == catName).map((c) => c.id).toList();
                    double total = 0; int count = 0;
                    for (var id in conceptIds) { if (child.masteryScores.containsKey(id)) { total += child.masteryScores[id]!; count++; } }
                    double avg = count == 0 ? 0 : total / count;
                    return Padding(padding: const EdgeInsets.only(bottom: 15.0), child: _statRow(catName, avg));
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _statRow(String title, double val) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 13)),
            Text("${(val * 100).toInt()}% Mastery", style: const TextStyle(color: AppColors.ultraViolet, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(value: val, minHeight: 8, backgroundColor: AppColors.lemonChiffon, valueColor: const AlwaysStoppedAnimation(AppColors.ultraViolet)),
        )
      ],
    );
  }

  Widget _buildAIOfflineRecommendation(DatabaseService db, ChildProfile child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.ultraViolet, Colors.deepPurple.shade400]), borderRadius: BorderRadius.circular(25)),
      child: const Row(
        children: [
          Icon(Icons.lightbulb, color: Colors.amber, size: 30),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Support their learning", style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                Text("Try an Offline Game", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 5),
                Text("Ask your child to find 3 things in the house that start with 'A'.", style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 10, left: 5), child: Text(title, style: const TextStyle(color: AppColors.ultraViolet, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)));
  }

  Widget _buildNoChildView(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBEE),
      appBar: AppBar(backgroundColor: Colors.white, title: const Text("PARENTAL CONTROL")),
      body: Center(child: TextButton(onPressed: () => Navigator.pushNamed(context, '/add_child'), child: const Text("Create a Child Profile"))),
    );
  }
}