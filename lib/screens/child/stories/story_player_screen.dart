import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../utils/app_colors.dart';

class StoryPlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;

  const StoryPlayerScreen({super.key, required this.videoId, required this.title});

  @override
  State<StoryPlayerScreen> createState() => _StoryPlayerScreenState();
}

class _StoryPlayerScreenState extends State<StoryPlayerScreen> {
  YoutubePlayerController? _controller; // Nullable to handle errors safely

  @override
  void initState() {
    super.initState();
    
    // CLEAN THE ID AGAIN JUST IN CASE
    String cleanId = widget.videoId.trim();

    if (cleanId.isNotEmpty) {
      _controller = YoutubePlayerController(
        initialVideoId: cleanId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          disableDragSeek: true,
          loop: false,
          isLive: false,
          forceHD: false, // Set false to help with buffering issues
          enableCaption: false,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Invalid Video Link")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.childNavy,
        elevation: 0,
      ),
      body: Center(
        child: YoutubePlayer(
          controller: _controller!, // Force unwrap since we checked it above
          showVideoProgressIndicator: true,
          progressIndicatorColor: AppColors.childBlue,
          onEnded: (data) => Navigator.pop(context),
          // Handle Errors Gracefully inside the player
          onReady: () {
            print('Player is ready.');
          },
        ),
      ),
    );
  }
}