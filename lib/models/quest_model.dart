import 'package:cloud_firestore/cloud_firestore.dart';

class QuestModel {
  final String id; // Add id field
  final String title;
  final String description;
  final int points;
  final String questType; 
  final Map<String, dynamic> requirements; 
  final Map<String, dynamic> progress; 
  final String status; // 

  QuestModel({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.questType,
    required this.requirements,
    required this.progress,
    required this.status,
  });

  factory QuestModel.fromMap(Map<String, dynamic> map, String id) {
    return QuestModel(
      id: id,
      title: map['title'] ?? 'Untitled Quest',
      description: map['description'] ?? 'No description available.',
      points: (map['points'] is int) ? map['points'] : int.tryParse(map['points'].toString()) ?? 0,
      questType: map['questType'] ?? '',
      requirements: map['requirements'] ?? {},
      progress: map['progress'] ?? {},
      status: map['status'] ?? 'ongoing',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'points': points,
      'questType': questType,
      'requirements': requirements,
      'progress': progress,
      'status': status,
    };
  }

  bool isCompleted() {
    switch (questType) {
      case 'scan':
        return (progress['scanCount'] ?? 0) >= (requirements['scanCount'] ?? 0);
      case 'finish_meal':
        return (progress['mealsFinished'] ?? 0) >= (requirements['mealsRequired'] ?? 0);
      case 'daily_login':
        return (progress['consecutiveDays'] ?? 0) >= (requirements['daysRequired'] ?? 0);
      default:
        return false;
    }
  }

  Stream<bool> isCompletedStream(String userId, String questId) {
    final firestore = FirebaseFirestore.instance;

    return firestore
        .collection('users')
        .doc(userId)
        .collection('quests')
        .doc(questId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return false;

      final data = snapshot.data() ?? {};
      final progress = data['progress'] ?? {};
      final requirements = data['requirements'] ?? {};
      final questType = data['questType'] ?? '';

      switch (questType) {
        case 'scan':
          return (progress['scanCount'] ?? 0) >= (requirements['scanCount'] ?? 0);
        case 'finish_meal':
          return (progress['mealsFinished'] ?? 0) >= (requirements['mealsRequired'] ?? 0);
        case 'daily_login':
          return (progress['consecutiveDays'] ?? 0) >= (requirements['daysRequired'] ?? 0);
        default:
          return false;
      }
    });
  }

  QuestModel updateProgress(Map<String, dynamic> newProgress) {
    final updatedProgress = Map<String, dynamic>.from(progress);
    newProgress.forEach((key, value) {
      updatedProgress[key] = (updatedProgress[key] ?? 0) + value;
    });

    String newStatus = status;
    if (isCompleted() && status == 'ongoing') {
      newStatus = 'completed';
    }

    return QuestModel(
      id: id,
      title: title,
      description: description,
      points: points,
      questType: questType,
      requirements: requirements,
      progress: updatedProgress,
      status: newStatus,
    );
  }

  QuestModel claim() {
    if (status == 'completed') {
      return QuestModel(
        id: id,
        title: title,
        description: description,
        points: points,
        questType: questType,
        requirements: requirements,
        progress: progress,
        status: 'claimed',
      );
    }
    return this;
  }

  bool canBeClaimed() {
    return status == 'completed';
  }

  String getRealTimeStatus() {
    final isCompleted = requirements.entries.every((entry) =>
        (progress[entry.key] ?? 0) >= entry.value);

    if (isCompleted) {
      return 'completed';
    }
    return status; // Tetap gunakan status asli jika belum completed
  }
}