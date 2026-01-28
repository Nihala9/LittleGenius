import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/database_service.dart';
import '../../services/voice_service.dart';
import '../../models/child_model.dart';
import '../../utils/app_colors.dart';
import '../child/child_home_screen.dart';

class ProfileSelectorScreen extends StatefulWidget {
  const ProfileSelectorScreen({super.key});
  @override
  State<ProfileSelectorScreen> createState() => _ProfileSelectorScreenState();
}

class _ProfileSelectorScreenState extends State<ProfileSelectorScreen> {
  final VoiceService _voice = VoiceService();
  final db = DatabaseService();

  @override
  void initState() {
    super.initState();
    _voice.initTTS(); // Warm up the AI voice engine
  }

  // --- LOGIC: WHEN A CHILD IS SELECTED ---
  void _onChildSelected(ChildProfile child) async {
    // 1. Persist Session (Remember this child next time the app opens)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activeChildId', child.id);

    // 2. AI VOICE GREETING (Multilingual & Personalized)
    String greet;
    if (child.language == "Malayalam") {
      greet = "Namaskaram ${child.name}! Namukku thudangam?";
    } else if (child.language == "Hindi") {
      greet = "Namaste ${child.name}! Kya aap khelne ke liye taiyar hain?";
    } else if (child.language == "Arabic") {
      greet = "Marhaba ${child.name}! Hal anta mustaeid lil-laeib?";
    } else {
      greet = "Hi ${child.name}! Let's start our adventure!";
    }
    
    await _voice.speak(greet, child.language);

    if (!mounted) return;
    
    // 3. Navigate to the Child's Home Playroom
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (c) => ChildHomeScreen(child: child))
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 50),
            const Text(
              "Who is playing?", 
              style: TextStyle(
                fontSize: 32, 
                fontWeight: FontWeight.bold, 
                color: AppColors.textDark,
                letterSpacing: -1
              )
            ),
            const SizedBox(height: 10),
            const Text(
              "Pick your profile to start the adventure!", 
              style: TextStyle(color: Colors.blueGrey)
            ),
            
            Expanded(
              child: StreamBuilder<List<ChildProfile>>(
                stream: db.streamChildProfiles(user!.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final profiles = snapshot.data ?? [];

                  return GridView.builder(
                    padding: const EdgeInsets.all(30),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, 
                      mainAxisSpacing: 25, 
                      crossAxisSpacing: 25,
                      childAspectRatio: 0.85
                    ),
                    itemCount: profiles.length + 1,
                    itemBuilder: (context, i) {
                      if (i == profiles.length) return _buildAddBtn();
                      return _buildProfileCard(profiles[i]);
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

  // --- WIDGET: THE CHILD'S EMOJI BADGE CARD ---
  Widget _buildProfileCard(ChildProfile profile) {
  // CORRECT: Parsing the child-specific color and emoji from the profile object
  Color badgeColor;
  try {
    badgeColor = Color(int.parse(profile.profileColor));
  } catch (e) {
    badgeColor = AppColors.childBlue;
  }

  return GestureDetector(
    onTap: () => _onChildSelected(profile),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [BoxShadow(color: AppColors.primaryBlue.withAlpha(20), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // SIBLING IDENTITY: Unique color and unique emoji
          CircleAvatar(
            radius: 45, 
            backgroundColor: badgeColor,
            child: Text(profile.profileEmoji, style: const TextStyle(fontSize: 45)),
          ),
          const SizedBox(height: 15),
          Text(profile.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textDark)),
          const SizedBox(height: 4),
          Text(profile.language, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    ),
  );
}
  // --- WIDGET: ADD NEW CHILD BUTTON ---
  Widget _buildAddBtn() => GestureDetector(
    onTap: () => Navigator.pushNamed(context, '/add_child'),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200, width: 2), 
        borderRadius: BorderRadius.circular(35)
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_circle_outline_rounded, size: 50, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            "Add Child", 
            style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)
          ),
        ],
      ),
    ),
  );
}