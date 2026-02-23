import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/child_model.dart';
import '../../models/story_model.dart'; // Added
import '../../utils/app_colors.dart';
import '../../services/database_service.dart';
import '../../services/voice_service.dart';
import '../../widgets/interactive_buddy.dart'; 
import '../parent/parent_dashboard.dart';
import 'learning_map.dart';
import 'badge_gallery.dart';
import 'sleep_mode_screen.dart';
import 'category_selector_screen.dart';
import 'bubble_pop_game.dart';
import 'stories/story_player_screen.dart';
import 'stories/story_library_screen.dart'; // Added

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
              backgroundColor: const Color(0xFFF8FBFF),
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
                      _buildCategoryHeading(liveChild),
                      _buildCategoryRow(liveChild),
                      const SizedBox(height: 30),
                      _buildStressGameCard(context),
                      const SizedBox(height: 30),
                      _buildStoryCard(context),
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
        CircleAvatar(radius: 26, backgroundImage: AssetImage(liveChild.avatarUrl)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_getTimeBasedGreeting(), style: const TextStyle(color: Colors.grey, fontSize: 11)),
              Text(liveChild.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.childNavy)),
            ],
          ),
        ),
        _pill(Icons.timer_outlined, "${remaining}m", AppColors.childBlue),
        const SizedBox(width: 10),
        _pill(Icons.stars_rounded, "${liveChild.totalStars}", Colors.white, bg: AppColors.childBlue, shadow: true),
      ],
    );
  }

  Widget _pill(IconData icon, String label, Color color, {Color? bg, bool shadow = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg ?? const Color(0xFFEEF7FF), 
        borderRadius: BorderRadius.circular(20),
        boxShadow: shadow ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : null
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildTodayHabitCard(ChildProfile liveChild) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFEBF5FF), borderRadius: BorderRadius.circular(30)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Today's good habit", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("\"Kindness makes the world better.\"", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.childNavy)),
                const SizedBox(height: 15),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _voice.speak("Always be kind!", liveChild.language),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.childBlue, shape: const StadiumBorder(), elevation: 0),
                      child: const Text("Listen"),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.local_fire_department, color: Colors.orange, size: 18),
                    const Text(" 5 Days", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          InteractiveBuddy(height: 90, language: liveChild.language), 
        ],
      ),
    );
  }

  Widget _buildCategoryHeading(ChildProfile liveChild) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Your Journey", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.childNavy)),
        TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => CategorySelectorScreen(child: liveChild))),
          child: const Text("See All", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  Widget _buildCategoryRow(ChildProfile liveChild) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.streamCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 100);
        final categories = snapshot.data!;
        return SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              List<Color> borderColors = [const Color(0xFFBBDEFB), const Color(0xFFF8BBD0), const Color(0xFFFFCC80)];
              return _buildCategoryCard(cat['name'], cat['imagePath'], borderColors[index % 3], liveChild);
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryCard(String title, String? asset, Color border, ChildProfile liveChild) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => LearningMapScreen(child: liveChild, category: title))),
      child: Container(
        width: 110, margin: const EdgeInsets.only(right: 15, bottom: 5),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(25),
          border: Border.all(color: border.withOpacity(0.5), width: 2),
          boxShadow: [BoxShadow(color: border.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            asset != null ? Image.asset(asset, height: 80) : const Icon(Icons.auto_awesome, size: 40),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.childNavy)),
          ],
        ),
      ),
    );
  }

  Widget _buildStressGameCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const BubblePopGame())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFE0C3FC), Color(0xFF8EC5FC)]),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Relaxing Pop", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                  Text("Release stress with bubbles", style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: const Text("Play", style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Bedtime Stories", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.childNavy)),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const StoryLibraryScreen())),
              child: const Text("See All", style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 15),
        StreamBuilder<List<KidStory>>(
          stream: _db.streamStories(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text("More stories coming soon!");
            final latest = snapshot.data!.first;

            return Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: const Color(0xFFFFF9E5), borderRadius: BorderRadius.circular(25)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Featured Story", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text(latest.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.childNavy)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(
                            builder: (c) => StoryPlayerScreen(videoId: latest.youtubeId, title: latest.title)
                          )),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.childBlue, shape: const StadiumBorder(), elevation: 0),
                          child: const Text("Watch Now"),
                        )
                      ],
                    ),
                  ),
                  Image.asset('assets/images/lion.png', height: 80, errorBuilder: (c,e,s) => const Icon(Icons.pets, size: 40)),
                ],
              ),
            );
          },
        )
      ],
    );
  }

  Widget _buildBottomNav(ChildProfile liveChild) {
    return BottomNavigationBar(
      currentIndex: _bottomNavIndex,
      selectedItemColor: AppColors.childBlue,
      onTap: (i) {
        if (i == 1) Navigator.push(context, MaterialPageRoute(builder: (c) => BadgeGalleryScreen(child: liveChild)));
        else if (i == 2) _openParentLock(liveChild);
        else setState(() => _bottomNavIndex = i);
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.star_rounded), label: "Badges"),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profile"),
      ],
    );
  }
}