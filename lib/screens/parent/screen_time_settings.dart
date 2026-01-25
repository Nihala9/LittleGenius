import 'package:flutter/material.dart';
import '../../models/child_model.dart';
import '../../services/database_service.dart';
import '../../utils/app_colors.dart';

class ScreenTimeSettingsScreen extends StatefulWidget {
  final ChildProfile child;
  const ScreenTimeSettingsScreen({super.key, required this.child});

  @override
  State<ScreenTimeSettingsScreen> createState() => _ScreenTimeSettingsScreenState();
}

class _ScreenTimeSettingsScreenState extends State<ScreenTimeSettingsScreen> {
  double _currentLimit = 30; // Default 30 mins
  final _db = DatabaseService();

  void _saveLimit() async {
    // Save to a new 'screenTime' field in the child's profile
    await _db.updateChildProfile(
      "PARENT_ID", // Get current UID
      widget.child.id, 
      {'dailyLimit': _currentLimit.toInt()}
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Usage limit updated!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Screen Time Settings")),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            const Icon(Icons.hourglass_bottom_rounded, size: 80, color: AppColors.accentOrange),
            const SizedBox(height: 20),
            Text("Daily Limit for ${widget.child.name}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 50),
            
            Text("${_currentLimit.toInt()} Minutes", 
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
            
            Slider(
              value: _currentLimit,
              min: 5, max: 120,
              divisions: 23,
              activeColor: AppColors.primaryBlue,
              onChanged: (val) => setState(() => _currentLimit = val),
            ),
            
            const Text("The app will automatically lock after this time.", style: TextStyle(color: Colors.grey)),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: AppColors.primaryBlue),
              onPressed: _saveLimit, 
              child: const Text("Save Limit", style: TextStyle(color: Colors.white))
            ),
          ],
        ),
      ),
    );
  }
}