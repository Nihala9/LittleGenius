import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lottie/lottie.dart';
import '../../../utils/game_assets.dart';
import '../../../services/sound_service.dart';
import '../../../services/voice_service.dart';

class ScratchRevealActivity extends StatefulWidget {
  final String itemName;
  final String? imageUrl;
  final String language;
  final Function(bool) onComplete;

  const ScratchRevealActivity({
    super.key, 
    required this.itemName, 
    this.imageUrl,
    required this.language, 
    required this.onComplete
  });

  @override
  State<ScratchRevealActivity> createState() => _ScratchRevealActivityState();
}

class _ScratchRevealActivityState extends State<ScratchRevealActivity> with SingleTickerProviderStateMixin {
  final VoiceService _voice = VoiceService();
  List<Offset?> points = [];
  bool _isFinished = false;

  // AI Logic Constants
  final Set<int> _revealedCells = {};
  final int _gridSize = 10; 
  Timer? _struggleTimer;
  int _secondsElapsed = 0;
  bool _showTutorialHand = false;

  late AnimationController _handController;
  late Animation<Offset> _handPath;

  @override
  void initState() {
    super.initState();
    _startStruggleMonitor();
    _handController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _handPath = Tween<Offset>(begin: const Offset(-80, -80), end: const Offset(80, 80))
        .animate(CurvedAnimation(parent: _handController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _struggleTimer?.cancel();
    _handController.dispose();
    super.dispose();
  }

  // --- THE AI REDIRECTION MONITOR ---
  void _startStruggleMonitor() {
    _struggleTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isFinished || !mounted) { timer.cancel(); return; }
      _secondsElapsed++;

      // Stage 1 & 2: Verbal Hints
      if (_secondsElapsed == 10 || _secondsElapsed == 20) {
        _speakStruggleMsg();
      }
      
      // Stage 3: Visual Tutorial
      if (_secondsElapsed == 10) {
        setState(() => _showTutorialHand = true);
        _handController.repeat(reverse: true);
      }

      // Stage 4: THE REDIRECT (Struggling too long)
      if (_secondsElapsed >= 30 && _revealedCells.length < 5) {
        timer.cancel();
        _voice.speak("Let's try a different game, buddy!", widget.language);
        widget.onComplete(false); // <--- Triggers redirection in GameContainer
      }
    });
  }

  void _speakStruggleMsg() {
    String msg = "";
    if (widget.language == "Malayalam") {
      msg = "ഇവിടെ ഒന്ന് ഉരച്ചു നോക്കൂ!";
    } else if (widget.language == "Hindi") {
      msg = "यहाँ रगड़ें!";
    } else if (widget.language == "Arabic") {
      msg = "امسح هنا!";
    } else {
      msg = "Rub the screen to see!";
    }
    _voice.speak(msg, widget.language);
  }

  void _checkProgress(Offset pos, Size size) {
    double cellWidth = size.width / _gridSize;
    double cellHeight = size.height / _gridSize;
    int col = (pos.dx / cellWidth).floor().clamp(0, _gridSize - 1);
    int row = (pos.dy / cellHeight).floor().clamp(0, _gridSize - 1);
    _revealedCells.add(row * _gridSize + col);

    if (_revealedCells.length >= 50 && !_isFinished) _triggerSuccess();
  }

  void _triggerSuccess() async {
    setState(() { _isFinished = true; _showTutorialHand = false; });
    _struggleTimer?.cancel();
    SoundService.playSFX('success.mp3'); 
    HapticFeedback.heavyImpact();

    String announce = widget.language == "Arabic" ? "أحسنت! هذا ${widget.itemName}" : "Great! This is a ${widget.itemName}!";
    await _voice.speak(announce, widget.language);

    await Future.delayed(const Duration(seconds: 3));
    widget.onComplete(true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FadeInDown(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
            child: Text("MAGIC BOX", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.purple.shade700, letterSpacing: 2)),
          ),
        ),
        const SizedBox(height: 40),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 320, height: 320,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(35)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: widget.imageUrl != null 
                  ? Image.network(widget.imageUrl!, fit: BoxFit.cover)
                  : Center(child: Text(GameAssets.getConceptData(widget.itemName)['item'], style: const TextStyle(fontSize: 150))),
              ),
            ),
            if (!_isFinished)
              SizedBox(
                width: 320, height: 320,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _showTutorialHand = false; // Hide tutorial as soon as they touch
                      points.add(details.localPosition);
                    });
                    _checkProgress(details.localPosition, const Size(320, 320));
                  },
                  onPanEnd: (_) => setState(() { points.add(null); }),
                  child: CustomPaint(painter: ScratchPainter(points: points), size: Size.infinite),
                ),
              ),
            if (_showTutorialHand)
              AnimatedBuilder(
                animation: _handPath,
                builder: (context, child) => Transform.translate(
                  offset: _handPath.value,
                  child: Lottie.asset('assets/animations/hand_gesture.json', height: 80),
                ),
              ),
          ],
        ),
        const SizedBox(height: 40),
        if (!_isFinished) Pulse(infinite: true, child: const Text("✨ Rub the screen! ✨", style: TextStyle(fontSize: 18, color: Colors.blueGrey, fontWeight: FontWeight.bold))),
      ],
    );
  }
}

class ScratchPainter extends CustomPainter {
  final List<Offset?> points;
  ScratchPainter({required this.points});
  @override
  void paint(Canvas canvas, Size size) {
    Paint coverPaint = Paint()..color = const Color(0xFFB0BEC5);
    Paint erasePaint = Paint()..blendMode = BlendMode.clear..strokeCap = StrokeCap.round..strokeWidth = 65.0;
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(35)), coverPaint);
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) canvas.drawLine(points[i]!, points[i + 1]!, erasePaint);
    }
    canvas.restore();
  }
  @override bool shouldRepaint(ScratchPainter old) => true;
}