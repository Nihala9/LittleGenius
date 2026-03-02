import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/child_model.dart';
import '../../services/database_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/parent_scaffold.dart';

class ScreenTimeSettingsScreen extends StatefulWidget {
  final ChildProfile child;
  const ScreenTimeSettingsScreen({super.key, required this.child});

  @override
  State<ScreenTimeSettingsScreen> createState() => _ScreenTimeSettingsScreenState();
}

class _ScreenTimeSettingsScreenState extends State<ScreenTimeSettingsScreen> {
  late double _currentLimit;
  final _db = DatabaseService();

  @override
  void initState() {
    super.initState();
    _currentLimit = widget.child.dailyLimit.toDouble();
  }

  void _saveLimit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _db.updateChildProfile(
      user.uid, 
      widget.child.id, 
      {'dailyLimit': _currentLimit.toInt()}
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usage limit updated successfully!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ParentScaffold(
      title: "Time Limits",
      activeRoute: "limits", // Highlights 'Time Limits' in sidebar
      child: widget.child,
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            const Icon(Icons.hourglass_bottom_rounded, size: 80, color: AppColors.accentOrange),
            const SizedBox(height: 20),
            Text("Daily Limit for ${widget.child.name}", 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.childNavy)),
            const SizedBox(height: 50),
            
            Text("${_currentLimit.toInt()} Minutes", 
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
            const SizedBox(height: 10),
            const Text("Adjust the slider to set a limit", style: TextStyle(color: Colors.grey)),
            
            const SizedBox(height: 40),
            Slider(
              value: _currentLimit,
              min: 5, 
              max: 120,
              divisions: 23,
              activeColor: AppColors.primaryBlue,
              inactiveColor: AppColors.cloudySky,
              onChanged: (val) => setState(() => _currentLimit = val),
            ),
            
            const Spacer(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "When this limit is reached, the app will automatically lock until a parent unlocks it.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blueGrey, fontSize: 13),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60), 
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: _saveLimit, 
              child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
            ),
          ],
        ),
      ),
    );
  }
}