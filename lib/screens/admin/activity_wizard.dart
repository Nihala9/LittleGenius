import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/activity_model.dart';

class ActivityWizard extends StatefulWidget {
  const ActivityWizard({super.key});

  @override
  State<ActivityWizard> createState() => _ActivityWizardState();
}

class _ActivityWizardState extends State<ActivityWizard> {
  int _currentStep = 0;
  bool _saving = false;

  // --- Requirement 1 & 2: Targeting ---
  String? conceptId;
  String lang = 'en-US';
  String subject = 'Literacy';

  // --- Requirement 3 & Metadata: Identity ---
  final titleController = TextEditingController();
  String mode = 'Visual';
  String type = 'Game';
  String ageGroup = '3-4';
  String difficulty = 'Easy';

  // --- Requirement 4: AI Rules ---
  double mastery = 0.9;
  double retries = 3;

  // --- Requirement 5: Gamification ---
  double stars = 10;

  // --- Req 6: Final Publish Logic ---
  void _publish() async {
    if (conceptId == null || titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Missing Concept or Title! Check Step 1 & 2.")),
      );
      setState(() => _currentStep = 0);
      return;
    }

    setState(() => _saving = true);

    try {
      final act = Activity(
        id: '', // Firestore auto-id
        conceptId: conceptId!,
        language: lang,
        activityMode: mode,
        title: titleController.text,
        type: type,
        subject: subject,
        ageGroup: ageGroup,
        difficulty: difficulty,
        estimatedTime: 5, // Default for now
        masteryGoal: mastery,
        retryLimit: retries.toInt(),
        starReward: stars.toInt(),
        badgeName: 'Hero',
        status: ActivityStatus.published,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance.collection('activities').add(act.toMap());
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Success! Activity is now live."), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Authoring Wizard", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
      ),
      body: _saving 
        ? const Center(child: CircularProgressIndicator()) 
        : Theme(
            data: ThemeData(colorScheme: ColorScheme.light(primary: Colors.indigo)),
            child: Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              onStepContinue: () => _currentStep < 4 ? setState(() => _currentStep++) : _publish(),
              onStepCancel: () => _currentStep > 0 ? setState(() => _currentStep--) : null,
              controlsBuilder: _buildControls,
              steps: [
                _buildStep("Targeting", "Map concept and language", 0, _targetingUI()),
                _buildStep("Activity Details", "Basic identity and metadata", 1, _identityUI()),
                _buildStep("AI Engine Rules", "Configure BKT and MAB logic", 2, _aiRulesUI()),
                _buildStep("Engagement", "Set reward weights", 3, _rewardsUI()),
                _buildStep("Preview", "Final validation", 4, _reviewUI()),
              ],
            ),
          ),
    );
  }

  // --- STEP UI BUILDERS ---

  Widget _targetingUI() {
    return Column(children: [
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('concepts').snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const LinearProgressIndicator();
          return _dropdown("Concept Node", snap.data!.docs.map((d) => d.id).toList(), (v) => conceptId = v);
        }),
      _dropdown("Guidance Language", ['en-US', 'ml-IN', 'hi-IN'], (v) => lang = v!),
      _dropdown("Subject Category", ['Literacy', 'Numeracy', 'Science', 'Logic'], (v) => subject = v!),
    ]);
  }

  Widget _identityUI() {
    return Column(children: [
      TextField(controller: titleController, decoration: const InputDecoration(labelText: "Activity Title", border: OutlineInputBorder())),
      _dropdown("AI Mode", ['Kinesthetic', 'Visual', 'Auditory'], (v) => mode = v!),
      _dropdown("Target Age", ['2-3', '3-4', '5-6', '7-8'], (v) => ageGroup = v!),
    ]);
  }

  Widget _aiRulesUI() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Mastery Goal: ${(mastery * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold)),
      Slider(value: mastery, min: 0.5, max: 1.0, divisions: 5, onChanged: (v) => setState(() => mastery = v)),
      Text("Redirection Trigger: ${retries.toInt()} failures", style: const TextStyle(fontWeight: FontWeight.bold)),
      Slider(value: retries, min: 1, max: 5, divisions: 4, onChanged: (v) => setState(() => retries = v)),
    ]);
  }

  Widget _rewardsUI() {
    return Column(children: [
      Text("Star Reward: ${stars.toInt()}"),
      Slider(value: stars, min: 5, max: 50, divisions: 9, activeColor: Colors.orange, onChanged: (v) => setState(() => stars = v)),
    ]);
  }

  Widget _reviewUI() {
    return Container(
      padding: const EdgeInsets.all(15),
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Activity: ${titleController.text}", style: const TextStyle(fontWeight: FontWeight.bold)),
        Text("Mode: $mode | Lang: $lang"),
        Text("AI Rules: Redirect after ${retries.toInt()} fails."),
      ]),
    );
  }

  // --- HELPERS ---

  Step _buildStep(String t, String s, int i, Widget c) {
    return Step(
      isActive: _currentStep >= i,
      state: _currentStep > i ? StepState.complete : StepState.indexed,
      title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(s),
      content: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: c),
    );
  }

  Widget _dropdown(String l, List<String> items, Function(String?) onC) {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: l, border: const OutlineInputBorder()),
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
        onChanged: onC,
      ),
    );
  }

  Widget _buildControls(BuildContext context, ControlsDetails d) {
    bool isLast = _currentStep == 4;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(children: [
        ElevatedButton(
          onPressed: d.onStepContinue,
          style: ElevatedButton.styleFrom(backgroundColor: isLast ? Colors.green : Colors.indigo),
          child: Text(isLast ? "PUBLISH" : "NEXT", style: const TextStyle(color: Colors.white)),
        ),
        if (_currentStep > 0)
          TextButton(onPressed: d.onStepCancel, child: const Text("BACK")),
      ]),
    );
  }
}