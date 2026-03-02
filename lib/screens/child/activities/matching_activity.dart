import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:animate_do/animate_do.dart';
import '../../../models/concept_model.dart';
import '../../../utils/game_assets.dart';
import '../../../utils/app_colors.dart';
import 'matching_painter.dart';

class MatchingActivity extends StatefulWidget {
  final Concept concept;
  final Function(bool) onComplete;

  const MatchingActivity({super.key, required this.concept, required this.onComplete});

  @override
  State<MatchingActivity> createState() => _MatchingActivityState();
}

class _MatchingActivityState extends State<MatchingActivity> with TickerProviderStateMixin {
  late String _sourceID;
  late List<String> _options;
  
  final GlobalKey _sourceDotKey = GlobalKey();
  final Map<String, GlobalKey> _targetDotKeys = {};
  
  Offset? _dragStart;
  Offset? _dragEnd;
  bool _isSolved = false;
  bool _showTutorial = true;

  late AnimationController _tutorialController;
  Animation<Offset>? _handMovement;

  @override
  void initState() {
    super.initState();
    _setupGame();
    _setupTutorial();
  }

  void _setupGame() {
    _sourceID = widget.concept.name;
    List<String> distractors = GameAssets.getDistractors(_sourceID, widget.concept.category);
    _options = List.from(distractors);
    _options.add(_sourceID);
    _options.shuffle();

    for (var id in _options) {
      _targetDotKeys[id] = GlobalKey();
    }
  }

  void _setupTutorial() {
    _tutorialController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        final start = _getCenterOfDot(_sourceDotKey);
        final targetKey = _targetDotKeys[_sourceID];
        if (targetKey != null) {
          final end = _getCenterOfDot(targetKey);
          setState(() {
            _handMovement = Tween<Offset>(begin: start, end: end).animate(
              CurvedAnimation(parent: _tutorialController, curve: const Interval(0.2, 0.8, curve: Curves.easeInOut)),
            );
          });
        }
      });
    });
  }

  // --- FIXED: PRECISE COORDINATE CALCULATION ---
  Offset _getCenterOfDot(GlobalKey key) {
    if (key.currentContext == null) return Offset.zero;
    final RenderBox box = key.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = box.localToGlobal(Offset.zero, ancestor: overlay);
    // Center logic based on the 32x32 dot size
    return Offset(position.dx + 16, position.dy + 16); 
  }

  void _onPanStart(DragStartDetails details) {
    if (_isSolved) return;
    setState(() {
      _showTutorial = false;
      _dragStart = _getCenterOfDot(_sourceDotKey);
      _dragEnd = _dragStart;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isSolved || _dragStart == null) return;
    setState(() {
      _dragEnd = details.globalPosition;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dragEnd == null || _isSolved) return;

    String? foundTargetID;
    Offset? targetCenter;

    for (var id in _options) {
      Offset center = _getCenterOfDot(_targetDotKeys[id]!);
      if ((_dragEnd! - center).distance < 50) {
        foundTargetID = id;
        targetCenter = center;
        break;
      }
    }

    if (foundTargetID != null && foundTargetID == _sourceID) {
      setState(() { _isSolved = true; _dragEnd = targetCenter; });
      widget.onComplete(true);
    } else {
      setState(() { _dragStart = null; _dragEnd = null; });
      if (foundTargetID != null) widget.onComplete(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. THE DRAWN LINE
          Positioned.fill(
            child: CustomPaint(
              painter: LineMatchingPainter(
                completedLines: [], 
                currentStart: _dragStart,
                currentEnd: _dragEnd,
                activeColor: _isSolved ? AppColors.childGreen : AppColors.childBlue,
              ),
            ),
          ),

          // 2. MAIN INTERFACE
          Column(
            children: [
              const SizedBox(height: 60),
              // Header
              FadeInDown(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: AppColors.childBlue.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))],
                  ),
                  child: const Text("Match the Pair!", 
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.childBlue)),
                ),
              ),
              
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      // LEFT SIDE: CONCEPT
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildItemContent(_sourceID, false, screenWidth),
                              const SizedBox(width: 8),
                              _dot(_sourceDotKey, true),
                            ],
                          ),
                        ),
                      ),
                      
                      // RIGHT SIDE: OPTIONS
                      Expanded(
                        flex: 3,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _options.map((id) => Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _dot(_targetDotKeys[id]!, false),
                              const SizedBox(width: 8),
                              _buildItemContent(id, true, screenWidth),
                            ],
                          )).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 3. TUTORIAL
          if (_showTutorial && !_isSolved && _handMovement != null) 
            _buildTutorialLayer(),
        ],
      ),
    );
  }

  Widget _buildItemContent(String id, bool isTarget, double screenWidth) {
    final data = GameAssets.getConceptData(id);
    bool isShadowCategory = (widget.concept.category == "Animals" || widget.concept.category == "Shapes");
    
    // Scale font size based on screen width to prevent overflow
    double iconSize = screenWidth < 400 ? 55 : 70;

    Widget content;
    if (isTarget && isShadowCategory) {
      content = ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
        child: Opacity(
          opacity: 0.1, // Visible shadow
          child: Text(data['item'], style: TextStyle(fontSize: iconSize + 10)),
        ),
      );
    } else {
      content = Text(
        isTarget ? data['match'] : data['item'], 
        style: TextStyle(fontSize: iconSize, fontWeight: FontWeight.bold, color: AppColors.childNavy)
      );
    }

    return Flexible(child: content);
  }

  Widget _dot(GlobalKey key, bool isSource) {
    return GestureDetector(
      onPanStart: isSource ? _onPanStart : null,
      onPanUpdate: isSource ? _onPanUpdate : null,
      onPanEnd: isSource ? _onPanEnd : null,
      child: Container(
        key: key,
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: Colors.white, shape: BoxShape.circle,
          border: Border.all(color: isSource ? AppColors.childBlue : Colors.grey.shade300, width: 4),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4)],
        ),
        child: Center(child: CircleAvatar(radius: 5, backgroundColor: isSource ? AppColors.childBlue : Colors.grey.shade300)),
      ),
    );
  }

  Widget _buildTutorialLayer() {
    return AnimatedBuilder(
      animation: _tutorialController,
      builder: (context, child) {
        final currentHandPos = _handMovement!.value;
        return Stack(
          children: [
            CustomPaint(
              painter: LineMatchingPainter(
                completedLines: [],
                currentStart: _getCenterOfDot(_sourceDotKey),
                currentEnd: currentHandPos,
                activeColor: AppColors.childBlue.withOpacity(0.3),
              ),
            ),
            Positioned(
              left: currentHandPos.dx - 20,
              top: currentHandPos.dy - 20,
              child: IgnorePointer(child: Lottie.asset('assets/animations/hand_gesture.json', height: 60)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _tutorialController.dispose();
    super.dispose();
  }
}