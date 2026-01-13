import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/activity_model.dart';

class ActivityEditorScreen extends StatefulWidget {
  const ActivityEditorScreen({super.key});

  @override
  State<ActivityEditorScreen> createState() => _ActivityEditorScreenState();
}

class _ActivityEditorScreenState extends State<ActivityEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final titleController = TextEditingController();
  final objectiveController = TextEditingController();
  final badgeController = TextEditingController(text: "Logic Explorer");
  
  String? selectedConceptId;
  String selectedLang = 'en-US';
  String selectedMode = 'Visual'; 
  String selectedType = 'Game';   
  String selectedSubject = 'Literacy';
  String selectedAge = '3-4';
  String selectedDifficulty = 'Easy';
  double masteryThreshold = 0.9;
  double retryLimit = 3;
  double starReward = 10;
  double estimatedTime = 5;

  final Color primaryIndigo = const Color(0xFF4F46E5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Content Workspace", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildSection("AI Logic", Icons.psychology, Column(children: [
                _buildConceptSelector(),
                _buildDropdown("AI Redirection Mode", ['Kinesthetic', 'Visual', 'Auditory'], (v) => selectedMode = v!),
              ])),

              _buildSection("Metadata", Icons.settings_input_component, Column(children: [
                _buildDropdown("Subject", ['Literacy', 'Numeracy', 'Science', 'Logic'], (v) => selectedSubject = v!),
                _buildDropdown("Age Group", ['2-3', '3-4', '5-6', '7-8'], (v) => selectedAge = v!),
                _buildDropdown("Difficulty", ['Easy', 'Medium', 'Hard'], (v) => selectedDifficulty = v!),
              ])),

              _buildSection("Identity", Icons.badge_outlined, Column(children: [
                TextFormField(controller: titleController, decoration: const InputDecoration(labelText: "Activity Title", border: OutlineInputBorder())),
                _buildDropdown("Guidance Language", ['en-US', 'ml-IN', 'hi-IN'], (v) => selectedLang = v!),
              ])),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _saveActivity,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryIndigo,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Publish Activity", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 50),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: primaryIndigo, size: 20), const SizedBox(width: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
        const Divider(height: 30),
        content,
      ]),
    );
  }

  Widget _buildConceptSelector() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('concepts').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        return DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: "Concept Node"),
          items: snapshot.data!.docs.map((c) => DropdownMenuItem(value: c.id, child: Text(c['name']))).toList(),
          onChanged: (val) => setState(() => selectedConceptId = val),
        );
      },
    );
  }

  Widget _buildDropdown(String label, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        value: items[0],
      ),
    );
  }

  void _saveActivity() async {
    if (_formKey.currentState!.validate() && selectedConceptId != null) {
      // FIX: Passing all defined named parameters
      final activity = Activity(
        id: '', 
        conceptId: selectedConceptId!,
        language: selectedLang,
        activityMode: selectedMode,
        title: titleController.text,
        type: selectedType,
        subject: selectedSubject,      // Now defined in model
        ageGroup: selectedAge,         // Now defined in model
        difficulty: selectedDifficulty, // Now defined in model
        estimatedTime: estimatedTime.toInt(), // Now defined in model
        masteryGoal: masteryThreshold,
        retryLimit: retryLimit.toInt(),
        starReward: starReward.toInt(),
        badgeName: badgeController.text,
        status: ActivityStatus.published,
        createdAt: DateTime.now(),
      );
      
      await FirebaseFirestore.instance.collection('activities').add(activity.toMap());
      if (mounted) Navigator.pop(context);
    }
  }
}