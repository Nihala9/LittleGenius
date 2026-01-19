import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/child_profile.dart';
import '../../services/database_service.dart';

class AddChildWizard extends StatefulWidget {
  final ChildProfile? existingChild;
  const AddChildWizard({super.key, this.existingChild});

  @override
  State<AddChildWizard> createState() => _AddChildWizardState();
}

class _AddChildWizardState extends State<AddChildWizard> {
  int _currentStep = 0;
  bool _isSaving = false;

  late TextEditingController _nameController;
  late double _selectedAge;
  late String _selectedAvatar;
  late String _selectedLanguage;
  late double _timeLimit;

  // Aesthetic Palette
  final Color geniusPurple = const Color(0xFF818CF8);
  final Color activeMint = const Color(0xFF34D399);

  final List<Map<String, String>> _buddies = [
    {"name": "Lion", "emoji": "🦁"},
    {"name": "Owl", "emoji": "🦉"},
    {"name": "Cat", "emoji": "🐱"},
    {"name": "Rabbit", "emoji": "🐰"},
    {"name": "Hoopoe", "emoji": "🐦"},
  ];

  final List<Map<String, String>> _languages = [
    {"name": "English (US)", "code": "en-US"},
    {"name": "മലയാളം (Malayalam)", "code": "ml-IN"},
    {"name": "हिन्दी (Hindi)", "code": "hi-IN"},
    {"name": "Spanish", "code": "es-ES"},
  ];

  @override
  void initState() {
    super.initState();
    final child = widget.existingChild;
    _nameController = TextEditingController(text: child?.name ?? "");
    _selectedAge = (child?.age ?? 4).toDouble();
    _selectedAvatar = child?.avatar ?? "🦁";
    _selectedLanguage = child?.language ?? 'en-US';
    _timeLimit = (child?.dailyLimit ?? 30).toDouble();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_nameController.text.isEmpty) return;
    setState(() => _isSaving = true);
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final data = ChildProfile(
      id: widget.existingChild?.id ?? '',
      parentId: user.uid,
      name: _nameController.text.trim(),
      age: _selectedAge.toInt(),
      avatar: _selectedAvatar,
      language: _selectedLanguage,
      dailyLimit: _timeLimit.toInt(),
      usageToday: widget.existingChild?.usageToday ?? 0,
      preferredMode: widget.existingChild?.preferredMode ?? 'Visual',
      totalStars: widget.existingChild?.totalStars ?? 0,
      masteryScores: widget.existingChild?.masteryScores ?? {},
    );

    // FIXED: Using DatabaseService directly to keep this file clean of Firestore imports
    if (widget.existingChild == null) {
      await DatabaseService().addChildProfile(data);
    } else {
      await DatabaseService().updateChildProfile(data);
    }
    
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. BLURRED PASTEL BACKGROUND
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE0E7FF), Color(0xFFFFF7ED), Color(0xFFECFDF5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildStepper(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _isSaving 
                      ? const Center(child: CircularProgressIndicator()) 
                      : _buildCurrentStepContent(),
                  ),
                ),
                _buildFooterButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 40),
      child: Row(
        children: List.generate(3, (i) => Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: _currentStep >= i ? geniusPurple : Colors.black12,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        )),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    if (_currentStep == 0) return _stepIdentity();
    if (_currentStep == 1) return _stepVoiceSelection();
    return _stepWellness();
  }

  Widget _stepIdentity() {
    return Column(
      children: [
        Text("Who is the new", style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w400)),
        Text("Explorer?", style: GoogleFonts.inter(fontSize: 34, fontWeight: FontWeight.w900, color: geniusPurple)),
        const SizedBox(height: 40),
        
        _glassBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("CHILD'S NAME", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45)),
              TextField(
                controller: _nameController,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(hintText: "e.g. Leo", border: InputBorder.none),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
        const Align(alignment: Alignment.centerLeft, child: Text("Pick a Friend", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
        const SizedBox(height: 16),
        
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _buddies.length,
            itemBuilder: (context, i) {
              bool isSel = _selectedAvatar == _buddies[i]['emoji'];
              return GestureDetector(
                onTap: () => setState(() => _selectedAvatar = _buddies[i]['emoji']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(right: 15),
                  width: 90,
                  decoration: BoxDecoration(
                    color: isSel ? Colors.white : Colors.white24,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isSel ? geniusPurple : Colors.white.withOpacity(0.5), width: 2.5),
                  ),
                  child: Center(child: Text(_buddies[i]['emoji']!, style: const TextStyle(fontSize: 45))),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _stepVoiceSelection() {
    return Column(
      children: [
        Text("Choose My", style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w400)),
        Text("Native Voice", style: GoogleFonts.inter(fontSize: 34, fontWeight: FontWeight.w900, color: activeMint)),
        const SizedBox(height: 40),
        _glassBox(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLanguage,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: activeMint),
              items: _languages.map((l) => DropdownMenuItem(value: l['code'], child: Text(l['name']!, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
              onChanged: (v) => setState(() => _selectedLanguage = v!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepWellness() {
    return Column(
      children: [
        Text("Setting the", style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w400)),
        Text("Guardrails", style: GoogleFonts.inter(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.orange)),
        const SizedBox(height: 40),
        _glassBox(
          child: Column(
            children: [
              Text("Daily Play Limit: ${_timeLimit.toInt()} min", style: const TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                value: _timeLimit, min: 15, max: 120, divisions: 7,
                activeColor: geniusPurple,
                onChanged: (v) => setState(() => _timeLimit = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooterButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(colors: [geniusPurple, geniusPurple.withOpacity(0.8)]),
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent, 
            shadowColor: Colors.transparent,
            minimumSize: const Size(double.infinity, 65),
          ),
          onPressed: () => _currentStep < 2 ? setState(() => _currentStep++) : _saveProfile(),
          child: Text(_currentStep == 2 ? "START LEARNING 🚀" : "CONTINUE", 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }

  Widget _glassBox({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }
}