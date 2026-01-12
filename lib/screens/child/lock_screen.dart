import 'package:flutter/material.dart';

class LockScreen extends StatelessWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade900,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bedtime, size: 100, color: Colors.yellow),
            const SizedBox(height: 20),
            const Text("Adventure Time is Over!", 
              style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: Text("Your brain did a great job today. It's time to rest and play outside!", 
                textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.white70)),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("Parent Unlock")
            )
          ],
        ),
      ),
    );
  }
}