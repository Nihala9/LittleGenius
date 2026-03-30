import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../models/child_model.dart';
import '../../../models/story_model.dart';
import '../../../services/database_service.dart';
import '../../../utils/app_colors.dart';

class StoryLibraryScreen extends StatelessWidget {
  final ChildProfile child;
  const StoryLibraryScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FF),
      appBar: AppBar(
        title: const Text("MAGIC STORIES", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.childNavy,
        elevation: 0,
      ),
      body: StreamBuilder<List<KidStory>>(
        stream: db.streamStories(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final stories = snapshot.data!;

          if (stories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_stories_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  Text(child.language == "Arabic" ? "لا توجد قصص بعد!" : "No stories in the library yet!", 
                    style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1, // Full width cards for better visuals
              mainAxisSpacing: 20,
              childAspectRatio: 1.4,
            ),
            itemCount: stories.length,
            itemBuilder: (context, index) {
              return FadeInUp(
                delay: Duration(milliseconds: index * 100),
                child: _buildStoryCard(context, stories[index]),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStoryCard(BuildContext context, KidStory story) {
    return GestureDetector(
      onTap: () => _openPlayer(context, story.youtubeId),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    child: Image.network(
                      "https://img.youtube.com/vi/${story.youtubeId}/maxresdefault.jpg",
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Image.network("https://img.youtube.com/vi/${story.youtubeId}/0.jpg", fit: BoxFit.cover),
                    ),
                  ),
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 30,
                    child: Icon(Icons.play_arrow_rounded, color: Colors.red, size: 40),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(story.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(story.category, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Text(story.duration, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _openPlayer(BuildContext context, String videoId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryPlayerScreen(videoId: videoId),
      ),
    );
  }
}

// A dedicated full-screen safe player
class StoryPlayerScreen extends StatefulWidget {
  final String videoId;
  const StoryPlayerScreen({super.key, required this.videoId});

  @override
  State<StoryPlayerScreen> createState() => _StoryPlayerScreenState();
}

class _StoryPlayerScreenState extends State<StoryPlayerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false, hideControls: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Colors.red,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}