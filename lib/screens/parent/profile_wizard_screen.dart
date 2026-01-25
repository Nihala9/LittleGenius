import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/child_model.dart';
import '../../services/database_service.dart';

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

  // SaaS Palette
  final Color indigo = const Color(0xFF3F51B5);
  final Color teal = const Color(0xFF00BFA5);
  final Color lavender = const Color(0xFFE8EAF6);

  final _nameController = TextEditingController();
  int _selectedAge = 3;
  String _selectedLanguage = 'English';
  int _selectedBuddyIndex = 0;

  final List<Map<String, String>> _buddies = [
    {'name': 'Robo-B1', 'style': 'bottts', 'tone': 'Logical & Patient'},
    {'name': 'Wise Owl', 'style': 'adventurer', 'tone': 'Calm & Wise'},
    {'name': 'Leo-AI', 'style': 'lorelei', 'tone': 'Fun & Energetic'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingChild != null) {
      _nameController.text = widget.existingChild!.name;
      _selectedAge = widget.existingChild!.age;
      _selectedLanguage = widget.existingChild!.language;
    }
  }

  String _getAvatar(String style, String seed) => "https://api.dicebear.com/7.x/$style/png?seed=$seed";

  void _onNext() {
    if (_currentStep < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    } else {
      _save();
    }
  }

  void _save() async {
    final user = FirebaseAuth.instance.currentUser;
    String style = _buddies[_selectedBuddyIndex]['style']!;
    Map<String, dynamic> data = {
      'name': _nameController.text.trim(),
      'age': _selectedAge,
      'language': _selectedLanguage,
      'avatarUrl': _getAvatar(style, _nameController.text),
    };

    if (widget.existingChild == null) {
      data.addAll({'preferredMode': 'Tracing', 'totalStars': 0, 'masteryScores': {}, 'createdAt': DateTime.now(), 'dailyLimit': 30});
      await _db.updateChildProfile(user!.uid, "new", data);
    } else {
      await _db.updateChildProfile(user!.uid, widget.existingChild!.id, data);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(elevation: 0, backgroundColor: Colors.white, title: _buildStepper()),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [_stepInfo(), _stepBuddy(), _stepLang()],
            ),
          ),
          _footer(),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) => Row(children: [
        CircleAvatar(radius: 12, backgroundColor: i < _currentStep ? teal : (i == _currentStep ? indigo : Colors.grey.shade300), child: Text("${i+1}", style: const TextStyle(fontSize: 10, color: Colors.white))),
        if (i < 2) Container(width: 20, height: 2, color: lavender)
      ])),
    );
  }

  Widget _stepInfo() => Padding(
    padding: const EdgeInsets.all(30),
    child: Column(children: [
      Text("The Adventure Begins", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: indigo)),
      const SizedBox(height: 40),
      TextField(controller: _nameController, decoration: InputDecoration(labelText: "Child's Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
      const SizedBox(height: 30),
      const Text("How old are they?"),
      Wrap(spacing: 10, children: [2,3,4,5,6,7].map((a) => ChoiceChip(label: Text("$a"), selected: _selectedAge == a, onSelected: (v) => setState(() => _selectedAge = a))).toList())
    ]),
  );

  Widget _stepBuddy() => Column(children: [
    Text("Choose an AI Buddy", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: indigo)),
    const SizedBox(height: 20),
    CircleAvatar(radius: 80, backgroundColor: lavender, backgroundImage: NetworkImage(_getAvatar(_buddies[_selectedBuddyIndex]['style']!, _nameController.text))),
    const SizedBox(height: 20),
    Text(_buddies[_selectedBuddyIndex]['name']!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    const Spacer(),
    SizedBox(height: 100, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _buddies.length, itemBuilder: (c, i) => GestureDetector(onTap: () => setState(() => _selectedBuddyIndex = i), child: Padding(padding: const EdgeInsets.all(8.0), child: CircleAvatar(radius: 30, backgroundImage: NetworkImage(_getAvatar(_buddies[i]['style']!, _nameController.text))))))),
  ]);

  Widget _stepLang() => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Text("Final Setting", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    ...['English', 'Malayalam', 'Hindi'].map((l) => RadioListTile(title: Text(l), value: l, groupValue: _selectedLanguage, onChanged: (v) => setState(() => _selectedLanguage = v!)))
  ]);

  Widget _footer() => Padding(padding: const EdgeInsets.all(20), child: ElevatedButton(style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60), backgroundColor: indigo), onPressed: _onNext, child: Text(_currentStep == 2 ? "Finish" : "Next", style: const TextStyle(color: Colors.white))));
}