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
  bool _isSaving = false;

  // STEP 1: CONCEPT & LANGUAGE
  String? selectedConceptId;
  String selectedLang = 'en-US';

  // STEP 2: METADATA
  final titleController = TextEditingController();
  final objectiveController = TextEditingController();
  String selectedSubject = 'Literacy';

  // STEP 3: AI LEARNING MODE
  String selectedMode = 'Tracing'; // Tracing, Matching, Puzzle
  double retryThreshold = 3;

  // STEP 4: GAMIFICATION
  double starReward = 10;

  // --- FINAL PUBLISH FUNCTION ---
  void _publishActivity() async {
    if (selectedConceptId == null || titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a Concept and enter a Title"))
      );
      setState(() => _currentStep = 0);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final newActivity = Activity(
        id: '', // Firestore auto-generates
        title: titleController.text,
        objective: objectiveController.text,
        subject: selectedSubject,
        type: "Game", 
        ageGroup: "3-7", // Baseline range
        difficulty: "Easy",
        estimatedTime: 5,
        language: selectedLang,
        status: ActivityStatus.published,
        createdAt: DateTime.now(),
      );

      // SAVE TO FIRESTORE (Adding 'conceptId' and 'activityMode' to the map)
      Map<String, dynamic> data = newActivity.toMap();
      data['conceptId'] = selectedConceptId;
      data['activityMode'] = selectedMode;
      data['retryThreshold'] = retryThreshold.toInt();
      data['rewardStars'] = starReward.toInt();

      await FirebaseFirestore.instance.collection('activities').add(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Activity Successfully Linked to Concept!"))
        );
        Navigator.pop(context); 
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Performance-Based Creator", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isSaving 
        ? const Center(child: CircularProgressIndicator()) 
        : Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < 4) {
                setState(() => _currentStep++);
              } else {
                _publishActivity();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) setState(() => _currentStep--);
            },
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                      child: Text(_currentStep == 4 ? "PUBLISH TO CLOUD" : "CONTINUE", style: const TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 10),
                    TextButton(onPressed: details.onStepCancel, child: const Text("BACK")),
                  ],
                ),
              );
            },
            steps: [
              // STEP 1: TARGETING
              Step(
                isActive: _currentStep >= 0,
                title: const Text("1. Concept & Language"),
                content: Column(
                  children: [
                    _buildConceptDropdown(),
                    const SizedBox(height: 10),
                    _buildDropdown("Native Language", ['en-US', 'ml-IN', 'hi-IN', 'es-ES'], (val) => selectedLang = val!),
                  ],
                ),
              ),
              // STEP 2: METADATA
              Step(
                isActive: _currentStep >= 1,
                title: const Text("2. Basic Metadata"),
                content: Column(
                  children: [
                    TextField(controller: titleController, decoration: const InputDecoration(labelText: "Activity Title")),
                    const SizedBox(height: 10),
                    _buildDropdown("Category", ['Literacy', 'Numeracy', 'General Knowledge'], (val) => selectedSubject = val!),
                  ],
                ),
              ),
              // STEP 3: AI PERFORMANCE RULES
              Step(
                isActive: _currentStep >= 2,
                title: const Text("3. AI Mode & Redirection"),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDropdown("Teaching Mode", ['Tracing', 'Matching', 'Puzzle', 'Audio'], (val) => selectedMode = val!),
                    const SizedBox(height: 10),
                    Text("Redirection Threshold: ${retryThreshold.toInt()} failures"),
                    Slider(value: retryThreshold, min: 1, max: 5, divisions: 4, onChanged: (v) => setState(() => retryThreshold = v)),
                  ],
                ),
              ),
              // STEP 4: GAMIFICATION
              Step(
                isActive: _currentStep >= 3,
                title: const Text("4. Reward Settings"),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Completion Reward: ${starReward.toInt()} Stars"),
                    Slider(value: starReward, min: 5, max: 100, divisions: 19, onChanged: (v) => setState(() => starReward = v)),
                  ],
                ),
              ),
              // STEP 5: FINAL REVIEW
              Step(
                isActive: _currentStep >= 4,
                title: const Text("5. Review & Publish"),
                content: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Title: ${titleController.text}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("Mode: $selectedMode"),
                      Text("Language: $selectedLang"),
                      const Text("\nStatus: AI is ready to monitor this activity.", style: TextStyle(fontSize: 11, color: Colors.indigo)),
                    ],
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // Fetches Concepts from Firestore so Admin can link activities correctly
  Widget _buildConceptDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('concepts').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        var concepts = snapshot.data!.docs;
        return DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: "Linked Educational Concept"),
          items: concepts.map((c) => DropdownMenuItem(value: c.id, child: Text(c['name']))).toList(),
          onChanged: (val) => setState(() => selectedConceptId = val),
        );
      },
    );
  }

  Widget _buildDropdown(String label, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: label),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        value: items[0],
      ),
    );
  }
}