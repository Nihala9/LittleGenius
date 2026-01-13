class Concept {
  String id;
  String name;
  String category;
  double masteryThreshold;
  int retryThreshold;

  Concept({
    required this.id,
    required this.name,
    required this.category,
    this.masteryThreshold = 0.9,
    this.retryThreshold = 3,
  });

  factory Concept.fromMap(Map<String, dynamic> map, String docId) {
    return Concept(
      id: docId,
      name: map['name'] ?? '',
      category: map['category'] ?? 'Literacy',
      masteryThreshold: (map['masteryThreshold'] ?? 0.9).toDouble(),
      retryThreshold: (map['retryThreshold'] ?? 3).toInt(),
    );
  }
}