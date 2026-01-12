import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/concept_model.dart';

class ConceptManager extends StatelessWidget {
  const ConceptManager({super.key}); // This matches the 'const ConceptManager()' in main.dart

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Educational Concepts"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        elevation: 0.5,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('concepts').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final concept = Concept.fromMap(docs[index].data() as Map<String, dynamic>, docs[index].id);
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.psychology, color: Colors.teal),
                  title: Text(concept.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${concept.category} • Target: ${(concept.masteryThreshold * 100).toInt()}%"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => docs[index].reference.delete(),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddConceptDialog(context),
        label: const Text("New Concept"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
    );
  }

  void _showAddConceptDialog(BuildContext context) {
    final nameController = TextEditingController();
    String category = 'Literacy';
    double threshold = 0.9;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Define Concept"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name (e.g. Letter_A)")),
              DropdownButtonFormField<String>(
                value: category,
                items: ['Literacy', 'Numeracy', 'General Knowledge'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => category = v!),
                decoration: const InputDecoration(labelText: "Category"),
              ),
              const SizedBox(height: 20),
              Text("Mastery Goal: ${(threshold * 100).toInt()}%"),
              Slider(value: threshold, min: 0.5, max: 1.0, divisions: 5, onChanged: (v) => setState(() => threshold = v)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('concepts').doc(nameController.text).set({
                    'name': nameController.text,
                    'category': category,
                    'masteryThreshold': threshold,
                    'retryThreshold': 3, 
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Save"),
            )
          ],
        ),
      ),
    );
  }
}