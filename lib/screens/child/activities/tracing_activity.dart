import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/tracing_assets.dart';
import '../../../services/sound_service.dart';
import '../../../services/voice_service.dart';

// Helper to store finished parts of the letter
class FinishedStroke {
  final List<Offset?> points;
  final Color color;
  FinishedStroke(this.points, this.color);
}

class TracingActivity extends StatefulWidget {
  final String targetLetter;
  final String language;
  final Function(bool) onComplete;

  const TracingActivity({
    super.key, 
    required this.targetLetter, 
    required this.language, 
    required this.onComplete
  });

  @override
  State<TracingActivity> createState() => _TracingActivityState();
}

class _TracingActivityState extends State<TracingActivity> with TickerProviderStateMixin {
  final VoiceService _voice = VoiceService();
  
  // --- DRAWING STATE ---
  List<Offset?> _currentPoints = [];
  List<FinishedStroke> _completedStrokes = [];
  late List<List<Offset>> _allStrokes;
  int _activeStrokeIdx = 0;
  Set<int> _hitWaypoints = {};
  
  // --- AI STRUGGLE SYSTEM ---
  int _mistakeCount = 0;
  int _offTrackPoints = 0; 
  bool _hintActive = false; 
  bool _showTutorial = false;
  bool _isCelebrating = false;
  Timer? _idleTimer;

  late AnimationController _tutorialController;
  final List<Color> _palette = [
    AppColors.childBlue, 
    AppColors.childGreen, 
    AppColors.childPink, 
    AppColors.childOrange
  ];

  @override
  void initState() {
    super.initState();
    _allStrokes = TracingAssets.getStrokes(widget.targetLetter[0]);
    _tutorialController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _startIdleTimer();
  }

  // AI: Detects if the child is staring at the screen doing nothing
  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && _currentPoints.isEmpty && !_isCelebrating) {
        setState(() { _showTutorial = true; _hintActive = true; });
        _speakLocalized("idle");
        _mistakeCount++; 
        if (_mistakeCount >= 4) widget.onComplete(false); // AI Redirect
      }
    });
  }

  void _speakLocalized(String type) {
    String msg = "";
    if (widget.language == "Malayalam") {
      switch (type) {
        case "idle": msg = "Namukku orumichu varaykkam!"; break; // Let's draw together
        case "wrong": msg = "Oh-oh! Varayil thudarku!"; break; // Oh-oh stay on the lines
        case "success": msg = "Nannayi cheithu!"; break; // Well done
      }
    } else {
      switch (type) {
        case "idle": msg = "Need help? Follow the glowing dot!"; break;
        case "wrong": msg = "Oh-oh! Try to stay on the path!"; break;
        case "success": msg = "Great tracing!"; break;
      }
    }
    _voice.speak(msg, widget.language);
  }

  void _processInput(Offset localPos) {
    if (_activeStrokeIdx >= _allStrokes.length || _isCelebrating) return;
    List<Offset> activeWaypoints = _allStrokes[_activeStrokeIdx];
    bool isNearPath = false;

    for (int i = 0; i < activeWaypoints.length; i++) {
      double dist = (localPos - activeWaypoints[i]).distance;
      if (dist < 50) {
        isNearPath = true;
        if (!_hitWaypoints.contains(i)) {
          setState(() { _hitWaypoints.add(i); _offTrackPoints = 0; });
          HapticFeedback.selectionClick();
        }
      } else if (dist < 110) { isNearPath = true; }
    }

    // AI: Scribble detection (Drawing far from the letter)
    if (!isNearPath) {
      _offTrackPoints++;
      if (_offTrackPoints > 20) _handleMistake();
    }
    
    if (_hitWaypoints.length == activeWaypoints.length) _completeStroke();
  }

  void _handleMistake() async {
    _offTrackPoints = 0;
    _mistakeCount++;
    SoundService.playSFX('wrong.mp3');
    
    setState(() { 
      _currentPoints.clear(); 
      _hitWaypoints.clear(); 
      _hintActive = true; 
    });

    if (_mistakeCount < 3) {
      _speakLocalized("wrong");
    } else {
      widget.onComplete(false); // AI: Kid is struggling too much, redirect activity
    }
  }

  void _manualRefresh() {
    SoundService.playSFX('pop.mp3');
    setState(() {
      _currentPoints.clear();
      _completedStrokes.clear();
      _activeStrokeIdx = 0;
      _hitWaypoints.clear();
      _mistakeCount = 0;
      _offTrackPoints = 0;
      _hintActive = false;
      _showTutorial = false;
    });
    _startIdleTimer();
  }

  void _completeStroke() {
    SoundService.playSFX('pop.mp3');
    setState(() {
      _completedStrokes.add(FinishedStroke(
        List.from(_currentPoints), 
        _palette[_activeStrokeIdx % 4]
      ));
      _currentPoints.clear(); 
      _hitWaypoints.clear(); 
      _activeStrokeIdx++;
      _mistakeCount = 0; // Reset mistakes on success
      _isCelebrating = true;
    });

    if (_activeStrokeIdx == _allStrokes.length) {
      Future.delayed(const Duration(milliseconds: 500), () => widget.onComplete(true));
    } else {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) { setState(() => _isCelebrating = false); _startIdleTimer(); }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String letter = widget.targetLetter[0].toUpperCase();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FadeInDown(child: Text("Trace '$letter'", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.childNavy))),
        const SizedBox(height: 20),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 320, height: 420,
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(30), 
                border: Border.all(color: _hintActive ? AppColors.childPink.withOpacity(0.3) : Colors.grey.shade100, width: 2),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15)]
              ),
              child: Builder(builder: (canvasContext) {
                return GestureDetector(
                  onPanUpdate: (details) {
                    if (_isCelebrating) return;
                    _startIdleTimer();
                    setState(() { 
                      _showTutorial = false;
                      final RenderBox box = canvasContext.findRenderObject() as RenderBox;
                      final Offset localPos = box.globalToLocal(details.globalPosition);
                      if (localPos.dx >= 0 && localPos.dx <= 320 && localPos.dy >= 0 && localPos.dy <= 420) { 
                        _currentPoints.add(localPos); 
                        _processInput(localPos); 
                      }
                    });
                  },
                  onPanEnd: (_) => _currentPoints.add(null),
                  child: CustomPaint(
                    painter: TracingPainter(
                      currentPoints: _currentPoints, 
                      completedStrokes: _completedStrokes, 
                      currentColor: _palette[_activeStrokeIdx % 4], 
                      letter: letter, 
                      hintActive: _hintActive, 
                      activeWaypoints: _activeStrokeIdx < _allStrokes.length ? _allStrokes[_activeStrokeIdx] : []
                    ), 
                    size: const Size(320, 420)
                  ),
                );
              }),
            ),
            if (_showTutorial && _activeStrokeIdx < _allStrokes.length)
              IgnorePointer(child: AnimatedBuilder(animation: _tutorialController, builder: (context, child) {
                return CustomPaint(painter: TutorialPathPainter(progress: _tutorialController.value, points: _allStrokes[_activeStrokeIdx]), size: const Size(320, 420));
              })),
          ],
        ),
        const SizedBox(height: 30),
        
        // --- CONTROLS & STARS ---
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 40, color: Colors.grey),
              onPressed: _manualRefresh,
            ),
            const SizedBox(width: 20),
            ...List.generate(_allStrokes.length, (i) => BounceInUp(
              animate: i < _activeStrokeIdx,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Icon(
                  i < _activeStrokeIdx ? Icons.stars_rounded : Icons.radio_button_off, 
                  color: i < _activeStrokeIdx ? _palette[i % 4] : Colors.grey.shade300, 
                  size: 35
                ),
              ),
            )),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() { _idleTimer?.cancel(); _tutorialController.dispose(); super.dispose(); }
}

class TracingPainter extends CustomPainter {
  final List<Offset?> currentPoints;
  final List<FinishedStroke> completedStrokes;
  final Color currentColor;
  final String letter;
  final bool hintActive;
  final List<Offset> activeWaypoints;

  TracingPainter({required this.currentPoints, required this.completedStrokes, required this.currentColor, required this.letter, required this.hintActive, required this.activeWaypoints});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Background Letter
    TextPainter(text: TextSpan(text: letter, style: TextStyle(fontSize: 340, color: Colors.grey.shade50, fontWeight: FontWeight.w900)), textDirection: TextDirection.ltr)..layout()..paint(canvas, Offset((size.width - 220) / 2, (size.height - 380) / 2));
    
    // 2. Draw Hint Dots
    if (hintActive) {
      final p = Paint()..color = AppColors.childPink.withOpacity(0.15);
      for (var o in activeWaypoints) canvas.drawCircle(o, 15, p);
    }

    // 3. Draw Finished Lines
    Paint p = Paint()..strokeCap = StrokeCap.round..strokeWidth = 24.0;
    for (var s in completedStrokes) { 
      p.color = s.color; 
      for (int i = 0; i < s.points.length - 1; i++) { 
        if (s.points[i] != null && s.points[i+1] != null) canvas.drawLine(s.points[i]!, s.points[i+1]!, p); 
      } 
    }

    // 4. Draw Current Line
    p.color = currentColor; 
    for (int i = 0; i < currentPoints.length - 1; i++) { 
      if (currentPoints[i] != null && currentPoints[i+1] != null) canvas.drawLine(currentPoints[i]!, currentPoints[i+1]!, p); 
    }
  }
  @override bool shouldRepaint(TracingPainter old) => true;
}

class TutorialPathPainter extends CustomPainter {
  final double progress; final List<Offset> points;
  TutorialPathPainter({required this.progress, required this.points});
  @override
  void paint(Canvas canvas, Size size) {
    int segIdx = (progress * (points.length - 1)).floor();
    double segProg = (progress * (points.length - 1)) - segIdx;
    Offset pos = Offset.lerp(points[segIdx], points[(segIdx + 1).clamp(0, points.length - 1)], segProg)!;
    
    canvas.drawCircle(pos, 22, Paint()..color = AppColors.childPink.withOpacity(0.3));
    canvas.drawCircle(pos, 10, Paint()..color = AppColors.childPink);
  }
  @override bool shouldRepaint(TutorialPathPainter old) => true;
}