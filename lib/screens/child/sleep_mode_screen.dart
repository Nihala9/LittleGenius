import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:animate_do/animate_do.dart';
import '../../services/voice_service.dart';
import '../../utils/app_colors.dart';

class SleepModeScreen extends StatefulWidget {
  final String language;
  final VoidCallback onUnlock;

  const SleepModeScreen({
    super.key, 
    required this.language, 
    required this.onUnlock
  });

  @override
  State<SleepModeScreen> createState() => _SleepModeScreenState();
}

class _SleepModeScreenState extends State<SleepModeScreen> {
  final VoiceService _voice = VoiceService();

  @override
  void initState() {
    super.initState();
    // Trigger the voice message exactly once
    _playBedtimeMessage();
  }

  void _playBedtimeMessage() {
    String msg = "";
    if (widget.language == "Malayalam") {
      msg = "ഇന്ന് ഒരുപാട് പഠിച്ചു കഴിഞ്ഞു. ഇനി നമുക്ക് വിശ്രമിക്കാം. ഗുഡ് നൈറ്റ്!";
    } else if (widget.language == "Hindi") {
      msg = "आज के लिए बहुत पढ़ाई हो गई। अब आराम करने का समय है। शुभ रात्रि!";
    } else {
      msg = "Great job learning today! It is time to rest your eyes. See you tomorrow!";
    }
    _voice.speak(msg, widget.language);
  }

  @override
  Widget build(BuildContext context) {
    // Material is REQUIRED here so the 'Parent Settings' button has a theme/action context
    return Material(
      color: Colors.transparent,
      child: Container(
        color: AppColors.childNavy.withOpacity(0.98),
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. SLEEPING BUDDY
            FadeInDown(
              duration: const Duration(seconds: 1),
              child: Lottie.asset(
                'assets/animations/buddy_sleep.json',
                height: 250,
                repeat: true,
                errorBuilder: (context, error, stackTrace) => 
                   const Icon(Icons.nightlight_round, size: 100, color: Colors.amberAccent),
              ),
            ),

            const SizedBox(height: 30),

            // 2. TEXT
            FadeInUp(
              child: const Text(
                "Time for a break!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 10),

            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: const Text(
                "You've done a great job today. Let's sleep now!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 50),

            // 3. UNLOCK BUTTON
            FadeIn(
              delay: const Duration(seconds: 1),
              child: ElevatedButton.icon(
                onPressed: widget.onUnlock,
                icon: const Icon(Icons.lock_open_rounded, size: 18),
                label: const Text("Parent Settings"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  foregroundColor: Colors.white70,
                  elevation: 0,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}