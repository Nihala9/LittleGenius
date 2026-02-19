import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import '../../../services/sound_service.dart';

class BubblePopGame extends StatefulWidget {
  const BubblePopGame({super.key});

  @override
  State<BubblePopGame> createState() => _BubblePopGameState();
}

class _BubblePopGameState extends State<BubblePopGame> {
  final List<BubbleInstance> _bubbles = [];
  final List<PopEffect> _effects = [];
  final Random _random = Random();
  late Timer _spawnTimer;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    // Spawn a bubble every 700ms
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 700), (t) => _spawnBubble());
  }

  void _spawnBubble() {
    if (!mounted) return;
    setState(() {
      _bubbles.add(BubbleInstance(
        id: DateTime.now().millisecondsSinceEpoch,
        x: _random.nextDouble() * (MediaQuery.of(context).size.width - 80),
        color: _getRandomPastelColor(),
        size: 70.0 + _random.nextDouble() * 40.0,
        speed: 4 + _random.nextInt(3), // 4 to 7 seconds to reach top
      ));
    });
  }

  Color _getRandomPastelColor() {
    List<Color> colors = [
      Colors.blue.shade200, 
      Colors.pink.shade200, 
      Colors.purple.shade200, 
      Colors.orange.shade200, 
      Colors.green.shade200,
      Colors.cyan.shade200
    ];
    return colors[_random.nextInt(colors.length)];
  }

  void _pop(BubbleInstance bubble) {
    HapticFeedback.lightImpact(); // Tactile feedback
    SoundService.playSFX('pop.mp3');

    setState(() {
      _score += 10;
      // Capture exact position for the burst effect
      _effects.add(PopEffect(x: bubble.x, y: bubble.currentY, color: bubble.color));
      _bubbles.remove(bubble);
    });

    // Clean up the effect after it finishes animating
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && _effects.isNotEmpty) {
        setState(() => _effects.removeAt(0));
      }
    });
  }

  @override
  void dispose() {
    _spawnTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0C3FC), Color(0xFF8EC5FC)],
          ),
        ),
        child: Stack(
          children: [
            // 1. Particle Bursts
            ..._effects.map((e) => _buildPopBurst(e)),

            // 2. Floating Bubbles
            ..._bubbles.map((b) => _buildAnimatedBubble(b)),
            
            // 3. Score UI
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Center(
                child: BounceInDown(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Text(
                      "SCORE: $_score", 
                      style: const TextStyle(
                        fontSize: 28, 
                        fontWeight: FontWeight.w900, // FIXED: Replaced .black with .w900
                        color: Colors.white, 
                        letterSpacing: 2,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]
                      )
                    ),
                  ),
                ),
              ),
            ),

            // 4. Exit Button
            Positioned(
              top: 50,
              right: 20,
              child: IconButton(
                icon: CircleAvatar(
                  backgroundColor: Colors.black12,
                  child: const Icon(Icons.close, color: Colors.white)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBubble(BubbleInstance bubble) {
    double screenHeight = MediaQuery.of(context).size.height;

    return TweenAnimationBuilder(
      key: ValueKey(bubble.id),
      tween: Tween<double>(begin: screenHeight + 100, end: -150),
      duration: Duration(seconds: bubble.speed),
      builder: (context, double y, child) {
        bubble.currentY = y; // Update current Y for the pop logic
        return Positioned(
          left: bubble.x,
          top: y,
          child: GestureDetector(
            onTapDown: (_) => _pop(bubble),
            child: Pulse(
              infinite: true,
              duration: const Duration(seconds: 2),
              child: Container(
                width: bubble.size,
                height: bubble.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [bubble.color.withOpacity(0.3), bubble.color.withOpacity(0.8)],
                    center: const Alignment(-0.3, -0.3),
                  ),
                  boxShadow: [
                    BoxShadow(color: bubble.color.withOpacity(0.2), blurRadius: 15, spreadRadius: 2)
                  ],
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                ),
                child: Stack(
                  children: [
                    Positioned( // Glossy shine reflection
                      top: bubble.size * 0.15,
                      left: bubble.size * 0.15,
                      child: Container(
                        width: bubble.size * 0.25,
                        height: bubble.size * 0.15,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      onEnd: () => setState(() => _bubbles.remove(bubble)),
    );
  }

  Widget _buildPopBurst(PopEffect effect) {
    return Positioned(
      left: effect.x + 20,
      top: effect.y + 20,
      child: ZoomOut(
        duration: const Duration(milliseconds: 400),
        child: Stack(
          alignment: Alignment.center,
          children: List.generate(6, (i) {
            double angle = (i * 60) * pi / 180;
            return Transform.translate(
              offset: Offset(cos(angle) * 50, sin(angle) * 50),
              child: Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, 
                  color: effect.color.withOpacity(0.8)
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class BubbleInstance {
  final int id;
  final double x;
  final Color color;
  final double size;
  final int speed;
  double currentY = 0;
  BubbleInstance({required this.id, required this.x, required this.color, required this.size, required this.speed});
}

class PopEffect {
  final double x, y;
  final Color color;
  PopEffect({required this.x, required this.y, required this.color});
}