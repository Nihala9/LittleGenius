import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../models/story_model.dart';
import '../../../services/database_service.dart';
import '../../../utils/app_colors.dart';
import 'story_player_screen.dart';

class StoryLibraryScreen extends StatelessWidget {
  const StoryLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Bedtime Stories"),
        elevation: 0, backgroundColor: Colors.white, foregroundColor: AppColors.childNavy,
      ),
      body: StreamBuilder<List<KidStory>>(
        stream: DatabaseService().streamStories(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final stories = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 20, crossAxisSpacing: 20, childAspectRatio: 0.8
            ),
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];
              return FadeInUp(
                delay: Duration(milliseconds: index * 100),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (c) => StoryPlayerScreen(videoId: story.youtubeId, title: story.title)
                  )),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF9EE),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.orange.withOpacity(0.1)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_circle_fill, size: 50, color: Colors.orange),
                        const SizedBox(height: 15),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(story.title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        Text(story.duration, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}