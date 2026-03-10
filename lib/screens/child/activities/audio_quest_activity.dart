import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/game_assets.dart';
import '../../../models/concept_model.dart';
import '../../../services/voice_service.dart';

class AudioQuestActivity extends StatefulWidget {
  final Concept concept;
  final String language;
  final Function(bool) onComplete;

  const AudioQuestActivity({
    super.key, 
    required this.concept, 
    required this.language, 
    required this.onComplete
  });

  @override
  State<AudioQuestActivity> createState() => _AudioQuestActivityState();
}

class _AudioQuestActivityState extends State<AudioQuestActivity> {
  final VoiceService _voice = VoiceService();
  late List<String> _options;
  String? _selectedOption;
  bool _isLocked = false;

 @override
 void initState() {
   super.initState();
   // Pass BOTH the concept name and the category name
   _options = GameAssets.getDistractors(widget.concept.name, widget.concept.category);
   _options.add(widget.concept.name);
   _options.shuffle();
  
  Future.delayed(const Duration(milliseconds: 800), _askQuestion);
}

  // --- NATIVE SCRIPT INSTRUCTIONS ---
  void _askQuestion() {
    String msg = "";
    if (widget.language == "Malayalam") {
      msg = "ഇതിൽ ${widget.concept.name} എവിടെയാണ്?"; 
    } else if (widget.language == "Hindi") {
      msg = "इनमें से ${widget.concept.name} कौन सा है?"; 
    } else if (widget.language == "Arabic") {
      msg = "أين هو ${widget.concept.name}؟";
    } else {
      msg = " ${widget.concept.name}?";
    }
    _voice.speak(msg, widget.language);
  }

  void _handleSelection(String opt) async {
    if (_isLocked) return;
    setState(() {
      _selectedOption = opt;
      _isLocked = true;
    });

    if (opt == widget.concept.name) {
      // Notify Container of Success
      widget.onComplete(true);
    } else {
      // Notify Container of Failure
      widget.onComplete(false);
      // Brief delay before allowing another tap
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _isLocked = false;
          _selectedOption = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. BACKGROUND DECORATIONS
        Positioned(top: 20, right: 20, child: FadeInRight(child: const Icon(Icons.wb_sunny_rounded, size: 80, color: Colors.orangeAccent))),
        Positioned(top: 100, left: -20, child: FadeInLeft(child: Icon(Icons.cloud_rounded, size: 100, color: Colors.blue.withAlpha(20)))),

        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 2. THE BIG PULSING SPEAKER
            Pulse(
              infinite: true,
              duration: const Duration(seconds: 2),
              child: GestureDetector(
                onTap: _askQuestion,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 140, height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.childOrange.withAlpha(30),
                      ),
                    ),
                    Container(
                      width: 110, height: 110,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [AppColors.childOrange, Colors.orangeAccent]),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                      ),
                      child: const Icon(Icons.volume_up_rounded, size: 60, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.language == "Malayalam" ? "ശ്രദ്ധിച്ചു കേൾക്കൂ!" : "Listen Carefully!",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.childNavy),
            ),
            const SizedBox(height: 50),

            // 3. THE CHOICE GRID
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: _options.map((opt) => _buildChoiceCard(opt)).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChoiceCard(String opt) {
    final data = GameAssets.getConceptData(opt);
    bool isSelected = _selectedOption == opt;
    bool isCorrect = isSelected && opt == widget.concept.name;

    return GestureDetector(
      onTap: () => _handleSelection(opt),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 120, height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected 
                ? (isCorrect ? AppColors.childGreen : Colors.redAccent) 
                : Colors.grey.shade100, 
            width: 4
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                ? (isCorrect ? AppColors.childGreen : Colors.redAccent).withAlpha(50)
                : Colors.black.withAlpha(10), 
              blurRadius: 15, offset: const Offset(0, 8)
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(data['item'], style: const TextStyle(fontSize: 60)),
            const SizedBox(height: 5),
            if (isSelected) 
               Icon(
                 isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded, 
                 color: isCorrect ? AppColors.childGreen : Colors.redAccent
               ),
          ],
        ),
      ),
    );
  }
}