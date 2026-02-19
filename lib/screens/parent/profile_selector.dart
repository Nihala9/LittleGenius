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
  final VoiceService _voice = VoiceService();
  final db = DatabaseService();

  @override
  void initState() {
    super.initState();
    _voice.initTTS(); 
  }

  void _onChildSelected(ChildProfile child) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activeChildId', child.id);

    // FIX: Generate the greeting based on the specific language
    String greet = _getLocalizedGreeting(child.name, child.language);
    
    // Speak using the VoiceService (it will detect language automatically)
    await _voice.speak(greet, child.language);

    if (!mounted) return;
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (c) => ChildHomeScreen(child: child))
    );
  }

  // --- HELPER: Returns native greeting text ---
  String _getLocalizedGreeting(String name, String language) {
    switch (language) {
      case "Malayalam":
        return "Namaskaram $name! Namukku thudangam?"; 
      case "Hindi":
        return "Namaste $name! Chalo khelte hain!"; 
      case "Arabic":
        return "Marhaban $name! Hayya bina nal'ab!"; 
      case "Spanish":
        return "¡Hola $name! ¿Listo para jugar?"; 
      case "French":
        return "Bonjour $name! Prêt à jouer?"; 
      default:
        return "Hi $name! Ready for an adventure?";
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/landing');
            },
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Text("Who is playing?", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 10),
            const Text("Select a profile to start!", style: TextStyle(color: Colors.blueGrey)),
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
                      crossAxisCount: 2, mainAxisSpacing: 25, crossAxisSpacing: 25, childAspectRatio: 0.85
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

  Widget _buildProfileCard(ChildProfile profile) {
    return GestureDetector(
      onTap: () => _onChildSelected(profile),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(35), 
          boxShadow: [BoxShadow(color: AppColors.primaryBlue.withAlpha(20), blurRadius: 20)]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 45, 
              backgroundColor: AppColors.lavender,
              backgroundImage: AssetImage(profile.avatarUrl), 
            ),
            const SizedBox(height: 15),
            Text(profile.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text(profile.childClass, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddBtn() => GestureDetector(
    onTap: () => Navigator.push(
      context, 
      MaterialPageRoute(builder: (c) => const ProfileWizardScreen())
    ),
    child: Container(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200, width: 2), borderRadius: BorderRadius.circular(35)),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_circle_outline, size: 50, color: Colors.grey), 
          Text("Add Child", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
        ],
      ),
    ),
  );
}