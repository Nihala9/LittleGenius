import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import '../../models/child_model.dart';
import '../../models/concept_model.dart';
import '../../services/database_service.dart';
import '../../services/ai_engine.dart';
import '../../utils/app_colors.dart';
import 'game_container.dart';

class LearningMapScreen extends StatefulWidget {
  final ChildProfile child;
  final String category;

  const LearningMapScreen({super.key, required this.child, required this.category});

  @override
  State<LearningMapScreen> createState() => _LearningMapScreenState();
}

class _LearningMapScreenState extends State<LearningMapScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _floatController;
  final _db = DatabaseService();
  final _ai = AIEngine();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(duration: const Duration(seconds: 1), vsync: this)..repeat(reverse: true);
    _floatController = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white.withAlpha(180),
        elevation: 0,
        title: Text("${widget.category} Kingdom", style: const TextStyle(color: AppColors.ultraViolet, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Concept>>(
        stream: _db.streamPublishedConceptsByCategory(widget.category),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final concepts = snapshot.data!;
          double mapHeight = math.max(MediaQuery.of(context).size.height, concepts.length * 180.0 + 400);

          return SingleChildScrollView(
            child: Container(
              height: mapHeight,
              width: screenWidth,
              decoration: _buildWorldGradient(),
              child: Stack(
                children: [
                  // LAYER 1: THE ROAD PAINTER
                  Positioned.fill(
                    child: CustomPaint(painter: AdventurePathPainter(concepts.length, mapHeight)),
                  ),

                  // LAYER 2: DECORATIONS (Trees, Flowers, Animals)
                  ..._buildWorldDecorations(concepts.length, mapHeight, screenWidth),

                  // LAYER 3: INTERACTIVE LEVELS & MASCOT
                  ...List.generate(concepts.length, (index) {
                    bool isUnlocked = index == 0 || (widget.child.masteryScores[concepts[index - 1].id] ?? 0.0) > 0.8;
                    bool isCurrent = isUnlocked && (widget.child.masteryScores[concepts[index].id] ?? 0.0) < 0.8;
                    
                    return _buildLevelNode(concepts[index], index, isUnlocked, isCurrent, mapHeight, screenWidth);
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- GAME GRAPHICS: BIOME GRADIENT ---
  BoxDecoration _buildWorldGradient() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Color(0xFF7CB342), // Meadow Green
          Color(0xFF4DD0E1), // River Blue
          Color(0xFFFFD54F), // Desert Sand
          Color(0xFFE1F5FE), // Cloud Heights
        ],
      ),
    );
  }

  // --- GAME GRAPHICS: SCATTERED DECORATIONS ---
  List<Widget> _buildWorldDecorations(int count, double height, double width) {
    List<Widget> decorations = [];
    final random = math.Random(widget.category.length); // Seeded random stays consistent
    
    for (int i = 0; i < count * 2; i++) {
      double y = random.nextDouble() * height;
      double x = random.nextDouble() * width;
      String emoji = ["🌲", "🌸", "🏡", "🐄", "☁️", "🍄"][random.nextInt(6)];
      
      decorations.add(Positioned(
        left: x, top: y,
        child: Opacity(opacity: 0.6, child: Text(emoji, style: const TextStyle(fontSize: 30))),
      ));
    }
    return decorations;
  }

  Widget _buildLevelNode(Concept concept, int index, bool isUnlocked, bool isCurrent, double mapHeight, double screenWidth) {
    // SINE MATH for the curve
    double xPos = (screenWidth / 2 - 45) + (math.sin(index * 1.2) * (screenWidth * 0.28));
    double yPos = mapHeight - (index * 180.0) - 250;

    return Positioned(
      left: xPos,
      top: yPos,
      child: Column(
        children: [
          if (isCurrent) _buildCurrentPlayerMarker(), // Show Buddy on current level
          GestureDetector(
            onTap: isUnlocked ? () async {
              var activity = await _ai.getPersonalizedActivity(widget.child, concept.id);
              if (activity != null) {
                Navigator.push(context, MaterialPageRoute(builder: (c) => GameContainer(child: widget.child, activity: activity, parentId: FirebaseAuth.instance.currentUser!.uid)));
              }
            } : null,
            child: _buildBubble(index, isUnlocked, isCurrent),
          ),
          const SizedBox(height: 5),
          _buildNodeLabel(concept.name, isUnlocked),
        ],
      ),
    );
  }

  Widget _buildCurrentPlayerMarker() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -10 + (math.sin(_floatController.value * 2 * math.pi) * 8)),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: CircleAvatar(radius: 20, backgroundImage: AssetImage(widget.child.avatarUrl)),
          ),
        );
      },
    );
  }

  Widget _buildBubble(int index, bool isUnlocked, bool isCurrent) {
    Color color = [AppColors.childPink, AppColors.childOrange, AppColors.childGreen, AppColors.childBlue][index % 4];
    return ScaleTransition(
      scale: isCurrent ? Tween(begin: 1.0, end: 1.1).animate(_pulseController) : const AlwaysStoppedAnimation(1.0),
      child: Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle, color: Colors.white,
          boxShadow: [BoxShadow(color: isCurrent ? color.withAlpha(150) : Colors.black26, blurRadius: 15)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: CircleAvatar(
            backgroundColor: isUnlocked ? color : Colors.grey.shade400,
            child: Icon(isUnlocked ? (isCurrent ? Icons.play_arrow : Icons.check) : Icons.lock, color: Colors.white, size: 40),
          ),
        ),
      ),
    );
  }

  Widget _buildNodeLabel(String name, bool isUnlocked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.lavender)),
      child: Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isUnlocked ? AppColors.textDark : Colors.grey)),
    );
  }
}

// --- GAME DEVELOPER LOGIC: THE DASHED ROAD ---
class AdventurePathPainter extends CustomPainter {
  final int nodes;
  final double mapHeight;
  AdventurePathPainter(this.nodes, this.mapHeight);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(120)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30
      ..strokeCap = StrokeCap.round;

    final path = Path();
    double centerX = size.width / 2;

    for (double i = 0; i <= nodes; i += 0.05) {
      double x = centerX + (math.sin(i * 1.2) * (size.width * 0.28)) + 40;
      double y = mapHeight - (i * 180.0) - 210;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }

    // Draw the main thick "dirt road"
    canvas.drawPath(path, paint);
    
    // Draw the "Dashed center line" for the road
    final dashPaint = Paint()
      ..color = Colors.white.withAlpha(200)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
      
    canvas.drawPath(path, dashPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}