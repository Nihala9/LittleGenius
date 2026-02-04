import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../services/theme_service.dart';
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
  double redirectionLimit = 2; // New variable
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  void _loadConfig() async {
    final config = await _db.getAIConfig();
    setState(() {
      pGuess = config['pGuess'] ?? 0.2;
      pSlip = config['pSlip'] ?? 0.1;
      threshold = config['masteryThreshold'] ?? 0.8;
      redirectionLimit = (config['redirectionLimit'] ?? 2).toDouble();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context);

    return Scaffold(
      backgroundColor: theme.bgColor, 
      appBar: AppBar(
        title: const Text("AI ALGORITHM TUNING", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), 
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
              
              // NEW TUNER: REDIRECTION LIMIT
              _buildTuner(
                theme, 
                "Redirection Attempt Limit", 
                "How many fails before the AI changes the game mode?", 
                redirectionLimit, 
                (v) => setState(() => redirectionLimit = v),
                min: 1, max: 5, divisions: 4, isInteger: true
              ),

              const SizedBox(height: 50),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal, 
                  minimumSize: const Size(double.infinity, 65),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                ),
                onPressed: () async {
                  await _db.updateAIConfig({
                    'pGuess': pGuess, 
                    'pSlip': pSlip, 
                    'masteryThreshold': threshold,
                    'redirectionLimit': redirectionLimit.toInt()
                  });
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("AI Weights Updated Globally")));
                },
                child: const Text("Apply Weights to AI Engine", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
              const Text(
                "Note: These changes affect every child's pedagogical path immediately.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 11),
              )
            ],
          ),
    );
  }

  // UPDATED HELPER: Added min, max, divisions, and isInteger parameters
  Widget _buildTuner(
    ThemeService theme, 
    String title, 
    String desc, 
    double val, 
    Function(double) onChanged,
    {double min = 0.0, double max = 1.0, int? divisions, bool isInteger = false}
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(20),
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
            min: min, 
            max: max, 
            divisions: divisions,
            activeColor: AppColors.teal, 
            inactiveColor: theme.borderColor,
            onChanged: onChanged
          ),
          Align(
            alignment: Alignment.centerRight, 
            child: Text(
              isInteger ? "${val.toInt()} Tries" : "${(val * 100).toInt()}%", 
              style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)
            )
          ),
        ],
      ),
    );
  }
}