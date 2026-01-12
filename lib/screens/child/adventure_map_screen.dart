import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async'; // Required for the timer
import '../../models/child_profile.dart';
import '../../services/voice_service.dart';
import 'activity_screen.dart';
import 'lock_screen.dart'; // Import the lock screen

class AdventureMapScreen extends StatefulWidget {
  final ChildProfile child;

  const AdventureMapScreen({super.key, required this.child});

  @override
  _AdventureMapScreenState createState() => _AdventureMapScreenState();
}

class _AdventureMapScreenState extends State<AdventureMapScreen> {
  final VoiceService _voice = VoiceService();
  Timer? _usageTimer;
  int _sessionMinutes = 0;

  @override
  void initState() {
    super.initState();
    // 1. Initial Greeting
    _voice.speakGreeting(widget.child.name, widget.child.language);

    // 2. Start Screen Time Tracking (Updates every 1 minute)
    _startTrackingTime();
  }

  void _startTrackingTime() {
    _usageTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _incrementUsage();
    });
  }

  Future<void> _incrementUsage() async {
    _sessionMinutes++;
    int totalToday = widget.child.usageToday + _sessionMinutes;

    // Update Firestore
    await FirebaseFirestore.instance
        .collection('children')
        .doc(widget.child.id)
        .update({'usageToday': totalToday});

    // Check if daily limit is reached
    if (totalToday >= widget.child.dailyLimit) {
      _usageTimer?.cancel();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LockScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _usageTimer?.cancel(); // Stop timer when leaving screen
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlueAccent, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.blue),
                      onPressed: () => Navigator.pop(context),
                    ),
                    // Progress indicators
                    Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.orange, size: 24),
                            Text(" ${widget.child.totalStars}", 
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Text("Time: ${widget.child.usageToday}m / ${widget.child.dailyLimit}m",
                          style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Text("Learning Adventure", 
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLevelButton(Icons.abc, "Alphabets", Colors.purple),
                      const SizedBox(height: 30),
                      _buildLevelButton(Icons.calculate, "Numbers", Colors.green),
                      const SizedBox(height: 30),
                      _buildLevelButton(Icons.pets, "Animals", Colors.orange),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelButton(IconData icon, String title, Color color) {
    return InkWell(
      onTap: () {
        if (title == "Alphabets") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActivityScreen(child: widget.child, conceptId: "Letter_A"),
            ),
          );
        }
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 50),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}