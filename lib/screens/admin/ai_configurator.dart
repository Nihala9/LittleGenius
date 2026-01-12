import 'package:flutter/material.dart';

class AIConfigurator extends StatelessWidget {
  const AIConfigurator({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI engine Configuration")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildRuleHeader("Performance Evaluation"),
          _buildSliderSetting("Redirection Threshold", "Trigger mode switch when success rate drops below:", 0.6),
          _buildSliderSetting("Mastery Prediction", "Probability required to mark as mastered:", 0.9),
          const SizedBox(height: 20),
          _buildRuleHeader("Redirection Logic"),
          SwitchListTile(
            title: const Text("Instant Mode Switch"),
            subtitle: const Text("Switch activity type immediately upon consecutive failure"),
            value: true, 
            onChanged: (v){},
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, minimumSize: const Size(double.infinity, 50)),
            onPressed: () {}, 
            child: const Text("Apply Global AI Rules", style: TextStyle(color: Colors.white))
          )
        ],
      ),
    );
  }

  Widget _buildRuleHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
    );
  }

  Widget _buildSliderSetting(String title, String sub, double val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Slider(value: val, onChanged: (v){}, min: 0, max: 1),
      ],
    );
  }
}