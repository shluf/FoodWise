import 'package:cloud_firestore/cloud_firestore.dart';
// For logging debug messages
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';


class QuestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService(); 

  void monitorQuestProgress(String userId, String questId) async {
    debugPrint('Accessing user quests for userId: $userId');

    _firestoreService.getUserQuestsStream(userId).listen((quests) {
      bool questFound = false;

      debugPrint('User quests fetched:');
      for (var quest in quests) {
        debugPrint('Quest ID: ${quest.id}, Data: ${quest.toMap()}');

        if (quest.id == questId) {
          questFound = true;
          debugPrint('Found matching quest for questId: $questId');

          final progress = quest.progress;
          final requirements = quest.requirements;
          final questType = quest.questType;
          final status = quest.status;

          debugPrint('monitorQuestProgress triggered for questId: $questId');
          debugPrint('Current progress: $progress, Requirements: $requirements, Status: $status');

          bool isCompleted = false;

          switch (questType) {
            case 'scan':
              debugPrint('Checking completion for questId: $questId');
              debugPrint('Progress scanCount: ${progress['scanCount']}');
              debugPrint('Requirements scanCount: ${requirements['scanCount']}');
              isCompleted = (progress['scanCount'] ?? 0) >= (requirements['scanCount'] ?? 0);
              debugPrint('Is completed: $isCompleted');
              break;
            case 'finish_meal':
              isCompleted = (progress['mealsFinished'] ?? 0) >= (requirements['mealsRequired'] ?? 0);
              break;
            case 'daily_login':
              isCompleted = (progress['consecutiveDays'] ?? 0) >= (requirements['daysRequired'] ?? 0);
              break;
            default:
              debugPrint('Unknown questType: $questType');
              break;
          }

          if (status == 'claimed') {
            debugPrint('Quest status is "claimed" and cannot be updated for questId: $questId');
          } else if (isCompleted && status != 'completed') {
            debugPrint('Updating quest status to "completed" for questId: $questId');
            _firestoreService.updateQuestProgress(userId, questType, {}).then((_) {
              debugPrint('Quest status updated to "completed" for questId: $questId');
            }).catchError((error) {
              debugPrint('Error updating quest status for questId: $questId: $error');
            });
          } else if (!isCompleted && status != 'ongoing') {
            debugPrint('Updating quest status to "ongoing" for questId: $questId');
            _firestoreService.updateQuestProgress(userId, questType, {}).then((_) {
              debugPrint('Quest status updated to "ongoing" for questId: $questId');
            }).catchError((error) {
              debugPrint('Error updating quest status for questId: $questId: $error');
            });
          }
          break;
        }
      }

      if (!questFound) {
        debugPrint('No matching quest found for questId: $questId in the user quests.');
      }
    });
  }
}