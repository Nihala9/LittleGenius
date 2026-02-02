import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math; // Required for floating math
import '../../models/child_model.dart';
import '../../services/database_service.dart';
import '../../utils/app_colors.dart';

class ProfileWizardScreen extends StatefulWidget {
  final ChildProfile? existingChild;
  const ProfileWizardScreen({super.key, this.existingChild});

  @override
  State<ProfileWizardScreen> createState() => _ProfileWizardScreenState();
}

class _ProfileWizardScreenState extends State<ProfileWizardScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0; 
  final _db = DatabaseService();
  
  // Animation for the floating bird mascot
  late AnimationController _mascotController;

  // --- DATA STATE ---
  final _nameController = TextEditingController();
  String _selectedClass = 'Pre-School';
  String _selectedLanguage = 'English';
  String _selectedIcon = 'assets/icons/profiles/p1.png';

  final List<String> _profileIcons = [
    'assets/icons/profiles/p1.png',
    'assets/icons/profiles/p2.png',
    'assets/icons/profiles/p3.png',
    'assets/icons/profiles/p4.png',
    'assets/icons/profiles/p5.png',
    'assets/icons/profiles/p6.png',
    'assets/icons/profiles/p7.png',
    'assets/icons/profiles/p8.png',
    'assets/icons/profiles/p9.png',
    'assets/icons/profiles/p10.png',
  ];

  // Specific Palette from your "Select your Class" image
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
    // Setup smooth floating animation (2 seconds up and down)
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
      backgroundColor: const Color(0xFFFDFDFF), // Clean slight-off-white
      body: Stack(
        children: [
          // --- THE AI BUDDY (JUST THE BIRD, NO BACKGROUND) ---
          Positioned(
            bottom: -10,
            right: -20,
            child: AnimatedBuilder(
              animation: _mascotController,
              builder: (context, child) {
                return Transform.translate(
                  // Vertical floating math
                  offset: Offset(0, 15 * math.sin(_mascotController.value * math.pi)),
                  child: Image.asset(
                    'assets/images/buddy.png', 
                    height: 250, 
                    fit: BoxFit.contain, // Ensures no clipping
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
      padding: const EdgeInsets.all(25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (i) => Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < _currentStep ? AppColors.teal : (i == _currentStep ? AppColors.ultraViolet : Colors.white),
              border: Border.all(color: i <= _currentStep ? Colors.transparent : Colors.grey.shade300),
            ),
            child: Center(
              child: i < _currentStep 
                ? const Icon(Icons.check, size: 18, color: Colors.white) 
                : Text("${i + 1}", style: TextStyle(color: i == _currentStep ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
            ),
          ),
          if (i < 3) Container(width: 30, height: 3, color: i < _currentStep ? AppColors.teal : Colors.grey.shade200),
        ])),
      ),
    );
  }

  // --- STEP 1: NAME ---
  Widget _stepName() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Hello! What's your", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const Text("Name", style: TextStyle(fontSize: 42, fontWeight: FontWeight.w500, color: Color.fromARGB(255, 126, 203, 234))),
        const SizedBox(height: 40),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: TextField(
            controller: _nameController,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.ultraViolet),
            decoration: InputDecoration(
              hintText: "Type name here...",
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
            ),
          ),
        ),
      ],
    ),
  );

  // --- STEP 2: CLASS GRID (MATCHING IMAGE) ---
  Widget _stepClassGrid() => Padding(
    padding: const EdgeInsets.all(25),
    child: Column(
      children: [
        const Text("Select your", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const Text("Class", style: TextStyle(fontSize: 36, fontWeight: FontWeight.w500, color: Color.fromARGB(255, 143, 211, 243))),
        const SizedBox(height: 10),
        const Text("Test your skills and learn new things!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 20),
        Expanded(
          child: GridView.builder(
            itemCount: _classes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 15, crossAxisSpacing: 15, childAspectRatio: 2.1
            ),
            itemBuilder: (c, i) {
              bool isSelected = _selectedClass == _classes[i]['name'];
              return InkWell(
                onTap: () => setState(() => _selectedClass = _classes[i]['name']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _classes[i]['color'],
                    borderRadius: BorderRadius.circular(25),
                    border: isSelected ? Border.all(color: const Color.fromARGB(255, 255, 255, 255), width: 4) : null,
                    boxShadow: [BoxShadow(color: _classes[i]['color'].withAlpha(120), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_classes[i]['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                        if (_classes[i]['icon'] != null) Icon(_classes[i]['icon'], color: Colors.white)
                        else Text(_classes[i]['val'], style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        )
      ],
    ),
  );

  // --- STEP 3: BADGE PICKER ---
  Widget _stepBadgePicker() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text("Pick your", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
      const Text("Badge", style: TextStyle(fontSize: 36, fontWeight: FontWeight.w500, color: Color.fromARGB(255, 131, 229, 248))),
      const SizedBox(height: 30),
      Wrap(
        spacing: 20, runSpacing: 20,
        children: _profileIcons.map<Widget>((path) => GestureDetector(
          onTap: () => setState(() => _selectedIcon = path),
          child: AnimatedScale(
            scale: _selectedIcon == path ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _selectedIcon == path ? AppColors.ultraViolet : Colors.white, width: 4),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 15)],
              ),
              child: CircleAvatar(radius: 40, backgroundColor: Colors.white, backgroundImage: AssetImage(path)),
            ),
          ),
        )).toList(),
      ),
    ],
  );

  // --- STEP 4: LANGUAGE ---
  Widget _stepLanguage() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 30),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Choose your", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const Text("Language", style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.amber)),
        const SizedBox(height: 30),
        ...['English', 'Malayalam', 'Hindi', 'Arabic'].map<Widget>((l) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: _selectedLanguage == l ? AppColors.ultraViolet : Colors.grey.shade200, width: 2)
          ),
          color: _selectedLanguage == l ? AppColors.ultraViolet : Colors.white,
          child: RadioListTile(
            title: Text(l, style: TextStyle(fontWeight: FontWeight.bold, color: _selectedLanguage == l ? Colors.white : AppColors.textDark)),
            value: l, groupValue: _selectedLanguage, activeColor: Colors.white,
            onChanged: (v) => setState(() => _selectedLanguage = v.toString()),
          ),
        )),
      ],
    ),
  );

  Widget _buildFooter() => Padding(
    padding: const EdgeInsets.all(30),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.ultraViolet,
        minimumSize: const Size(double.infinity, 65),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
      ),
      onPressed: _onNext,
      child: Text(_currentStep == 3 ? "Let's Play!" : "Continue", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
    ),
  );
}