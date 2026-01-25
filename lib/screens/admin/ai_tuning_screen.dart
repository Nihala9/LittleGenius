import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Add this
import '../../services/database_service.dart';
import '../../services/theme_service.dart'; // Add this
import '../../utils/app_colors.dart';

class AITuningScreen extends StatefulWidget {
  const AITuningScreen({super.key});

  @override
  State<AITuningScreen> createState() => _AITuningScreenState();
}

class _AITuningScreenState extends State<AITuningScreen> {
  final _db = DatabaseService();
  double pGuess = 0.2;
  double pSlip = 0.1;
  double threshold = 0.8;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  void _loadConfig() async {
    final config = await _db.getAIConfig();
    setState(() {
      pGuess = config['pGuess'];
      pSlip = config['pSlip'];
      threshold = config['masteryThreshold'];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Fetch Global Theme
    final theme = Provider.of<ThemeService>(context);

    return Scaffold(
      // 2. Use Dynamic Colors
      backgroundColor: theme.bgColor, 
      appBar: AppBar(
        title: const Text("AI ALGORITHM TUNING"), 
        backgroundColor: theme.cardColor, 
        foregroundColor: theme.textColor,
        elevation: 0,
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator()) 
        : ListView(
            padding: const EdgeInsets.all(25),
            children: [
              _buildTuner(theme, "BKT: Guess Probability", "Chance a child gets lucky.", pGuess, (v) => setState(() => pGuess = v)),
              _buildTuner(theme, "BKT: Slip Probability", "Chance a child misses despite knowing.", pSlip, (v) => setState(() => pSlip = v)),
              _buildTuner(theme, "Mastery Threshold", "Required score for next level.", threshold, (v) => setState(() => threshold = v)),
              const SizedBox(height: 50),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal, 
                  minimumSize: const Size(double.infinity, 65),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                ),
                onPressed: () async {
                  await _db.updateAIConfig({'pGuess': pGuess, 'pSlip': pSlip, 'masteryThreshold': threshold});
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("AI Weights Updated")));
                },
                child: const Text("Apply Weights to AI Engine", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          ),
    );
  }

  Widget _buildTuner(ThemeService theme, String title, String desc, double val, Function(double) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(20),
      // 3. Use Dynamic Colors for the Cards
      decoration: BoxDecoration(
        color: theme.cardColor, 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: theme.borderColor)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(desc, style: TextStyle(color: theme.subTextColor, fontSize: 12)),
          const SizedBox(height: 10),
          Slider(
            value: val, 
            min: 0.0, 
            max: 1.0, 
            activeColor: AppColors.teal, 
            inactiveColor: theme.borderColor,
            onChanged: onChanged
          ),
          Align(
            alignment: Alignment.centerRight, 
            child: Text("${(val * 100).toInt()}%", 
              style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }
}