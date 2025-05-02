class QuestModel {
  final String id;
  final String name;
  final String description;
  final int point;
  final String? imageUrl;
  
  QuestModel({
    required this.id,
    required this.name,
    required this.description,
    required this.point,
    this.imageUrl,
  });
  
  factory QuestModel.fromMap(Map<String, dynamic> map, String id) {
    return QuestModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      point: map['point'] ?? 0,
      imageUrl: map['imageUrl'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'point': point,
      'imageUrl': imageUrl,
    };
  }
} 