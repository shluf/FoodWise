class QuestModel {
  final String id;
  final String questName;
  final String description;
  final int pointsReward;
  final String? imageUrl;
  
  QuestModel({
    required this.id,
    required this.questName,
    required this.description,
    required this.pointsReward,
    this.imageUrl,
  });
  
  factory QuestModel.fromMap(Map<String, dynamic> map, String id) {
    return QuestModel(
      id: id,
      questName: map['questName'] ?? '',
      description: map['description'] ?? '',
      pointsReward: map['pointsReward'] ?? 0,
      imageUrl: map['imageUrl'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'questName': questName,
      'description': description,
      'pointsReward': pointsReward,
      'imageUrl': imageUrl,
    };
  }
} 