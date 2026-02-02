import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/voice_service.dart';

class InteractiveBuddy extends StatefulWidget {
  final double height;
  final String language;

  const InteractiveBuddy({super.key, this.height = 120, required this.language});

  @override
  State<InteractiveBuddy> createState() => _InteractiveBuddyState();
}

class _InteractiveBuddyState extends State<InteractiveBuddy> {
  final VoiceService _voice = VoiceService();
  bool _isHappy = false;

  final List<String> _enPhrases = ["He-he! That tickles!", "Boing! I love jumping!", "Yay! High five!", "I'm your best buddy!"];
  final List<String> _mlPhrases = ["He-he! Enne thottu!", "Enikku rasamaayi!", "Nammal kootukaaraanu!", "Nannayi thottu!"];

  void _handleTap() async {
    if (_isHappy) return; 
    setState(() => _isHappy = true);

    final phrases = widget.language == "Malayalam" ? _mlPhrases : _enPhrases;
    String randomPhrase = phrases[Random().nextInt(phrases.length)];

    await _voice.speak(randomPhrase, widget.language);
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) setState(() => _isHappy = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Lottie.asset(
        _isHappy ? 'assets/animations/buddy_wave.json' : 'assets/animations/buddy_idle.json',
        height: widget.height,
        fit: BoxFit.contain,
      ),
    );
  }
}