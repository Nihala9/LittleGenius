import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/child_model.dart';
import '../../services/database_service.dart';
import '../../utils/app_colors.dart';

class ProfileWizardScreen extends StatefulWidget {
  final ChildProfile? existingChild;
  const ProfileWizardScreen({super.key, this.existingChild});

  @override
  State<ProfileWizardScreen> createState() => _ProfileWizardScreenState();
}

class _ProfileWizardScreenState extends State<ProfileWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0; 
  final _db = DatabaseService();

  final _nameController = TextEditingController();
  int _selectedAge = 3;
  String _selectedLanguage = 'English';
  
  // Badge Identity
  String _selectedEmoji = "⭐";
  Color _selectedColor = AppColors.childBlue;
  
  final List<String> _emojis = ["⭐", "🚀", "🎨", "⚽", "🦄", "🌈", "🍦", "🦁"];
  final List<Color> _colors = [AppColors.childBlue, AppColors.childPink, AppColors.childOrange, AppColors.childGreen, Colors.purpleAccent];

  // AI Buddy Registry
  int _selectedBuddyIndex = 0;
  final List<Map<String, String>> _buddies = [
    {'id': 'buddy_robo', 'name': 'Robo-B1', 'asset': 'assets/images/buddies/robo.png', 'tone': 'Logical'},
    {'id': 'buddy_girl', 'name': 'Eva', 'asset': 'assets/images/buddies/girl.png', 'tone': 'Curious'},
    {'id': 'buddy_boy', 'name': 'Sam', 'asset': 'assets/images/buddies/boy.png', 'tone': 'Energetic'},
    {'id': 'buddy_cat', 'name': 'Smarty Cat', 'asset': 'assets/images/buddies/cat.png', 'tone': 'Helpful'},
    {'id': 'buddy_lion', 'name': 'Leo', 'asset': 'assets/images/buddies/lion.png', 'tone': 'Brave'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingChild != null) {
      _nameController.text = widget.existingChild!.name;
      _selectedAge = widget.existingChild!.age;
      _selectedLanguage = widget.existingChild!.language;
      _selectedEmoji = widget.existingChild!.toMap()['profileEmoji'] ?? "⭐";
      _selectedColor = Color(int.parse(widget.existingChild!.toMap()['profileColor'] ?? "0xFF80B3FF"));
      _selectedBuddyIndex = _buddies.indexWhere((b) => b['id'] == widget.existingChild!.buddyType);
      if (_selectedBuddyIndex == -1) _selectedBuddyIndex = 0;
    }
  }

  void _onNext() {
    if (_currentStep < 3) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
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
      'age': _selectedAge,
      'language': _selectedLanguage,
      'buddyType': _buddies[_selectedBuddyIndex]['id'],
      'avatarUrl': _buddies[_selectedBuddyIndex]['asset'], 
      'profileEmoji': _selectedEmoji,
      'profileColor': '0x${_selectedColor.value.toRadixString(16).toUpperCase()}',
    };

    if (widget.existingChild == null) {
      data.addAll({'preferredMode': 'Tracing', 'totalStars': 0, 'masteryScores': {}, 'createdAt': DateTime.now(), 'dailyLimit': 30});
      await _db.updateChildProfile(user.uid, "new", data);
    } else {
      await _db.updateChildProfile(user.uid, widget.existingChild!.id, data);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(elevation: 0, backgroundColor: Colors.white, title: _buildStepper(), centerTitle: true),
      body: Column(
        children: [
          Expanded(child: PageView(controller: _pageController, physics: const NeverScrollableScrollPhysics(), children: [_stepInfo(), _stepBadge(), _stepBuddy(), _stepLang()])),
          _buildFooterButton(),
        ],
      ),
    );
  }

  Widget _buildStepper() => Row(mainAxisSize: MainAxisSize.min, children: List.generate(4, (i) => Row(children: [
    CircleAvatar(radius: 12, backgroundColor: i < _currentStep ? AppColors.teal : (i == _currentStep ? AppColors.oceanBlue : Colors.grey.shade300), child: i < _currentStep ? const Icon(Icons.check, size: 14, color: Colors.white) : Text("${i+1}", style: const TextStyle(fontSize: 10, color: Colors.white))),
    if (i < 3) Container(width: 20, height: 2, color: AppColors.lavender)
  ])));

  Widget _stepInfo() => Container(color: AppColors.childBlue.withAlpha(20), padding: const EdgeInsets.all(30), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Text("What is your name?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.oceanBlue)),
    const SizedBox(height: 40),
    TextField(controller: _nameController, textAlign: TextAlign.center, decoration: InputDecoration(hintText: "Enter Name", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none))),
    const SizedBox(height: 30),
    const Text("How old are you?", style: TextStyle(fontWeight: FontWeight.bold)),
    const SizedBox(height: 15),
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [2,3,4,5,6,7].map<Widget>((age) => ChoiceChip(label: Text("$age"), selected: _selectedAge == age, onSelected: (v) => setState(() => _selectedAge = age), selectedColor: AppColors.oceanBlue, labelStyle: TextStyle(color: _selectedAge == age ? Colors.white : Colors.black))).toList()),
  ]));

  Widget _stepBadge() => Container(color: AppColors.childYellow.withAlpha(30), padding: const EdgeInsets.all(30), child: Column(children: [
    const Text("Create your Identity Badge!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.oceanBlue)),
    const SizedBox(height: 30),
    CircleAvatar(radius: 60, backgroundColor: _selectedColor, child: Text(_selectedEmoji, style: const TextStyle(fontSize: 50))),
    const SizedBox(height: 30),
    const Text("Pick an Emoji:"),
    Wrap(spacing: 10, children: _emojis.map<Widget>((e) => GestureDetector(onTap: () => setState(() => _selectedEmoji = e), child: CircleAvatar(backgroundColor: _selectedEmoji == e ? Colors.white : Colors.transparent, child: Text(e, style: const TextStyle(fontSize: 20))))).toList()),
    const SizedBox(height: 30),
    const Text("Pick a Color:"),
    Wrap(spacing: 15, children: _colors.map<Widget>((c) => GestureDetector(onTap: () => setState(() => _selectedColor = c), child: CircleAvatar(backgroundColor: c, radius: 18, child: _selectedColor == c ? const Icon(Icons.check, color: Colors.white, size: 16) : null))).toList()),
  ]));

  Widget _stepBuddy() => Container(color: AppColors.childPink.withAlpha(20), child: Column(children: [
    const SizedBox(height: 10),
    const Text("Pick an AI Tutor!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.oceanBlue)),
    const Spacer(),
    Image.asset(_buddies[_selectedBuddyIndex]['asset']!, height: 160),
    const SizedBox(height: 10),
    Text(_buddies[_selectedBuddyIndex]['name']!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
    const Spacer(),
    SizedBox(height: 80, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), itemCount: _buddies.length, itemBuilder: (context, index) => GestureDetector(onTap: () => setState(() => _selectedBuddyIndex = index), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: CircleAvatar(radius: 30, backgroundColor: Colors.white, backgroundImage: AssetImage(_buddies[index]['asset']!), child: index == _selectedBuddyIndex ? Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.oceanBlue, width: 3))) : null))))),
    const SizedBox(height: 30),
  ]));

  Widget _stepLang() => Container(color: AppColors.childGreen.withAlpha(20), padding: const EdgeInsets.all(30), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text("Language Settings", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.oceanBlue)),
    const SizedBox(height: 40),
    ...['English', 'Malayalam', 'Hindi', 'Arabic'].map((lang) => Card(margin: const EdgeInsets.only(bottom: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 0, child: RadioListTile(title: Text(lang, style: const TextStyle(fontWeight: FontWeight.bold)), value: lang, groupValue: _selectedLanguage, activeColor: AppColors.oceanBlue, onChanged: (v) => setState(() => _selectedLanguage = v.toString()))))
  ]));

  Widget _buildFooterButton() => Padding(padding: const EdgeInsets.all(25), child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.oceanBlue, minimumSize: const Size(double.infinity, 65), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), onPressed: _onNext, child: Text(_currentStep == 3 ? "Finish Setup" : "Continue", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))));
}