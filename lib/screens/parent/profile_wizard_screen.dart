import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import '../../models/child_model.dart';
import '../../services/database_service.dart';
import '../../utils/app_colors.dart';

class ProfileWizardScreen extends StatefulWidget {
  final ChildProfile? existingChild;
  const ProfileWizardScreen({super.key, this.existingChild});

  @override
  State<ProfileWizardScreen> createState() => _ProfileWizardScreenState();
}

class _ProfileWizardScreenState extends State<ProfileWizardScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0; 
  final _db = DatabaseService();
  
  late AnimationController _mascotController;

  // --- DATA STATE ---
  final _nameController = TextEditingController();
  String _selectedClass = 'Pre-School';
  String _selectedLanguage = 'English';
  String _selectedIcon = 'assets/icons/profiles/p1.png';

  final List<String> _profileIcons = [
    'assets/icons/profiles/p1.png', 'assets/icons/profiles/p2.png',
    'assets/icons/profiles/p3.png', 'assets/icons/profiles/p4.png',
    'assets/icons/profiles/p5.png', 'assets/icons/profiles/p6.png',
    'assets/icons/profiles/p7.png', 'assets/icons/profiles/p8.png',
    'assets/icons/profiles/p9.png', 'assets/icons/profiles/p10.png',
  ];

  final List<Map<String, dynamic>> _classes = [
    {'name': 'Pre-School', 'color': const Color(0xFF9173FF), 'icon': Icons.school_rounded},
    {'name': 'Class 1', 'color': const Color(0xFFFF6B9D), 'val': '1'},
    {'name': 'Class 2', 'color': const Color(0xFF7ED957), 'val': '2'},
    {'name': 'Class 3', 'color': const Color(0xFFFFBD59), 'val': '3'},
    {'name': 'Class 4', 'color': const Color(0xFF4FAAFD), 'val': '4'},
    {'name': 'Class 5', 'color': const Color(0xFF38B6FF), 'val': '5'},
    {'name': 'No School', 'color': const Color(0xFFFF914D), 'icon': Icons.star_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _mascotController = AnimationController(
      duration: const Duration(seconds: 2), 
      vsync: this
    )..repeat(reverse: true);

    if (widget.existingChild != null) {
      _nameController.text = widget.existingChild!.name;
      _selectedClass = widget.existingChild!.childClass;
      _selectedLanguage = widget.existingChild!.language;
      _selectedIcon = widget.existingChild!.avatarUrl;
    }
  }

  @override
  void dispose() {
    _mascotController.dispose();
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    // Hide keyboard automatically when moving between steps
    FocusScope.of(context).unfocus();

    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500), 
        curve: Curves.fastOutSlowIn
      );
      setState(() => _currentStep++);
    } else {
      _save();
    }
  }

  void _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _nameController.text.isEmpty) return;

    Map<String, dynamic> data = {
      'name': _nameController.text.trim(),
      'childClass': _selectedClass,
      'language': _selectedLanguage,
      'avatarUrl': _selectedIcon, 
      'buddyType': 'BirdBuddy',
      'age': 3,
    };

    if (widget.existingChild == null) {
      data.addAll({
        'preferredMode': 'Tracing', 
        'totalStars': 0, 
        'masteryScores': {}, 
        'badges': [],
        'createdAt': DateTime.now(), 
        'dailyLimit': 30
      });
      await _db.updateChildProfile(user.uid, "new", data);
    } else {
      await _db.updateChildProfile(user.uid, widget.existingChild!.id, data);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFF),
      // Prevents the background from resizing when keyboard appears
      resizeToAvoidBottomInset: false, 
      body: Stack(
        children: [
          // --- AI BUDDY BACKGROUND ---
          Positioned(
            bottom: -20,
            right: -20,
            child: AnimatedBuilder(
              animation: _mascotController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 15 * math.sin(_mascotController.value * math.pi)),
                  child: Opacity(
                    opacity: 0.6, // Faded so it doesn't distract from forms
                    child: Image.asset('assets/images/buddy.png', height: 200),
                  ),
                );
              },
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeaderStepper(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _stepName(),
                      _stepClassGrid(),
                      _stepBadgePicker(),
                      _stepLanguage(),
                    ],
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStepper() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (i) => Row(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < _currentStep ? AppColors.childGreen : (i == _currentStep ? AppColors.ultraViolet : Colors.white),
              border: Border.all(color: i <= _currentStep ? Colors.transparent : Colors.grey.shade300),
            ),
            child: Center(
              child: i < _currentStep 
                ? const Icon(Icons.check, size: 16, color: Colors.white) 
                : Text("${i + 1}", style: TextStyle(color: i == _currentStep ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
          if (i < 3) Container(width: 20, height: 2, color: i < _currentStep ? AppColors.childGreen : Colors.grey.shade200),
        ])),
      ),
    );
  }

  // --- STEP 1: NAME ---
  Widget _stepName() => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 40),
    child: Column(
      children: [
        const SizedBox(height: 50),
        const Text("Hello! What's your", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const Text("Name?", style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.lightBlue)),
        const SizedBox(height: 40),
        TextField(
          controller: _nameController,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: "Type here...",
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide(color: Colors.grey.shade200)),
          ),
        ),
      ],
    ),
  );

  // --- STEP 2: CLASS GRID ---
  Widget _stepClassGrid() => SingleChildScrollView(
    padding: const EdgeInsets.all(25),
    child: Column(
      children: [
        const Text("Select your", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const Text("Class", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.lightBlue)),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true, // IMPORTANT: Allows Grid to work inside SingleChildScrollView
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _classes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 15, crossAxisSpacing: 15, childAspectRatio: 2.2
          ),
          itemBuilder: (c, i) {
            bool isSelected = _selectedClass == _classes[i]['name'];
            return InkWell(
              onTap: () => setState(() => _selectedClass = _classes[i]['name']),
              child: Container(
                decoration: BoxDecoration(
                  color: _classes[i]['color'],
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_classes[i]['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 5),
                    if (_classes[i]['icon'] != null) Icon(_classes[i]['icon'], color: Colors.white, size: 18)
                    else Text(_classes[i]['val'], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          },
        )
      ],
    ),
  );

  // --- STEP 3: BADGE PICKER ---
  Widget _stepBadgePicker() => SingleChildScrollView(
    padding: const EdgeInsets.all(25),
    child: Column(
      children: [
        const Text("Pick your", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const Text("Badge", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.lightBlue)),
        const SizedBox(height: 20),
        Wrap(
          spacing: 15, runSpacing: 15,
          children: _profileIcons.map((path) => GestureDetector(
            onTap: () => setState(() => _selectedIcon = path),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _selectedIcon == path ? AppColors.ultraViolet : Colors.transparent, width: 3),
              ),
              child: CircleAvatar(radius: 35, backgroundColor: Colors.white, backgroundImage: AssetImage(path)),
            ),
          )).toList(),
        ),
      ],
    ),
  );

  // --- STEP 4: LANGUAGE ---
  Widget _stepLanguage() => SingleChildScrollView(
    padding: const EdgeInsets.all(25),
    child: Column(
      children: [
        const Text("Choose your", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const Text("Language", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.amber)),
        const SizedBox(height: 20),
        ...['English', 'Malayalam', 'Hindi', 'Arabic'].map((l) => Card(
          child: RadioListTile(
            title: Text(l, style: const TextStyle(fontWeight: FontWeight.bold)),
            value: l, groupValue: _selectedLanguage,
            onChanged: (v) => setState(() => _selectedLanguage = v.toString()),
          ),
        )),
      ],
    ),
  );

  Widget _buildFooter() => Padding(
    padding: const EdgeInsets.all(20),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.ultraViolet,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: _onNext,
      child: Text(_currentStep == 3 ? "Let's Play!" : "Continue", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    ),
  );
}