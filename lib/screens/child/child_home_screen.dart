import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart'; 
import '../../models/child_model.dart';
import '../../models/story_model.dart';
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
import 'stories/story_library_screen.dart';

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
  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();
    _startUsageTracking();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  void _startUsageTracking() {
    _db.updateUsageHeartbeat(widget.child.id);
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && mounted) {
        _db.getLatestChildProfile(user.uid, widget.child.id).then((profile) {
          if (profile.minutesSpentToday < profile.dailyLimit) {
            _db.updateUsageHeartbeat(widget.child.id);
          }
        });
      }
    });
  }

  // --- 1. LOCALIZED TIME-BASED GREETING ---
  String _getTimeBasedGreeting(String lang) {
    var hour = DateTime.now().hour;
    if (lang == "Arabic") {
      if (hour < 12) return "صباح الخير!"; // Good Morning
      if (hour < 17) return "طاب يومك!";   // Good Afternoon
      if (hour < 21) return "مساء الخير!"; // Good Evening
      return "تصبح على خير!";              // Good Night
    } else if (lang == "Malayalam") {
      if (hour < 12) return "സുപ്രഭാതം!";
      if (hour < 17) return "നമസ്കാരം!";
      if (hour < 21) return "ശുഭസന്ധ്യ!";
      return "ശുഭരാത്രി!";
    } else if (lang == "Hindi") {
      if (hour < 12) return "सुप्रभात!";
      if (hour < 17) return "नमस्ते!";
      if (hour < 21) return "शुभ संध्या!";
      return "शुभ रात्रि!";
    }
    // Default English
    if (hour < 12) return "Good Morning!";
    if (hour < 17) return "Good Afternoon!";
    if (hour < 21) return "Good Evening!";
    return "Good Night!";
  }

  // --- 2. SHUFFLING PARENT LOCK (LOCALIZED) ---
  void _openParentLock(ChildProfile liveChild) {
    final ctrl = TextEditingController();
    final Random rng = Random();
    int num1 = rng.nextInt(20) + 10;
    int num2 = rng.nextInt(15) + 5;
    int correctAnswer = num1 + num2;

    bool isAr = liveChild.language == "Arabic";

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Column(
          children: [
            const Icon(Icons.lock_person_rounded, color: AppColors.ultraViolet, size: 40),
            const SizedBox(height: 10),
            Text(isAr ? "للآباء فقط" : "Parents Only", textAlign: TextAlign.center, 
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.ultraViolet)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isAr ? "قم بحل المسألة للدخول إلى الإعدادات:" : "Solve this to enter settings:", textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Text("$num1 + $num2 = ?", 
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.childBlue)),
            const SizedBox(height: 15),
            TextField(
              controller: ctrl, 
              keyboardType: TextInputType.number, 
              autofocus: true, 
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: isAr ? "الإجابة" : "Answer",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ultraViolet, 
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12)
              ),
              onPressed: () {
                if (ctrl.text == correctAnswer.toString()) {
                  Navigator.pop(c);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => ParentDashboard(specificChild: liveChild)
                  ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isAr ? "إجابة خاطئة! حاول مرة أخرى." : "Wrong answer! Try again."), duration: const Duration(seconds: 1))
                  );
                  Navigator.pop(c);
                }
              }, 
              child: Text(isAr ? "فتح الإعدادات" : "Unlock Dashboard", style: const TextStyle(color: Colors.white))
            ),
          ),
          const SizedBox(height: 10),
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
        bool isLocked = liveChild.minutesSpentToday >= liveChild.dailyLimit;

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
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
              extendBody: true,
              bottomNavigationBar: _buildMagicNav(liveChild),
            ),
            if (isLocked) Positioned.fill(
              child: SleepModeScreen(
                language: liveChild.language, 
                onUnlock: () => _openParentLock(liveChild)
              ),
            ),
          ],
        );
      },
    );
  }

  // --- UI: MAGIC NAVIGATION BAR (LOCALIZED) ---
  Widget _buildMagicNav(ChildProfile liveChild) {
    String lang = liveChild.language;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: Container(
        height: 75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: AppColors.childBlue.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _magicNavItem(0, Icons.home_rounded, lang == "Arabic" ? "الرئيسية" : "Home", liveChild),
            _magicNavItem(1, Icons.star_rounded, lang == "Arabic" ? "الأوسمة" : "Badges", liveChild),
            _magicNavItem(2, Icons.lock_rounded, lang == "Arabic" ? "الآباء" : "Parents", liveChild),
          ],
        ),
      ),
    );
  }

  Widget _magicNavItem(int index, IconData icon, String label, ChildProfile liveChild) {
    bool isActive = _bottomNavIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact(); 
        if (index == 1) {
          Navigator.push(context, MaterialPageRoute(builder: (c) => BadgeGalleryScreen(child: liveChild)));
        } else if (index == 2) {
          _openParentLock(liveChild);
        } else {
          setState(() => _bottomNavIndex = index);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: isActive ? BoxDecoration(
          color: AppColors.childBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ) : const BoxDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isActive 
              ? Bounce(duration: const Duration(milliseconds: 500), child: Icon(icon, color: AppColors.childBlue, size: 28))
              : Icon(icon, color: Colors.grey.shade400, size: 26),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(
              fontSize: 10, 
              fontWeight: FontWeight.bold,
              color: isActive ? AppColors.childBlue : Colors.grey.shade400
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(ChildProfile liveChild) {
    int remaining = (liveChild.dailyLimit - liveChild.minutesSpentToday).clamp(0, liveChild.dailyLimit);
    String greeting = _getTimeBasedGreeting(liveChild.language);

    return Row(
      children: [
        CircleAvatar(radius: 26, backgroundImage: AssetImage(liveChild.avatarUrl)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: const TextStyle(color: Colors.grey, fontSize: 11)),
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
    String tip = "Kindness makes the world better.";
    String header = "Today's good habit";
    String listenBtn = "Listen";

    if (liveChild.language == "Malayalam") {
      tip = "ദയ ലോകത്തെ സുന്ദരമാക്കുന്നു.";
      header = "ഇന്നത്തെ നല്ല ശീലം";
      listenBtn = "കേൾക്കൂ";
    } else if (liveChild.language == "Hindi") {
      tip = "दयालुता दुनिया को बेहतर बनाती है।";
      header = "आज की अच्छी आदत";
      listenBtn = "सुनो";
    } else if (liveChild.language == "Arabic") {
      tip = "اللّطف يجعل العالم مكاناً أفضل.";
      header = "عادة اليوم الجيدة";
      listenBtn = "استمع";
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFEBF5FF), borderRadius: BorderRadius.circular(30)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(header, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("\"$tip\"", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.childNavy)),
                const SizedBox(height: 15),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _voice.speak(tip, liveChild.language),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.childBlue, shape: const StadiumBorder(), elevation: 0),
                      child: Text(listenBtn),
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
    String title = "Your Journey";
    String seeAll = "See All";
    if (liveChild.language == "Arabic") {
      title = "رحلتك";
      seeAll = "عرض الكل";
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.childNavy)),
        TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => CategorySelectorScreen(child: liveChild))),
          child: Text(seeAll, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
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
            asset != null ? Image.asset(asset, height: 75) : const Icon(Icons.auto_awesome, size: 40),
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
                  Text("Relaxing Pop", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                  Text("Release stress with bubbles", style: TextStyle(color: Colors.white70, fontSize: 11)),
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
                  Image.asset('assets/images/lion1.png', height: 80, errorBuilder: (c,e,s) => const Icon(Icons.pets, size: 40)),
                ],
              ),
            );
          },
        )
      ],
    );
  }
}