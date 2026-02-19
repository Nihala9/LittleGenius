class KidStory {
  final String id;
  final String title;
  final String youtubeId;
  final String duration;
  final String category; // e.g., "Moral", "Animal", "Space"

  KidStory({required this.id, required this.title, required this.youtubeId, required this.duration, required this.category});

  factory KidStory.fromMap(Map<String, dynamic> data, String id) {
    return KidStory(
      id: id,
      title: data['title'] ?? '',
      youtubeId: data['youtubeId'] ?? '',
      duration: data['duration'] ?? '5 min',
      category: data['category'] ?? 'General',
    );
  }

  Map<String, dynamic> toMap() {
    return {'title': title, 'youtubeId': youtubeId, 'duration': duration, 'category': category};
  }
}