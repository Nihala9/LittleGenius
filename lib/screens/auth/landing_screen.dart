import 'package:flutter/material.dart';
import 'login_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. SOFT GRADIENT BACKGROUND
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade100, Colors.white],
              ),
            ),
          ),

          // 2. SUBTLE EDUCATIONAL BACKGROUND ACCENTS (Abstract Shapes/Icons)
          Positioned(top: 100, left: -20, child: _buildBgIcon(Icons.abc, 120)),
          Positioned(top: 250, right: -30, child: _buildBgIcon(Icons.functions, 100)),
          Positioned(bottom: 200, left: 40, child: _buildBgIcon(Icons.star_border, 60)),
          Positioned(bottom: 350, right: 20, child: _buildBgIcon(Icons.menu_book, 80)),

          // 3. MAIN CONTENT WITH FADE-IN ANIMATION
          SafeArea(
            child: TweenAnimationBuilder(
              duration: const Duration(milliseconds: 1200),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: Padding(
                    padding: EdgeInsets.only(top: 20 * (1 - value)), // Gentle slide up
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    
                    // APP LOGO & TITLE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.indigo, size: 40),
                        const SizedBox(width: 10),
                        const Text(
                          "LittleGenius",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.indigo,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Turning Screen Time into Smart Learning",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const Spacer(),

                    // CENTRAL ILLUSTRATION REPRESENTATION
                    Container(
                      height: 250,
                      width: 250,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.1),
                            blurRadius: 50,
                            spreadRadius: 20,
                          )
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.smart_toy_rounded, // The Robot head icon
                          size: 150,
                          color: Colors.orangeAccent,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // VALUE PROPOSITION TEXT
                    const Text(
                      "Learning made fun, safe, and personalized",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.indigo,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // PRIMARY ACTION BUTTON
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 65),
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: Colors.indigo.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Get Started",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward_rounded),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for decorative background icons
  Widget _buildBgIcon(IconData icon, double size) {
    return Opacity(
      opacity: 0.07, // Very faint so it doesn't distract
      child: Icon(
        icon,
        size: size,
        color: Colors.indigo,
      ),
    );
  }
}