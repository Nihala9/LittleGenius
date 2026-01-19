import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/child_profile.dart';
import 'activity_screen.dart';

class AdventureMapScreen extends StatefulWidget {
  final ChildProfile child;
  const AdventureMapScreen({super.key, required this.child});

  @override
  State<AdventureMapScreen> createState() => _AdventureMapScreenState();
}

class _AdventureMapScreenState extends State<AdventureMapScreen> {
  bool _isChecking = false; // Loading state to prevent double-clicks

  // US 04: The gatekeeper function
  void _startAdventure(String conceptId) async {
    setState(() => _isChecking = true);

    // Fetch activities that are specifically PUBLISHED and match the LANGUAGE
    var snapshot = await FirebaseFirestore.instance
        .collection('activities')
        .where('conceptId', isEqualTo: conceptId)
        .where('status', isEqualTo: 'published') 
        .where('language', isEqualTo: widget.child.language)
        .get();

    setState(() => _isChecking = false);

    if (!mounted) return;

    if (snapshot.docs.isNotEmpty) {
      // SUCCESS: At least one version of this lesson is published
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ActivityScreen(child: widget.child, conceptId: conceptId),
        ),
      );
    } else {
      // FAILURE: Content is in DRAFT mode or doesn't exist
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This adventure is being updated by the Admin. Try again soon!"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Learning Map", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isChecking 
        ? const Center(child: CircularProgressIndicator()) 
        : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // MUST USE _startAdventure logic here
                _buildMapNode("Alphabets", "Letter_A", Icons.abc, Colors.purple),
                const SizedBox(height: 30),
                _buildMapNode("Numbers", "Number_1", Icons.calculate, Colors.orange),
              ],
            ),
          ),
    );
  }

  Widget _buildMapNode(String title, String cId, IconData icon, Color color) {
    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: () => _startAdventure(cId), // This calls the database check
      child: Column(
        children: [
          CircleAvatar(
            radius: 45, 
            backgroundColor: color.withOpacity(0.1), 
            child: Icon(icon, color: color, size: 40)
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}