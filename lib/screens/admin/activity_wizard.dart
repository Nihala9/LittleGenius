import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/activity_model.dart';

class ActivityWizard extends StatefulWidget {
  const ActivityWizard({super.key});

  @override
  State<ActivityWizard> createState() => _ActivityWizardState();
}

class _ActivityWizardState extends State<ActivityWizard> {
  int _step = 0;
  bool _saving = false;

  // Theme Constants
  final Color primaryIndigo = const Color(0xFF5D5FEF);
  final Color slateGrey = const Color(0xFF64748B);
  final Color bgLight = const Color(0xFFF8FAFC);

  // Controllers
  final titleController = TextEditingController();
  final objectiveController = TextEditingController();

  String? conceptId;
  String lang = 'en-US';
  String mode = 'Visual';
  double mastery = 0.9;

  void _publish() async {
    if (conceptId == null || titleController.text.isEmpty) return;
    setState(() => _saving = true);

    final act = Activity(
      id: '',
      conceptId: conceptId!,
      language: lang,
      activityMode: mode,
      title: titleController.text,
      objective: objectiveController.text,
      type: 'Game',
      subject: 'Literacy',
      ageGroup: '3-7',
      difficulty: 'Easy',
      estimatedTime: 5,
      masteryGoal: mastery,
      retryLimit: 3,
      starReward: 10,
      badgeName: 'Explorer',
      status: ActivityStatus.published,
      createdAt: DateTime.now(),
    );

    try {
      await FirebaseFirestore.instance.collection('activities').add(act.toMap());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: Text("Create Learning Node", 
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF0F0F0), height: 1),
        ),
      ),
      body: _saving
          ? Center(child: CircularProgressIndicator(color: primaryIndigo))
          : Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(primary: primaryIndigo),
              ),
              child: Stepper(
                type: StepperType.vertical,
                currentStep: _step,
                onStepContinue: () => _step < 4 ? setState(() => _step++) : _publish(),
                onStepCancel: () => _step > 0 ? setState(() => _step--) : null,
                controlsBuilder: (context, details) => _buildStepControls(details),
                steps: [
                  _buildStep("Targeting", "Select concept and language", 0, _buildTargeting()),
                  _buildStep("Identity", "Define title and objective", 1, _buildIdentity()),
                  _buildStep("AI Logic", "Choose pedagogical mode", 2, _buildLogic()),
                  _buildStep("Performance Rules", "Set mastery threshold", 3, _buildRules()),
                  _buildStep("Final Review", "Ready for deployment", 4, _buildReview()),
                ],
              ),
            ),
    );
  }

  Step _buildStep(String title, String sub, int index, Widget content) {
    return Step(
      isActive: _step >= index,
      state: _step > index ? StepState.complete : StepState.indexed,
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text(sub, style: GoogleFonts.inter(color: slateGrey, fontSize: 12)),
      content: Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0F0F0)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: content,
      ),
    );
  }

  Widget _buildStepControls(ControlsDetails details) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: details.onStepContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryIndigo,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(_step == 4 ? "PUBLISH NODE" : "CONTINUE",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(width: 12),
          if (_step > 0)
            TextButton(
              onPressed: details.onStepCancel,
              child: Text("BACK", style: GoogleFonts.inter(color: slateGrey, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _buildTargeting() {
    return Column(children: [
      StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('concepts').snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const LinearProgressIndicator();
            return _dropdown("Educational Concept", 
              snap.data!.docs.map((d) => d.id).toList(), (v) => setState(() => conceptId = v));
          }),
      const SizedBox(height: 16),
      _dropdown("Instruction Language", ['en-US', 'ml-IN', 'hi-IN'], (v) => lang = v!),
    ]);
  }

  Widget _buildIdentity() {
    return Column(children: [
      _textField(titleController, "Activity Title", "e.g. Letter A Adventure"),
      const SizedBox(height: 16),
      _textField(objectiveController, "Learning Objective", "Instruction for AI engine", maxLines: 2),
    ]);
  }

  Widget _buildLogic() {
    return _dropdown("Pedagogical Mode", ['Visual', 'Auditory', 'Kinesthetic'], (v) => mode = v!);
  }

  Widget _buildRules() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Goal: ${(mastery * 100).toInt()}% Mastery", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      Slider(value: mastery, min: 0.5, max: 1.0, activeColor: primaryIndigo, onChanged: (v) => setState(() => mastery = v)),
    ]);
  }

  Widget _buildReview() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Targeting: $lang • $conceptId", style: GoogleFonts.inter(fontSize: 13)),
      const SizedBox(height: 8),
      Text("AI Logic: $mode", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: primaryIndigo)),
    ]);
  }

  // UI HELPERS
  Widget _dropdown(String label, List<String> items, Function(String?) onC) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 13, color: slateGrey),
        filled: true,
        fillColor: bgLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.inter(fontSize: 14)))).toList(),
      onChanged: onC,
    );
  }

  Widget _textField(TextEditingController ctrl, String label, String hint, {int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.inter(fontSize: 13, color: slateGrey),
        filled: true,
        fillColor: bgLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}