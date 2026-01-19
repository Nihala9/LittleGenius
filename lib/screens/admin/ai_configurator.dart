import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/ai_engine.dart';

class AIConfigurator extends StatefulWidget {
  const AIConfigurator({super.key});

  @override
  State<AIConfigurator> createState() => _AIConfiguratorState();
}

class _AIConfiguratorState extends State<AIConfigurator> {
  // BKT Parameters
  double pLearn = AIEngine.pLearn;
  double pGuess = AIEngine.pGuess;
  double pSlip = AIEngine.pSlip;
  
  // MAB Parameters
  bool instantSwitch = true;

  bool _isSaving = false;

  final Color primaryIndigo = const Color(0xFF4F46E5);
  final Color slate900 = const Color(0xFF0F172A);

  void _saveGlobalRules() async {
    setState(() => _isSaving = true);
    
    try {
      await FirebaseFirestore.instance.collection('settings').doc('ai_rules').set({
        'pLearn': pLearn,
        'pGuess': pGuess,
        'pSlip': pSlip,
        'instantSwitch': instantSwitch,
        'updatedAt': DateTime.now(),
      });

      AIEngine.syncRules({
        'pLearn': pLearn,
        'pGuess': pGuess,
        'pSlip': pSlip,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Global AI Parameters Synchronized"),
            backgroundColor: Color(0xFF0D9488),
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } catch (e) {
      debugPrint("Save Error: $e");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("AI Rule Engine", 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: slate900,
        elevation: 0,
        centerTitle: false,
      ),
      body: _isSaving 
        ? const Center(child: CircularProgressIndicator()) 
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSectionHeader("Mastery Prediction (BKT)", Icons.auto_graph_rounded),
              _buildDescription("Tweak how the Bayesian Knowledge Tracing algorithm calculates child mastery probability."),
              
              _ruleCard("Learning Probability", "Chance the child learns a concept per attempt.", pLearn, (v) => setState(() => pLearn = v)),
              _ruleCard("Guess Probability", "Chance of a 'lucky guess' without mastery.", pGuess, (v) => setState(() => pGuess = v)),
              _ruleCard("Slip Probability", "Chance of a mistake despite mastering.", pSlip, (v) => setState(() => pSlip = v)),

              const SizedBox(height: 30),
              _buildSectionHeader("Adaptive Branching (MAB)", Icons.alt_route_rounded),
              _buildDescription("Rules for the Multi-Armed Bandit engine to redirect children to alternative modes."),
              
              _switchCard("Instant Mode Redirection", "Switch teaching style immediately upon detected struggle.", instantSwitch, (v) => setState(() => instantSwitch = v)),

              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _saveGlobalRules,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryIndigo,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: const Text("Apply Intelligence Rules", 
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 50),
            ],
          ),
    );
  }

  // --- MODERN UI COMPONENTS ---

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: primaryIndigo),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: slate900)),
      ],
    );
  }

  Widget _buildDescription(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 20),
      child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
    );
  }

  Widget _ruleCard(String title, String sub, double value, Function(double) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text("${(value * 100).toInt()}%", 
                style: TextStyle(color: primaryIndigo, fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              activeTrackColor: primaryIndigo,
              thumbColor: primaryIndigo,
              overlayColor: primaryIndigo.withOpacity(0.1),
            ),
            child: Slider(value: value, min: 0.05, max: 0.8, divisions: 15, onChanged: onChanged),
          ),
        ],
      ),
    );
  }

  Widget _switchCard(String title, String sub, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 11)),
        activeColor: primaryIndigo,
        value: value, 
        onChanged: onChanged,
      ),
    );
  }
}