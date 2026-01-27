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
    // Pre-initialize the AI Voice engine so it's ready for greetings
    _voiceService.initTTS(); 
  }

  // --- LOGOUT LOGIC ---
  // This clears the parent's session and the local child persistence
  void _logoutParent() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/landing');
  }

  // --- MULTILINGUAL GREETING LOGIC ---
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
    // 1. Persist selection so app re-opens to this child
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activeChildId', profile.id);
    await prefs.setString('activeParentId', user!.uid);

    // 2. Trigger AI Buddy Greeting
    await _voiceService.speak(_getGreeting(profile.name, profile.language), profile.language);

    if (!mounted) return;
    
    // 3. Enter the Child Home (The adventure dashboard)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ChildHomeScreen(child: profile)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Automatically hides the back button if it exists
        automaticallyImplyLeading: false, 
        actions: [
          // Clear Logout option for the Parent
          TextButton.icon(
            onPressed: _logoutParent,
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
            label: const Text("Logout", 
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 15),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              "Who is playing?", 
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textDark, letterSpacing: -1)
            ),
            const SizedBox(height: 10),
            const Text(
              "Select a profile to start your adventure", 
              style: TextStyle(color: Colors.blueGrey)
            ),
            const SizedBox(height: 40),
            
            Expanded(
              child: StreamBuilder<List<ChildProfile>>(
                stream: _dbService.streamChildProfiles(user!.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
                  }
                  
                  final profiles = snapshot.data ?? [];

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, 
                      crossAxisSpacing: 25, 
                      mainAxisSpacing: 25, 
                      childAspectRatio: 0.82
                    ),
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

  // --- WIDGET: CHILD PROFILE CARD ---
  Widget _buildProfileCard(ChildProfile profile) {
    return GestureDetector(
      onTap: () => _onChildSelected(profile),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withAlpha(20), 
              blurRadius: 20, 
              offset: const Offset(0, 10)
            )
          ],
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
            Text(
              profile.name, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark)
            ),
            const SizedBox(height: 4),
            Text(
              profile.language, 
              style: const TextStyle(color: AppColors.accentOrange, fontSize: 11, fontWeight: FontWeight.bold)
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET: ADD PROFILE BUTTON ---
  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (c) => const ProfileWizardScreen())
      ),
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
            Text(
              "Add Child", 
              style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)
            ),
          ],
        ),
      ),
    );
  }
}