import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/database_service.dart';
import '../../services/voice_service.dart';
import '../../models/child_model.dart';
import '../../utils/app_colors.dart';
import '../child/child_home_screen.dart'; 
import 'profile_wizard_screen.dart';

class ProfileSelectorScreen extends StatefulWidget {
  const ProfileSelectorScreen({super.key});

  @override
  State<ProfileSelectorScreen> createState() => _ProfileSelectorScreenState();
}

class _ProfileSelectorScreenState extends State<ProfileSelectorScreen> {
  final VoiceService _voiceService = VoiceService();
  final DatabaseService _dbService = DatabaseService();
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _voiceService.initTTS();
  }

  // AI Logout Logic
  void _logoutParent() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Remove saved IDs
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/landing');
  }

  String _getGreeting(String name, String language) {
    switch (language) {
      case 'Malayalam':
        return "Namaskaram $name! Namukku padichu thudangam?";
      case 'Hindi':
        return "Namaste $name! Kya aap khelne ke liye taiyar hain?";
      default:
        return "Hello $name! Are you ready for an adventure?";
    }
  }

  void _onChildSelected(ChildProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activeChildId', profile.id);
    await prefs.setString('activeParentId', user!.uid);

    await _voiceService.speak(_getGreeting(profile.name, profile.language), profile.language);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ChildHomeScreen(child: profile)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      // APPBAR WITH LOGOUT OPTION
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _logoutParent,
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
            label: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text("Who is playing?", 
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 10),
            const Text("Select a profile to start your adventure", style: TextStyle(color: Colors.blueGrey)),
            const SizedBox(height: 30),
            Expanded(
              child: StreamBuilder<List<ChildProfile>>(
                stream: _dbService.streamChildProfiles(user!.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
                  }
                  final profiles = snapshot.data ?? [];
                  return GridView.builder(
                    padding: const EdgeInsets.all(30),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 25, mainAxisSpacing: 25, childAspectRatio: 0.82),
                    itemCount: profiles.length + 1,
                    itemBuilder: (context, index) {
                      if (index == profiles.length) return _buildAddButton();
                      return _buildProfileCard(profiles[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(ChildProfile profile) {
    return GestureDetector(
      onTap: () => _onChildSelected(profile),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: AppColors.primaryBlue.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 45, 
              backgroundColor: AppColors.lavender,
              backgroundImage: NetworkImage(profile.avatarUrl),
            ),
            const SizedBox(height: 15),
            Text(profile.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark)),
            const SizedBox(height: 4),
            Text(profile.language, style: const TextStyle(color: AppColors.accentOrange, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ProfileWizardScreen())),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.lavender, width: 2, style: BorderStyle.solid),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_rounded, size: 55, color: AppColors.primaryBlue),
            SizedBox(height: 10),
            Text("Add Child", style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}