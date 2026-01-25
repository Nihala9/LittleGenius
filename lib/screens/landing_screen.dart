import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. FULL-SCREEN IMMERSIVE BACKGROUND
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/landing_img.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. MULTI-LAYER GRADIENT OVERLAY (For readability and depth)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.1, 0.5, 0.9],
                colors: [
                  Colors.black.withOpacity(0.3), // Top shadow
                  Colors.transparent,             // Clear middle
                  Colors.black.withOpacity(0.9), // Dark bottom for text
                ],
              ),
            ),
          ),

          // 3. CONTENT LAYER
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  
                  // TOP BADGE (Highlighting AI Technology)
                  _buildAIBadge(),
                  
                  const Spacer(),

                  // APP BRANDING
                  const Text(
                    "LittleGenius",
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -1.5,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 15, offset: Offset(0, 5))],
                    ),
                  ),

                  const SizedBox(height: 15),

                  // VALUE PROPOSITION (Why parents should use it)
                  const Text(
                    "The personalized AI tutor that turns screen time into an educational adventure.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      height: 1.4,
                      fontFamily: 'Poppins',
                    ),
                  ),

                  const SizedBox(height: 50),

                  // PRIMARY ACTION: START ADVENTURE (Registration Path)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 70),
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 10,
                      shadowColor: AppColors.primaryBlue.withOpacity(0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Start Adventure", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(width: 15),
                        Icon(Icons.rocket_launch_rounded, size: 28),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // SECONDARY ACTION: LOGIN (Returning User Path)
                  _buildLoginLink(context),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget: AI Feature Badge
  Widget _buildAIBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.accentOrange, size: 18),
          const SizedBox(width: 8),
          Text(
            "Powered by Personalization AI",
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Widget: Login Link
  Widget _buildLoginLink(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.pushNamed(context, '/login'),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Poppins'),
          children: [
            const TextSpan(text: "Already a member? "),
            TextSpan(
              text: "Login",
              style: TextStyle(
                color: AppColors.accentOrange,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}