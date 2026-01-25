class Concept {
  String id;
  String name;      // e.g., "Letter A"
  String category;  // e.g., "Alphabet", "Maths"
  int order;        // Determines position on the Learning Map

  Concept({required this.id, required this.name, required this.category, required this.order});

  factory Concept.fromMap(Map<String, dynamic> data, String id) {
    return Concept(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? 'General',
      order: data['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'category': category, 'order': order};
  }
}