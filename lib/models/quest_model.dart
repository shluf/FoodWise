class QuestModel {
  final String title;
  final String description;
  final int points;

  QuestModel({
    required this.title,
    required this.description,
    required this.points,
  });

  factory QuestModel.fromMap(Map<String, dynamic> map, String? id) {
    return QuestModel(
      title: map['title'] ?? 'Untitled Quest', // Default value for title
      description: map['description'] ?? 'No description available.', // Default value for description
      points: (map['points'] is int) ? map['points'] : int.tryParse(map['points'].toString()) ?? 0, // Handle int or string
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'points': points,
    };
  }
}