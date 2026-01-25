import 'package:flutter/material.dart';
import '../../models/child_model.dart';
import '../../models/concept_model.dart';
import '../../services/database_service.dart';
import '../../utils/app_colors.dart';

class ResourceGridScreen extends StatelessWidget {
  final ChildProfile child;
  final String category;
  const ResourceGridScreen({super.key, required this.child, required this.category});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    return Scaffold(
      appBar: AppBar(title: Text("Discover $category"), elevation: 0),
      body: StreamBuilder<List<Concept>>(
        stream: db.streamConceptsByCategory(category),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(25),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 20, crossAxisSpacing: 20),
            itemCount: items.length,
            itemBuilder: (context, i) => _buildDiscoveryCard(items[i]),
          );
        },
      ),
    );
  }

  Widget _buildDiscoveryCard(Concept concept) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.accentOrange, size: 20),
          const SizedBox(height: 10),
          Text(concept.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Text("Story & Play", style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}