import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/child_model.dart';
import '../../utils/app_colors.dart';
import '../../services/database_service.dart';
import '../../services/voice_service.dart';
import '../../widgets/interactive_buddy.dart'; // Import the buddy widget
import '../parent/parent_dashboard.dart';
import 'learning_map.dart';
import 'badge_gallery.dart';
import 'sleep_mode_screen.dart';

class ChildHomeScreen extends StatefulWidget {
  final ChildProfile child;
  const ChildHomeScreen({super.key, required this.child});

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen> {
  int _bottomNavIndex = 0;
  final VoiceService _voice = VoiceService();
  final DatabaseService _db = DatabaseService();
  
  late DateTime _sessionStartTime;
  int _minutesPlayed = 0;
  bool _isLocked = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
    _startSessionTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startSessionTimer() {
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !_isLocked) {
        setState(() {
          _minutesPlayed = DateTime.now().difference(_sessionStartTime).inMinutes;
        });
      }
    });
  }

  String _getTimeBasedGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning!";
    if (hour < 17) return "Good Afternoon!";
    return "Good Evening!";
  }

  void _openParentLock(ChildProfile liveChild) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Parents Only", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Solve to unlock:"),
            const SizedBox(height: 10),
            const Text("15 + 7 = ?", 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.childBlue)),
            TextField(controller: ctrl, keyboardType: TextInputType.number, autofocus: true, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (ctrl.text == "22") {
                Navigator.pop(c);
                if (_isLocked) setState(() { _isLocked = false; _sessionStartTime = DateTime.now(); });
                Navigator.push(context, MaterialPageRoute(builder: (context) => ParentDashboard(specificChild: liveChild)));
              }
            }, 
            child: const Text("Unlock")
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<ChildProfile>(
      stream: _db.streamSingleChild(user!.uid, widget.child.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
        final liveChild = snapshot.data!;
        if (_minutesPlayed >= liveChild.dailyLimit) _isLocked = true;

        return Stack(
          children: [
            Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      _buildTopHeader(liveChild),
                      const SizedBox(height: 25),
                      _buildTodayHabitCard(liveChild),
                      const SizedBox(height: 30),
                      
                      const Text("Your Journey", 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.childNavy)),
                      const SizedBox(height: 15),

                      _buildCategoryRow(liveChild),
                      
                      const SizedBox(height: 30),
                      _buildRewardSection(liveChild),
                      const SizedBox(height: 30),
                      _buildStoryCard(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: _buildBottomNav(liveChild),
            ),
            if (_isLocked) SleepModeScreen(language: liveChild.language, onUnlock: () => _openParentLock(liveChild)),
          ],
        );
      },
    );
  }

  Widget _buildTopHeader(ChildProfile liveChild) {
    int remaining = liveChild.dailyLimit - _minutesPlayed;
    return Row(
      children: [
        CircleAvatar(radius: 26, backgroundColor: AppColors.lavender, backgroundImage: AssetImage(liveChild.avatarUrl)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getTimeBasedGreeting(), style: const TextStyle(color: Colors.grey, fontSize: 13)),
            Text(liveChild.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.childNavy)),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15)),
          child: Row(
            children: [
              Icon(Icons.timer_outlined, size: 14, color: remaining < 5 ? Colors.red : AppColors.childBlue),
              const SizedBox(width: 4),
              Text("${remaining}m", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: remaining < 5 ? Colors.red : AppColors.childBlue)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: AppColors.childBlue, borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              const Icon(Icons.stars_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 4),
              Text("${liveChild.totalStars}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTodayHabitCard(ChildProfile liveChild) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.childBlue.withAlpha(20), borderRadius: BorderRadius.circular(30)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("BUDDY TIP", style: TextStyle(color: Colors.blueGrey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                const Text("\"Kindness makes you a superstar!\"", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.childNavy)),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () => _voice.speak("Always be kind to everyone!", liveChild.language),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.childBlue, shape: const StadiumBorder()),
                  child: const Text("Listen"),
                ),
              ],
            ),
          ),
          // Buddy is now interactive (tap to giggle/talk)
          InteractiveBuddy(height: 110, language: liveChild.language), 
        ],
      ),
    );
  }

  Widget _buildCategoryRow(ChildProfile liveChild) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.streamCategories(),
      builder: (context, catSnapshot) {
        if (!catSnapshot.hasData) return const SizedBox(height: 140, child: Center(child: CircularProgressIndicator()));
        final categories = catSnapshot.data ?? [];
        return SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return _buildCategoryCard(cat['name'] ?? "Lesson", cat['imagePath'] ?? 'assets/icons/category/c1.png', liveChild);
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryCard(String title, String asset, ChildProfile liveChild) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => LearningMapScreen(child: liveChild, category: title))),
      child: Container(
        width: 110, margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(asset, height: 100, errorBuilder: (c, e, s) => const Icon(Icons.category, size: 40)), 
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.childNavy)),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardSection(ChildProfile liveChild) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => BadgeGalleryScreen(child: liveChild))),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFFFFEFEF), borderRadius: BorderRadius.circular(30)),
        child: Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: Colors.orange, size: 40),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Badge Gallery", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.childNavy)),
                Text("You have ${liveChild.badges.length} stickers!", style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Bedtime Stories", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(color: const Color(0xFFFEF9E7), borderRadius: BorderRadius.circular(25)),
          child: const ListTile(
            leading: Icon(Icons.menu_book, color: Colors.orange),
            title: Text("The Happy Lion", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Audio Story • 5 min"),
            trailing: Icon(Icons.play_circle_fill, color: Colors.orange, size: 30),
          ),
        )
      ],
    );
  }

  Widget _buildBottomNav(ChildProfile liveChild) {
    return Container(
      decoration: const BoxDecoration(boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BottomNavigationBar(
          currentIndex: _bottomNavIndex,
          selectedItemColor: AppColors.childBlue,
          onTap: (i) {
            if (i == 1) Navigator.push(context, MaterialPageRoute(builder: (c) => BadgeGalleryScreen(child: liveChild)));
            else if (i == 2) _openParentLock(liveChild);
            else setState(() => _bottomNavIndex = i);
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: "Badges"),
            BottomNavigationBarItem(icon: Icon(Icons.lock_person), label: "Parents"),
          ],
        ),
      ),
    );
  }
}