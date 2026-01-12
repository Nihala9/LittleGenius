class Concept {
  String id;
  String name;        // e.g., "Letter_A"
  String category;    // Literacy, Numeracy, General Knowledge
  String language;    // Universal support
  double masteryThreshold; // The BKT score needed to "finish" this concept (e.g., 0.9)

  Concept({
    required this.id,
    required this.name,
    required this.category,
    required this.language,
    this.masteryThreshold = 0.9,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'language': language,
      'masteryThreshold': masteryThreshold,
    };
  }

  factory Concept.fromMap(Map<String, dynamic> map, String docId) {
    return Concept(
      id: docId,
      name: map['name'] ?? '',
      category: map['category'] ?? 'Literacy',
      language: map['language'] ?? 'en-US',
      masteryThreshold: map['masteryThreshold'] ?? 0.9,
    );
  }
}