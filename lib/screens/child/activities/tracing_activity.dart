import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lottie/lottie.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/tracing_assets.dart';
import '../../../utils/game_assets.dart';
import '../../../services/sound_service.dart';
import '../../../services/voice_service.dart';
import 'workbook_painter.dart';

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
  
  // --- STATE (Final keywords added to satisfy warnings) ---
  final List<Offset?> _currentPoints = [];
  final List<FinishedStroke> _completedStrokes = [];
  late final List<List<Offset>> _allStrokes;
  final Set<int> _hitWaypoints = {};
  
  int _activeIdx = 0;
  int _scribblePoints = 0; 
  bool _showTutorial = true;
  bool _isLocked = false;

  late final AnimationController _handController;

  @override
  void initState() {
    super.initState();
    _allStrokes = TracingAssets.getStrokes(widget.targetLetter[0]);
    _handController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _voice.speak("Trace it!", widget.language);
  }

  // --- REFRESH LOGIC ---
  void _resetEntireGame() {
    SoundService.playSFX('pop.mp3');
    setState(() {
      _currentPoints.clear();
      _completedStrokes.clear();
      _activeIdx = 0;
      _hitWaypoints.clear();
      _scribblePoints = 0;
      _showTutorial = true;
      _isLocked = false;
    });
  }

  void _processInput(Offset pos, Color color) {
    if (_activeIdx >= _allStrokes.length || _isLocked) return;
    if (_showTutorial) setState(() => _showTutorial = false);

    List<Offset> path = _allStrokes[_activeIdx];
    
    // AI: Scribble Detection
    bool isNear = false;
    for (var p in path) {
      if ((pos - p).distance < 110) { 
        isNear = true;
        break;
      }
    }

    if (!isNear) {
      _scribblePoints++;
      if (_scribblePoints > 20) _handleError();
      return;
    }

    // Success detection
    for (int i = 0; i < path.length; i++) {
      if ((pos - path[i]).distance < 45) {
        if (!_hitWaypoints.contains(i)) {
          setState(() { _hitWaypoints.add(i); _scribblePoints = 0; });
          HapticFeedback.selectionClick();
        }
      }
    }

    if (_hitWaypoints.length == path.length) _finishStroke(color);
  }

  void _handleError() {
    SoundService.playSFX('wrong.mp3');
    setState(() {
      _currentPoints.clear();
      _hitWaypoints.clear();
      _scribblePoints = 0;
      _showTutorial = true; 
    });
    widget.onComplete(false); 
  }

  void _finishStroke(Color color) {
    SoundService.playSFX('pop.mp3');
    setState(() {
      _completedStrokes.add(FinishedStroke(List.from(_currentPoints), color));
      _currentPoints.clear();
      _hitWaypoints.clear();
      _activeIdx++;
      _showTutorial = true;
    });

    if (_activeIdx == _allStrokes.length) {
      setState(() => _isLocked = true);
      widget.onComplete(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = GameAssets.getConceptData(widget.targetLetter[0]);
    final Color themeColor = data['color'] ?? Colors.cyan;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FadeInDown(
          child: const Text("Trace it!", 
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.childNavy)),
        ),
        const SizedBox(height: 15),
        
        Container(
          width: 350, height: 540,
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(40),
            border: Border.all(color: themeColor, width: 14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)],
          ),
          child: Column(
            children: [
              Expanded(
                child: Builder(builder: (ctx) {
                  return Stack(
                    children: [
                      GestureDetector(
                        onPanUpdate: (d) {
                          if (_isLocked) return;
                          final RenderBox box = ctx.findRenderObject() as RenderBox;
                          Offset pos = box.globalToLocal(d.globalPosition);
                          if (pos.dx >= 0 && pos.dx <= 320 && pos.dy >= 0 && pos.dy <= 420) {
                            setState(() { _currentPoints.add(pos); });
                            _processInput(pos, themeColor);
                          }
                        },
                        onPanEnd: (_) => setState(() => _currentPoints.add(null)),
                        child: CustomPaint(
                          painter: WorkbookPainter(
                            completed: _completedStrokes,
                            current: _currentPoints,
                            activeColor: themeColor,
                            letter: widget.targetLetter[0],
                            // FIXED: Removed the undefined parameter 'allStrokes'
                          ),
                          size: const Size(320, 420),
                        ),
                      ),
                      if (_showTutorial && _activeIdx < _allStrokes.length)
                        _buildTutorialHand(_allStrokes[_activeIdx]),
                    ],
                  );
                }),
              ),
              _footer(data, themeColor),
            ],
          ),
        ),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(icon: const Icon(Icons.refresh_rounded, size: 50, color: Colors.redAccent), onPressed: _resetEntireGame),
            const SizedBox(width: 30),
            ...List.generate(_allStrokes.length, (i) => Icon(
              Icons.stars_rounded, size: 45, color: i < _activeIdx ? themeColor : Colors.grey.shade200
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildTutorialHand(List<Offset> points) {
    return AnimatedBuilder(
      animation: _handController,
      builder: (context, child) {
        int idx = (_handController.value * (points.length - 1)).floor();
        double sub = (_handController.value * (points.length - 1)) - idx;
        Offset pos = Offset.lerp(points[idx], points[(idx + 1).clamp(0, points.length - 1)], sub)!;
        return Positioned(left: pos.dx - 20, top: pos.dy - 20, child: IgnorePointer(child: Lottie.asset('assets/animations/hand_gesture.json', height: 60)));
      },
    );
  }

  Widget _footer(Map data, Color c) => Container(
    height: 110, color: Colors.grey.shade50,
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _item(data['item'] ?? "🍎", data['word'] ?? "Apple", c),
      _item(data['extra'] ?? "🐜", data['extraWord'] ?? "Ant", c),
    ]),
  );

  Widget _item(String i, String w, Color c) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Text(i, style: const TextStyle(fontSize: 40)),
    Text(w.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c))
  ]);

  @override void dispose() { _handController.dispose(); super.dispose(); }
}