import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/activity_model.dart';

class ActivityEditorScreen extends StatefulWidget {
  final Activity? activity;

  const ActivityEditorScreen({super.key, this.activity});

  @override
  State<ActivityEditorScreen> createState() => _ActivityEditorScreenState();
}

class _ActivityEditorScreenState extends State<ActivityEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController titleController;
  late TextEditingController objectiveController;
  late TextEditingController optA, optB, optC, optD;
  late TextEditingController badgeController;

  String? selectedConceptId;
  String selectedLang = 'en-US';
  String selectedMode = 'Visual';
  String selectedType = 'Alphabet';
  String selectedSubject = 'Literacy';
  String selectedAge = '3-4';
  String selectedDifficulty = 'Easy';
  String correctAnswer = "A";
  double masteryThreshold = 0.9;
  double retryLimit = 3;
  double starReward = 10;

  @override
  void initState() {
    super.initState();
    final act = widget.activity;
    
    titleController = TextEditingController(text: act?.title ?? "");
    objectiveController = TextEditingController(text: act?.objective ?? "");
    optA = TextEditingController(); 
    optB = TextEditingController();
    optC = TextEditingController();
    optD = TextEditingController();
    badgeController = TextEditingController(text: act?.badgeName ?? "Logic Explorer");

    if (act != null) {
      selectedConceptId = act.conceptId;
      selectedLang = act.language;
      selectedMode = act.activityMode;
      selectedType = act.type;
      selectedSubject = act.subject;
      selectedAge = act.ageGroup;
      selectedDifficulty = act.difficulty;
      masteryThreshold = act.masteryGoal;
      retryLimit = act.retryLimit.toDouble();
      starReward = act.starReward.toDouble();
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    objectiveController.dispose();
    optA.dispose(); optB.dispose(); optC.dispose(); optD.dispose();
    badgeController.dispose();
    super.dispose();
  }

  void _saveActivity() async {
    if (_formKey.currentState!.validate() && selectedConceptId != null) {
      final data = Activity(
        id: widget.activity?.id ?? '',
        conceptId: selectedConceptId!,
        language: selectedLang,
        activityMode: selectedMode,
        title: titleController.text,
        objective: objectiveController.text, // Correctly using objective now
        type: selectedType,
        subject: selectedSubject,
        ageGroup: selectedAge,
        difficulty: selectedDifficulty,
        estimatedTime: 5,
        masteryGoal: masteryThreshold,
        retryLimit: retryLimit.toInt(),
        starReward: starReward.toInt(),
        badgeName: badgeController.text,
        status: ActivityStatus.published,
        createdAt: widget.activity?.createdAt ?? DateTime.now(),
      );

      if (widget.activity == null) {
        await FirebaseFirestore.instance.collection('activities').add(data.toMap());
      } else {
        await FirebaseFirestore.instance.collection('activities').doc(widget.activity!.id).update(data.toMap());
      }

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.activity == null ? "Create Activity" : "Edit Activity",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildSection("Targeting", Icons.track_changes, Column(children: [
                _buildConceptSelector(),
                const SizedBox(height: 15),
                Row(children: [
                  Expanded(child: _buildDropdown("Language", ['en-US', 'ml-IN', 'hi-IN'], (v) => setState(() => selectedLang = v!))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDropdown("Subject", ['Literacy', 'Numeracy', 'Science'], (v) => setState(() => selectedSubject = v!))),
                ]),
              ])),
              _buildSection("Content", Icons.edit_note, Column(children: [
                TextFormField(controller: titleController, decoration: _inputStyle("Title", null)),
                const SizedBox(height: 15),
                TextFormField(controller: objectiveController, maxLines: 3, decoration: _inputStyle("Instructions", null)),
              ])),
              _buildSection("AI Rules", Icons.psychology, Column(children: [
                _buildDropdown("Mode", ['Kinesthetic', 'Visual', 'Auditory'], (v) => setState(() => selectedMode = v!)),
                Slider(value: masteryThreshold, min: 0.5, max: 1.0, onChanged: (v) => setState(() => masteryThreshold = v)),
              ])),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveActivity,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), minimumSize: const Size(double.infinity, 60)),
                child: const Text("Save Activity", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: Colors.indigo, size: 20), const SizedBox(width: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.bold))]),
        const Divider(height: 30),
        content,
      ]),
    );
  }

  InputDecoration _inputStyle(String label, IconData? icon) {
    return InputDecoration(labelText: label, filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none));
  }

  Widget _buildDropdown(String label, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: _inputStyle(label, null),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      value: items[0],
    );
  }

  Widget _buildConceptSelector() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('concepts').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        return DropdownButtonFormField<String>(
          decoration: _inputStyle("Concept Node", null),
          items: snapshot.data!.docs.map((c) => DropdownMenuItem(value: c.id, child: Text(c['name']))).toList(),
          onChanged: (val) => setState(() => selectedConceptId = val),
        );
      },
    );
  }
}