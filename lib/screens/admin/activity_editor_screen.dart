import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/activity_model.dart'; // Corrected import path

class ActivityEditorScreen extends StatefulWidget {
  const ActivityEditorScreen({super.key});

  @override
  State<ActivityEditorScreen> createState() => _ActivityEditorScreenState();
}

class _ActivityEditorScreenState extends State<ActivityEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final titleController = TextEditingController();
  final objectiveController = TextEditingController();
  
  // Form Values
  String selectedSubject = 'Math';
  String selectedType = 'Game';
  String selectedAge = '3-4';
  String selectedDifficulty = 'Easy';
  String selectedLang = 'en-US'; // Added for Universal Language Support
  double estimatedTime = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Content Authoring Workspace", 
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Discard")),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              onPressed: _saveActivity, 
              child: const Text("Publish Activity")
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("1. Basic Metadata", Icons.info_outline),
              const SizedBox(height: 20),
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Activity Title", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildDropdown("Subject", ['Math', 'Reading', 'Science', 'Logic'], (v) => selectedSubject = v!)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildDropdown("Language", ['en-US', 'ml-IN', 'hi-IN', 'es-ES', 'fr-FR'], (v) => selectedLang = v!)),
                ],
              ),
              
              const SizedBox(height: 30),
              _buildSectionHeader("2. Adaptive Learning Rules", Icons.psychology),
              const SizedBox(height: 20),
              TextFormField(
                controller: objectiveController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Learning Objective (Instructions for AI Redirection)", 
                  border: OutlineInputBorder()
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildDropdown("Target Age", ['2-3', '3-4', '5-6', '7-8'], (v) => selectedAge = v!)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildDropdown("Baseline Difficulty", ['Easy', 'Medium', 'Hard'], (v) => selectedDifficulty = v!)),
                ],
              ),
              
              const SizedBox(height: 30),
              Text("Estimated Completion Time: ${estimatedTime.toInt()} mins", 
                style: const TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                value: estimatedTime,
                activeColor: Colors.indigo,
                min: 2, max: 20, divisions: 9,
                onChanged: (v) => setState(() => estimatedTime = v),
              ),

              const SizedBox(height: 30),
              _buildSectionHeader("3. Multimedia & Gamification", Icons.perm_media),
              const SizedBox(height: 15),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.02), 
                  borderRadius: BorderRadius.circular(12), 
                  border: Border.all(color: Colors.indigo.withOpacity(0.1))
                ),
                child: const Column(
                  children: [
                    Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.indigo),
                    SizedBox(height: 10),
                    Text("Upload Game Assets (Lottie/Images/Audio)", 
                      style: TextStyle(color: Colors.indigo, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.indigo, size: 20),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      value: items.contains(label == "Language" ? selectedLang : selectedSubject) ? null : items[0],
      onChanged: onChanged,
    );
  }

  void _saveActivity() async {
    if (_formKey.currentState!.validate()) {
      final activity = Activity(
        id: '', // Generated by Firestore
        title: titleController.text,
        objective: objectiveController.text,
        subject: selectedSubject,
        type: selectedType,
        ageGroup: selectedAge,
        difficulty: selectedDifficulty,
        estimatedTime: estimatedTime.toInt(),
        language: selectedLang,
        status: ActivityStatus.published,
        createdAt: DateTime.now(),
      );
      
      await FirebaseFirestore.instance.collection('activities').add(activity.toMap());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Activity Published Successfully")));
        Navigator.pop(context);
      }
    }
  }
}