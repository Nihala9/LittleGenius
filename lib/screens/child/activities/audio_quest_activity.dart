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

  const AudioQuestActivity({super.key, required this.concept, required this.language, required this.onComplete});

  @override
  State<AudioQuestActivity> createState() => _AudioQuestActivityState();
}

class _AudioQuestActivityState extends State<AudioQuestActivity> {
  final VoiceService _voice = VoiceService();
  late List<String> options;
  bool hasSpoken = false;

  @override
  void initState() {
    super.initState();
    // Create a list with 1 correct answer and 3 distractors
    options = GameAssets.getDistractors(widget.concept.name);
    options.add(widget.concept.name);
    options.shuffle();
    
    // Prompt the child after a short delay
    Future.delayed(const Duration(milliseconds: 500), _askQuestion);
  }

  void _askQuestion() {
    String prompt = widget.language == "Malayalam" 
      ? "Ithil ${widget.concept.name} evideyanu?" 
      : "Can you find the ${widget.concept.name}?";
    _voice.speak(prompt, widget.language);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 1. THE AUDITORY BUTTON
        Pulse(
          infinite: true,
          child: GestureDetector(
            onTap: _askQuestion,
            child: const CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.childOrange,
              child: Icon(Icons.volume_up_rounded, size: 40, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text("Listen & Tap!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 40),

        // 2. GRID OF OPTIONS
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: options.map((opt) {
            final data = GameAssets.getConceptData(opt);
            return GestureDetector(
              onTap: () {
                if (opt == widget.concept.name) {
                  widget.onComplete(true);
                } else {
                  _voice.speak("Not that one, try again!", widget.language);
                  widget.onComplete(false);
                }
              },
              child: ZoomIn(
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: AppColors.childBlue.withOpacity(0.3), width: 3),
                  ),
                  child: Center(child: Text(data['item'], style: const TextStyle(fontSize: 45))),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}