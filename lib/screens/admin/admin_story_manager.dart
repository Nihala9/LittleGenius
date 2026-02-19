import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/story_model.dart';
import '../../services/database_service.dart';
import '../../services/theme_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/admin_scaffold.dart';

class AdminStoryManager extends StatefulWidget {
  const AdminStoryManager({super.key});

  @override
  State<AdminStoryManager> createState() => _AdminStoryManagerState();
}

class _AdminStoryManagerState extends State<AdminStoryManager> {
  final _db = DatabaseService();

  // --- ROBUST YOUTUBE ID EXTRACTOR ---
  // Converts various URL formats into a clean 11-character ID
  String? _extractVideoId(String input) {
    input = input.trim();
    if (input.isEmpty) return null;

    // 1. If it's already a clean ID (11 chars, alphanumeric with - or _), return it
    final RegExp idRegex = RegExp(r'^[a-zA-Z0-9_-]{11}$');
    if (idRegex.hasMatch(input)) {
      return input;
    }

    // 2. Parse URL patterns
    try {
      Uri uri = Uri.parse(input);
      
      // Standard: youtube.com/watch?v=ID
      if (uri.queryParameters.containsKey('v')) {
        return uri.queryParameters['v'];
      } 
      // Shortened: youtu.be/ID
      else if (uri.host == 'youtu.be') {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      }
      // Embed: youtube.com/embed/ID
      else if (uri.pathSegments.contains('embed')) {
        return uri.pathSegments.last;
      }
      // Shorts: youtube.com/shorts/ID
      else if (uri.pathSegments.contains('shorts')) {
        return uri.pathSegments.last;
      }
    } catch (e) {
      return null; // Parsing failed
    }
    
    return null; // No ID found
  }

  void _showStoryDialog(ThemeService theme, {KidStory? existing}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? "");
    // If editing, show the full link for context, or just the ID
    final urlCtrl = TextEditingController(text: existing != null ? "https://youtu.be/${existing.youtubeId}" : "");
    final durationCtrl = TextEditingController(text: existing?.duration ?? "5 min");
    final categoryCtrl = TextEditingController(text: existing?.category ?? "General");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(existing == null ? "Add New Story" : "Edit Story",
            style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _input(titleCtrl, "Story Title", theme),
              const SizedBox(height: 15),
              _input(urlCtrl, "YouTube Link or ID", theme, hint: "Paste full link here"),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _input(durationCtrl, "Duration", theme, hint: "10 min")),
                  const SizedBox(width: 10),
                  Expanded(child: _input(categoryCtrl, "Category", theme, hint: "Animals")),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.oceanBlue),
            onPressed: () async {
              if (titleCtrl.text.isEmpty || urlCtrl.text.isEmpty) return;

              // 1. EXTRACT & VALIDATE ID
              final String? cleanId = _extractVideoId(urlCtrl.text);

              if (cleanId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Invalid YouTube Link! Please check the URL."),
                    backgroundColor: Colors.redAccent,
                  )
                );
                return;
              }

              // 2. CREATE MODEL
              final newStory = KidStory(
                id: existing?.id ?? '', // ID handled by Firebase for new
                title: titleCtrl.text.trim(),
                youtubeId: cleanId, // Save ONLY the ID
                duration: durationCtrl.text.trim(),
                category: categoryCtrl.text.trim(),
              );

              // 3. SAVE TO DB
              if (existing == null) {
                await _db.addStory(newStory);
              } else {
                // For simplicity, delete old and add new to update
                await _db.deleteStory(existing.id); 
                await _db.addStory(newStory);
              }
              
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("Save Story", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _input(TextEditingController c, String label, ThemeService theme, {String? hint}) {
    return TextField(
      controller: c,
      style: TextStyle(color: theme.textColor),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: theme.subTextColor.withOpacity(0.5)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: theme.bgColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context);

    return AdminScaffold(
      title: "Bedtime Story Library",
      breadcrumbs: const ["Home", "Stories"],
      body: Stack(
        children: [
          StreamBuilder<List<KidStory>>(
            stream: _db.streamStories(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final stories = snapshot.data ?? [];

              if (stories.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_library_outlined, size: 60, color: theme.subTextColor),
                      const SizedBox(height: 10),
                      Text("No stories added yet.", style: TextStyle(color: theme.subTextColor)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                itemCount: stories.length,
                itemBuilder: (context, index) {
                  final story = stories[index];
                  return Card(
                    color: theme.cardColor,
                    margin: const EdgeInsets.only(bottom: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: theme.borderColor)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(10),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        // Fetch Thumbnail from YouTube
                        child: Image.network(
                          "https://img.youtube.com/vi/${story.youtubeId}/0.jpg",
                          width: 80, height: 60, fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            width: 80, height: 60, color: Colors.grey.shade300,
                            child: const Icon(Icons.broken_image, size: 30),
                          ),
                        ),
                      ),
                      title: Text(story.title, style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)),
                      subtitle: Text("${story.duration} • ${story.category}\nID: ${story.youtubeId}", 
                        style: TextStyle(color: theme.subTextColor, fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blueAccent),
                            onPressed: () => _showStoryDialog(theme, existing: story),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _db.deleteStory(story.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          Positioned(
            bottom: 30, right: 30,
            child: FloatingActionButton.extended(
              onPressed: () => _showStoryDialog(theme),
              backgroundColor: Colors.redAccent,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Add Story", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}