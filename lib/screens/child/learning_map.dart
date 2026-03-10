import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import '../../models/child_model.dart';
import '../../models/concept_model.dart';
import '../../models/activity_model.dart';
import '../../services/database_service.dart';
import '../../services/ai_engine.dart';
import '../../services/sound_service.dart';
import '../../services/voice_service.dart';
import '../../utils/app_colors.dart';
import 'game_container.dart';

class LearningMapScreen extends StatelessWidget {
  final ChildProfile child;
  final String category;

  const LearningMapScreen({super.key, required this.child, required this.category});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    final ai = AIEngine();
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: StreamBuilder<ChildProfile>(
        // --- LIVE STREAM: Always stay synced with Firestore ---
        stream: db.streamSingleChild(user!.uid, child.id),
        builder: (context, childSnapshot) {
          // IMPORTANT: liveChild contains the latest 'masteryScores' and 'preferredMode'
          final liveChild = childSnapshot.data ?? child;

          return Stack(
            children: [
              // 1. DYNAMIC BACKGROUND
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFA6E3FF), Color(0xFFE2FFD1), Color(0xFFF9FFD1)],
                  ),
                ),
              ),

              // 2. SCROLLABLE ADVENTURE PATH
              StreamBuilder<List<Concept>>(
                stream: db.streamPublishedConceptsByCategory(category),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final concepts = snapshot.data!;
                  
                  // Identify current level (First level with mastery < 0.5)
                  int currentLevelIdx = concepts.indexWhere((c) => (liveChild.masteryScores[c.id] ?? 0.0) < 0.5);
                  if (currentLevelIdx == -1) currentLevelIdx = concepts.length - 1;

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 150, bottom: 300),
                    itemCount: concepts.length,
                    itemBuilder: (context, index) {
                      final concept = concepts[index];
                      double mastery = liveChild.masteryScores[concept.id] ?? 0.0;
                      
                      // LOGIC: Next level stays locked until current level has 2 Stars (0.5)
                      bool isLocked = index > currentLevelIdx;
                      bool isCurrent = index == currentLevelIdx;

                      double currentAlign = (index % 2 == 0) ? -0.65 : 0.65;
                      double nextAlign = (index % 2 == 0) ? 0.65 : -0.65;

                      return SizedBox(
                        height: 200,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Path Painter
                            if (index < concepts.length - 1)
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: FlowingPathPainter(startX: currentAlign, endX: nextAlign),
                                ),
                              ),
                            
                            // 3D Level Node
                            Align(
                              alignment: Alignment(currentAlign, 0),
                              child: _buildHighFidelityNode(
                                context, 
                                liveChild, // Pass fresh data
                                concept, 
                                index + 1, 
                                mastery, 
                                isLocked, 
                                isCurrent, 
                                ai
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              _buildHeader(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHighFidelityNode(
    BuildContext context, 
    ChildProfile liveChild, 
    Concept concept, 
    int num, 
    double mastery, 
    bool isLocked, 
    bool isCurrent, 
    AIEngine ai
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Stars (Based on LIVE mastery)
        _buildGlassyStarArc(mastery, isLocked),

        // 2. 3D Interaction Button
        GestureDetector(
          onTap: isLocked ? () {
            // --- AI LOCK GUIDANCE ---
            SoundService.playSFX('wrong.mp3');
            String msg = "";
            if (liveChild.language == "Malayalam") {
              msg = "അടുത്ത ഘട്ടം തുറക്കാൻ രണ്ട് നക്ഷത്രങ്ങൾ വേണം. ഈ പാഠം ഒന്നുകൂടി കളിക്കൂ!";
            } else if (liveChild.language == "Hindi") {
              msg = "अगला लेवल खोलने के लिए आपको दो सितारों की जरूरत है। इसे फिर से खेलें!";
            } else if (liveChild.language == "Arabic") {
              msg = "لفتح المستوى التالي، تحتاج إلى نجمتين. العب هذا الدرس مرة أخرى!";
            } else {
              msg = "Play this level again to get 2 stars and unlock the next path!";
            }
            VoiceService().speak(msg, liveChild.language);
          } : () async {
            SoundService.playSFX('pop.mp3');
            
            // --- AI SHUFFLE ENGINE ---
            // This now uses LIVE data to decide if it should shuffle or not
            Activity? act = await ai.getPersonalizedActivity(liveChild, concept.id);
            
            if (context.mounted && act != null) {
              Navigator.push(context, MaterialPageRoute(
                builder: (c) => GameContainer(child: liveChild, concept: concept, activity: act)
              ));
            }
          },
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // 3D Base
              Container(
                width: 95, height: 75,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.elliptical(47, 37)),
                  color: isLocked ? Colors.grey.shade400 : const Color(0xFFB07D4D),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 8))],
                ),
              ),
              // Interaction Surface
              Container(
                width: 82, height: 68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.elliptical(41, 34)),
                  gradient: LinearGradient(
                    colors: isLocked 
                      ? [Colors.grey.shade100, Colors.grey.shade300] 
                      : [const Color(0xFF4FC3F7), const Color(0xFF0288D1)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 3.5),
                ),
                child: Center(
                  child: isLocked 
                    ? const Icon(Icons.lock_rounded, color: Colors.white70, size: 28)
                    : Text("$num", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, shadows: [Shadow(blurRadius: 4, color: Colors.black26)])),
                ),
              ),
              // Mascot Indicator
              if (isCurrent)
                Positioned(
                  top: -55,
                  child: Bounce(
                    infinite: true,
                    child: Image.asset('assets/images/buddy.png', height: 55, errorBuilder: (c,e,s) => const Icon(Icons.face, color: Colors.blue, size: 50)),
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 10),

        // 3. Concept Name Label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
          ),
          child: Text(concept.name, style: const TextStyle(color: AppColors.childNavy, fontSize: 12, fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }

  Widget _buildGlassyStarArc(double mastery, bool isLocked) {
    int count = isLocked ? 0 : (mastery >= 0.8 ? 3 : (mastery >= 0.5 ? 2 : (mastery >= 0.3 ? 1 : 0)));
    return SizedBox(
      width: 130, height: 40,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          _glassStar(active: count >= 1, angle: -0.4, x: -45, y: -0, index: 0),
          _glassStar(active: count >= 2, angle: 0, x: 0, y: -12, index: 1),
          _glassStar(active: count >= 3, angle: 0.4, x: 45, y: -0, index: 2),
        ],
      ),
    );
  }

  Widget _glassStar({required bool active, required double angle, required double x, required double y, required int index}) {
    return Transform.translate(
      offset: Offset(x, y),
      child: Transform.rotate(
        angle: angle,
        child: ZoomIn(
          delay: Duration(milliseconds: index * 100),
          child: Icon(
            Icons.star_rounded,
            size: 38,
            color: active ? Colors.amber : const Color.fromARGB(255, 169, 168, 168).withOpacity(0.6),
            shadows: active ? [const Shadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))] : null,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            IconButton(
              icon: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.childBlue, size: 20)),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 10),
            Text(category.toUpperCase(), style: const TextStyle(color: AppColors.childNavy, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }
}

class FlowingPathPainter extends CustomPainter {
  final double startX;
  final double endX;
  FlowingPathPainter({required this.startX, required this.endX});

  @override
  void paint(Canvas canvas, Size size) {
    double x1 = (startX + 1) / 2 * size.width;
    double x2 = (endX + 1) / 2 * size.width;
    final path = Path();
    path.moveTo(x1, size.height / 2);
    path.cubicTo(x1, size.height * 0.95, x2, size.height * 0.05, x2, size.height * 1.5);
    final dashPaint = Paint()..color = AppColors.childBlue.withOpacity(0.4)..style = PaintingStyle.stroke..strokeWidth = 6..strokeCap = StrokeCap.round;
    for (var metric in path.computeMetrics()) {
      double dist = 0.0;
      while (dist < metric.length) {
        canvas.drawPath(metric.extractPath(dist, dist + 18), dashPaint);
        dist += 33.0; 
      }
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}