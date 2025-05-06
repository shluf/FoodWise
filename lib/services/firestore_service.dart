import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodwise/services/ai_service.dart';
import '../models/food_scan_model.dart';
import '../models/quest_model.dart';
import '../models/user_model.dart';
import '../models/leaderboard_entry_model.dart';
import 'package:flutter/material.dart';


class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Food Scans Collection
  // =====================

  Stream<List<FoodScanModel>> getUserFoodScans(String userId) {
    return _firestore
        .collection('foodScans')
        .where('userId', isEqualTo: userId)
        .orderBy('scanTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          return Future.wait(snapshot.docs.map((doc) async {
            return await FoodScanModel.fromMapAsync(doc.data(), doc.id);
          }).toList());
        });
  }
  
  Future<String> addFoodScan(FoodScanModel foodScan) async {
    try {
      DocumentReference docRef = await _firestore.collection('foodScans').add(foodScan.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding food scan: $e');
      rethrow;
    }
  }
  
  Future<void> updateFoodScan(FoodScanModel foodScan) async {
    try {
      await _firestore.collection('foodScans').doc(foodScan.id).update(foodScan.toMap());
    } catch (e) {
      print('Error updating food scan: $e');
      rethrow;
    }
  }
  
  Future<void> deleteFoodScan(String foodScanId) async {
    try {
      await _firestore.collection('foodScans').doc(foodScanId).delete();
    } catch (e) {
      print('Error deleting food scan: $e');
      rethrow;
    }
  }
  
  Future<Map<DateTime, double>> getTotalFoodWasteByWeek(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('foodScans')
          .where('userId', isEqualTo: userId)
          .where('isDone', isEqualTo: true)
          .get();
      
      Map<DateTime, double> weeklyFoodWaste = {};
      
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        if (data['scanTime'] is Timestamp) {
          DateTime scanTime = (data['scanTime'] as Timestamp).toDate();
          double weight = (data['weight'] ?? 0).toDouble();
          
          DateTime startOfWeek = DateTime(
            scanTime.year, 
            scanTime.month, 
            scanTime.day - scanTime.weekday + 1
          );
          
          if (weeklyFoodWaste.containsKey(startOfWeek)) {
            weeklyFoodWaste[startOfWeek] = weeklyFoodWaste[startOfWeek]! + weight;
          } else {
            weeklyFoodWaste[startOfWeek] = weight;
          }
        }
      }
      
      return weeklyFoodWaste;
    } catch (e) {
      print('Error getting total food waste by week: $e');
      return {};
    }
  }
  
  Stream<FoodScanModel?> getFoodScanById(String foodScanId) {
    return _firestore
        .collection('foodScans')
        .doc(foodScanId)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return FoodScanModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }
          return null;
        });
  }
  
  // Quests Collection
  // ================
  
  Stream<List<QuestModel>> getAllQuests() {
    return _firestore
        .collection('quests')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return QuestModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }
  
  // Users Collection 
  // ===============
  
  Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  Future<void> updateUserPoints(String userId, int points) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'points': FieldValue.increment(points)
      });
    } catch (e) {
      print('Error updating user points: $e');
      rethrow;
    }
  }
  
  Stream<List<UserModel>> getLeaderboard() {
    return _firestore
        .collection('users')
        .orderBy('points', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return UserModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }
  
  Future<List<LeaderboardEntry>> getLeaderboardData({
    required String timeFrame,
    int limit = 50,
  }) async {
    try {
      DateTime startDate;
      final now = DateTime.now();
      
      switch (timeFrame) {
        case 'weekly':
          startDate = DateTime(
            now.year, 
            now.month, 
            now.day - now.weekday + 1
          );
          break;
        case 'monthly':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'all_time':
        default:
          startDate = DateTime(2000, 1, 1);
          break;
      }
      
      final startTimestamp = Timestamp.fromDate(startDate);
      
      final foodScansQuery = await _firestore
        .collection('foodScans')
        .where('scanTime', isGreaterThanOrEqualTo: startTimestamp)
        .where('isFinished', isEqualTo: false)
        .get();
      
      Map<String, double> userWasteSaved = {};
      Map<String, int> userPoints = {};
      Map<String, String> usernames = {};
      
      for (var doc in foodScansQuery.docs) {
        var data = doc.data();
        var userId = data['userId'] as String;
        var weight = (data['weight'] ?? 0).toDouble();
        
        if (userWasteSaved.containsKey(userId)) {
          userWasteSaved[userId] = userWasteSaved[userId]! + weight;
        } else {
          userWasteSaved[userId] = weight;
          
          var userDoc = await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            var userData = userDoc.data() as Map<String, dynamic>;
            usernames[userId] = userData['username'] as String? ?? 'Unknown';
            userPoints[userId] = userData['points'] as int? ?? 0;
          }
        }
      }
      
      List<LeaderboardEntry> leaderboard = [];
      
      for (var userId in userWasteSaved.keys) {
        if (usernames.containsKey(userId)) {
          leaderboard.add(
            LeaderboardEntry(
              userId: userId,
              username: usernames[userId]!,
              points: userPoints[userId] ?? 0,
              wasteSaved: userWasteSaved[userId]!,
            ),
          );
        }
      }
      
      leaderboard.sort((a, b) => b.points.compareTo(a.points));
      
      if (leaderboard.length > limit) {
        leaderboard = leaderboard.sublist(0, limit);
      }
      
      return leaderboard;
    } catch (e) {
      print('Error getting leaderboard data: $e');
      return [];
    }
  }

  // Gamifikasi Collection
  // =====================
  
  Future<List<QuestModel>> getAllQuestsData() async {
    try {
      final snapshot = await _firestore.collection('quests').get();
      return snapshot.docs.map((doc) {
        return QuestModel.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      print('Error fetching quests data: $e');
      return [];
    }
  }

  // Weekly Summary Collection
  // =====================

  Future<void> saveWeeklySummary(String userId, Map<String, dynamic> summaryData) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'weekly_summary': summaryData,
        'weekly_summary_timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving weekly summary: $e');
      rethrow;
    }
  }

  Future<void> generateAndSaveWeeklySummary(String userId) async {
    try {
      // Fetch food scans for the user in real-time
      final foodScansStream = _firestore
          .collection('foodScans')
          .where('userId', isEqualTo: userId)
          .where('isDone', isEqualTo: true)
          .snapshots();

      await for (final snapshot in foodScansStream) {
        final foodScans = snapshot.docs.map((doc) {
          return FoodScanModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();


        // Calculate summary data
        final Map<String, dynamic> summaryData = _calculateSummary(foodScans);

        debugPrint('Weekly summary data: $summaryData');

        // Save summary to Firestore
        await saveWeeklySummary(userId, summaryData);
      }
    } catch (e) {
      print('Error generating and saving weekly summary: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _calculateSummary(List<FoodScanModel> foodScans) {
    final Map<String, dynamic> summary = {
      "generalUserRecommendations": [],
      "topWastedFoodItems": [],
      "foodWasteByMealTime": [],
      "foodWasteByDayOfWeek": [],
  
      "totalFoodWaste": {
        "totalWeight_gram": 0.0,
        "totalWeight_kg": 0.0,
        "totalCarbonEmission_kgCO2": 0.0,
      },
      "mostFinishedItems": [],
      "wasteByCategory": {
        "Carbohydrate": 0.0,
        "Protein": 0.0,
        "Vegetables": 0.0,
      },
    };

    debugPrint("Data foodScans untuk summary dengan panjang ${foodScans.length}:");
    for (var scan in foodScans) {
      debugPrint("Scan ID: ${scan.id}, Scan Time: ${scan.scanTime}, Food Items: ${scan.foodItems}");
      for(var item in scan.foodItems ?? []) {
        debugPrint("Item Name: ${item.itemName}, Weight: ${item.weight}, Remaining Weight: ${item.remainingWeight}");
      }
    }

    double totalWeight = 0.0;
    Map<String, double> categoryWaste = {"Carbohydrate": 0.0, "Protein": 0.0, "Vegetables": 0.0};
    Map<String, double> wasteByDay = {};
    Map<String, List<double>> wasteByMealTime = {"Breakfast": [], "Lunch": [], "Dinner": []};
    Map<String, int> finishedItemCount = {};
    Map<String, double> itemWasteWeight = {};
    Map<String, int> itemOccurrences = {};

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    for (var scan in foodScans) {
      if (scan.scanTime == null || scan.scanTime.isBefore(startOfWeek)) continue;

      final dayName = _getDayName(scan.scanTime.weekday);
      final mealTime = _categorizeMealTime(scan.scanTime);

      double mealTotalWeight = 0.0;
      double mealWasteWeight = 0.0;

      if (scan.foodItems != null) {
        for (var item in scan.foodItems!) {
          // Validasi null untuk item.itemName dan item.weight
          if (item.itemName == null || item.itemName!.isEmpty || item.weight == null) continue;

          final remainingWeight = item.remainingWeight ?? 0.0;
          final weight = item.weight!;

          mealTotalWeight += weight;
          mealWasteWeight += remainingWeight;

          // Validasi null untuk kategori
          final category = _categorizeByAI(item.itemName!);
          if (categoryWaste.containsKey(category)) {
            categoryWaste[category] = categoryWaste[category]! + remainingWeight;
          }

          // Track top wasted items
          itemWasteWeight[item.itemName!] = (itemWasteWeight[item.itemName!] ?? 0.0) + remainingWeight;
          itemOccurrences[item.itemName!] = (itemOccurrences[item.itemName!] ?? 0) + 1;

          // Track most finished items
          if (remainingWeight == 0) {
            finishedItemCount[item.itemName!] = (finishedItemCount[item.itemName!] ?? 0) + 1;
          }
        }
      }

      // Track waste by day
      wasteByDay[dayName] = (wasteByDay[dayName] ?? 0.0) + mealWasteWeight;

      // Track waste by meal time
      if (mealTotalWeight > 0) {
        wasteByMealTime[mealTime]?.add((mealWasteWeight / mealTotalWeight) * 100);
      }

      totalWeight += mealWasteWeight;
    }

    // Populate summary fields
    summary["totalFoodWaste"]["totalWeight_gram"] = totalWeight;
    summary["totalFoodWaste"]["totalWeight_kg"] = totalWeight / 1000.0;
    summary["totalFoodWaste"]["totalCarbonEmission_kgCO2"] = (totalWeight / 1000.0) * 2.5;

    summary["wasteByCategory"] = categoryWaste;

    summary["foodWasteByDayOfWeek"] = wasteByDay.entries
        .map((entry) => {"day": entry.key, "totalWasteGram": entry.value})
        .toList();

    summary["foodWasteByMealTime"] = wasteByMealTime.entries
        .map((entry) => {
              "mealTime": entry.key,
              "averageRemainingPercentage": entry.value.isNotEmpty
                  ? entry.value.reduce((a, b) => a + b) / entry.value.length
                  : 0.0
            })
        .toList();

    summary["topWastedFoodItems"] = itemWasteWeight.entries
        .map((entry) => {
              "itemName": entry.key,
              "totalRemainingWeight": entry.value,
              "totalOccurrences": itemOccurrences[entry.key] ?? 0
            })
        .toList()
        ..sort((a, b) => (b["totalRemainingWeight"] as double).compareTo(a["totalRemainingWeight"] as double))
        ..take(3);

    summary["mostFinishedItems"] = finishedItemCount.entries
        .map((entry) => {"itemName": entry.key, "finishedCount": entry.value})
        .toList()
        ..sort((a, b) => (b["finishedCount"] as int).compareTo(a["finishedCount"] as int));

    // Add recommendations using AI
    summary["generalUserRecommendations"] = _generateRecommendationsUsingAI(summary);

  

    return summary;
  }

  String _getDayName(int weekday) {
    const days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    return days[weekday - 1];
  }

  String _categorizeMealTime(DateTime time) {
    if (time.hour >= 5 && time.hour < 11) return "Breakfast";
    if (time.hour >= 11 && time.hour < 15) return "Lunch";
    return "Dinner";
  }

  String _categorizeByAI(String itemName) {
    if (itemName.toLowerCase().contains("rice")) return "Carbohydrate";
    if (itemName.toLowerCase().contains("chicken")) return "Protein";
    if (itemName.toLowerCase().contains("vegetable")) return "Vegetables";
    return "Others";
  }

  List<Map<String, dynamic>> _generateRecommendationsUsingAI(Map<String, dynamic> summary) {
    return [
      {
        "facts": {
          "breakfastConsistency": "You never skip breakfast, great job!",
          "mealPortionControl": "Your lunch portions are well-balanced.",
          "wasteReduction": "You've reduced food waste by 15% this week."
        },
        "suggestions": {
          "portionAdjustment": "Reduce portion size for lunch.",
          "foodTypeRecommendation": "Consider eating more vegetables.",
          "behavioralTip": "Avoid distractions while eating."
        }
      }
    ];
  }

  Future<Map<String, dynamic>?> getWeeklySummary(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return {
          'weekly_summary': data['weekly_summary'],
          'weekly_summary_timestamp': data['weekly_summary_timestamp'],
        };
      }
      return null;
    } catch (e) {
      print('Error fetching weekly summary: $e');
      return null;
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getWeeklySummaryStream(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots();
  }

}





