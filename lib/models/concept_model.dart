class Concept {
  String id;
  String name;      // e.g., "Letter A"
  String category;  // e.g., "Alphabet", "Maths"
  int order;        // Determines position on the Learning Map
  bool isPublished;

  Concept({required this.id, required this.name, required this.category, required this.order, this.isPublished = false});

  factory Concept.fromMap(Map<String, dynamic> data, String id) {
    return Concept(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? 'General',
      order: data['order'] ?? 0,
      isPublished: data['isPublished'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'category': category, 'order': order, 'isPublished': isPublished};
  }
}