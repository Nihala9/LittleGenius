import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/concept_model.dart';

class ConceptManager extends StatelessWidget {
  const ConceptManager({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Modern Slate 50
      appBar: AppBar(
        title: const Text("Concept Configuration", 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Learning Goals", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text("Define AI performance targets for concepts", style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          Expanded(child: _buildConceptList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddConceptDialog(context),
        label: const Text("New Concept", style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_task_rounded),
        backgroundColor: const Color.fromARGB(255, 172, 218, 247), // Professional Teal
      ),
    );
  }

  Widget _buildConceptList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('concepts').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No concepts defined yet.", style: TextStyle(color: Colors.grey)));
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final concept = Concept.fromMap(docs[index].data() as Map<String, dynamic>, docs[index].id);
            return _buildConceptCard(context, concept, docs[index].reference);
          },
        );
      },
    );
  }

  Widget _buildConceptCard(BuildContext context, Concept concept, DocumentReference ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.psychology_rounded, color: Color(0xFF0D9488), size: 24),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryBadge(concept.category),
            const SizedBox(height: 6),
            Text(concept.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A))),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              const Icon(Icons.auto_graph_rounded, size: 14, color: Colors.blueGrey),
              const SizedBox(width: 6),
              Text("Mastery Goal: ${(concept.masteryThreshold * 100).toInt()}%", 
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
          onPressed: () => _confirmDelete(context, ref),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
      child: Text(category.toUpperCase(), 
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF475569), letterSpacing: 0.5)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: const Text("Define Concept Node", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("This name must match the 'Concept ID' in your learning activities.", 
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: _inputStyle("Concept Name", "e.g. Letter_A"),
                ),
                const SizedBox(height: 20),
                _buildDropdown("Category", ['Literacy', 'Numeracy', 'General Knowledge'], (v) => setState(() => category = v!)),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Mastery Target", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text("${(threshold * 100).toInt()}%", style: const TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: threshold, min: 0.5, max: 1.0, divisions: 5,
                  activeColor: const Color(0xFF0D9488),
                  onChanged: (v) => setState(() => threshold = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
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
              child: const Text("Save Node", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, DocumentReference ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Concept?"),
        content: const Text("This will remove the educational link for all associated activities."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Keep")),
          TextButton(onPressed: () { ref.delete(); Navigator.pop(context); }, child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  InputDecoration _inputStyle(String label, String hint) {
    return InputDecoration(
      labelText: label, hintText: hint, filled: true, fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  Widget _buildDropdown(String label, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: _inputStyle(label, ""),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      value: items[0],
    );
  }
}