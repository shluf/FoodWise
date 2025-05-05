import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodwise/services/ai_service.dart';
import '../models/food_scan_model.dart';
import '../models/quest_model.dart';
import '../models/user_model.dart';
import '../models/leaderboard_entry_model.dart';

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
      // Fetch food scans for the user
      final foodScansSnapshot = await _firestore
          .collection('foodScans')
          .where('userId', isEqualTo: userId)
          .where('isDone', isEqualTo: true)
          .get();

      final foodScans = foodScansSnapshot.docs.map((doc) {
        return FoodScanModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Calculate summary data
      final Map<String, dynamic> summaryData = _calculateSummary(foodScans);

      // Save summary to Firestore
      await saveWeeklySummary(userId, summaryData);
    } catch (e) {
      print('Error generating and saving weekly summary: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _calculateSummary(List<FoodScanModel> foodScans) {
    // Example calculations based on the provided JSON structure
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

    // Example: Calculate total food waste
    double totalWeight = 0.0;
    for (var scan in foodScans) {
      for (var item in scan.foodItems) {
        totalWeight += item.remainingWeight ?? 0.0;

        // Categorize waste by type
        if (item.itemName.toLowerCase().contains('nasi') || item.itemName.toLowerCase().contains('rice')) {
          summary["wasteByCategory"]["Carbohydrate"] += item.remainingWeight ?? 0.0;
        } else if (item.itemName.toLowerCase().contains('ayam') || item.itemName.toLowerCase().contains('meat')) {
          summary["wasteByCategory"]["Protein"] += item.remainingWeight ?? 0.0;
        } else if (item.itemName.toLowerCase().contains('sayur') || item.itemName.toLowerCase().contains('vegetables')) {
          summary["wasteByCategory"]["Vegetables"] += item.remainingWeight ?? 0.0;
        }
      }
    }

    // Calculate total carbon emission
    summary["totalFoodWaste"]["totalWeight_gram"] = totalWeight;
    summary["totalFoodWaste"]["totalWeight_kg"] = totalWeight / 1000.0;
    summary["totalFoodWaste"]["totalCarbonEmission_kgCO2"] = (totalWeight / 1000.0) * 2.5;

    // Example: Add recommendations
    summary["generalUserRecommendations"].add({
      "userId": "exampleUserId",
      "eatingPattern": {
        "frequentWasteTime": "Lunch",
        "mostWastedItem": "Nasi",
        "averageWastePercentage": 11.6,
      },
      "suggestions": {
        "portionAdjustment": "Kurangi porsi nasi saat makan siang.",
        "foodTypeRecommendation": "Pilih makanan berbasis sayuran atau sup saat siang.",
        "behavioralTip": "Usahakan ambil porsi lebih kecil terlebih dahulu, dan tambah jika masih lapar.",
      },
    });

    // Example: Add top wasted food items
    summary["topWastedFoodItems"].add({
      "itemName": "Nasi",
      "totalRemainingWeight": 200.5,
      "totalOccurrences": 15,
    });

    return summary;
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

  Future<void> generateAndSaveWeeklySummaryWithAI(
      String userId, AIService aiService) async {
    try {
      // Fetch existing weekly summary
      // final weeklySummaryData = await getWeeklySummary(userId);

      // if (weeklySummaryData != null && weeklySummaryData['weekly_summary'] != null) {
      //   print('Weekly summary already exists for userId: $userId');
      //   print('Weekly Summary: ${weeklySummaryData['weekly_summary']}');
      //   print('Timestamp: ${weeklySummaryData['weekly_summary_timestamp']}');
      //   return;
      // }

      // Fetch food scans for the past 7 days
      final DateTime sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final foodScansSnapshot = await _firestore
          .collection('foodScans')
          .where('userId', isEqualTo: userId)
          .where('scanTime', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
          .get();

      final foodScans = foodScansSnapshot.docs.map((doc) {
        return FoodScanModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      if (foodScans.isEmpty) {
        print('No food scans found for the past 7 days.');
        return;
      }

      // Fetch user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        print('User data not found for userId: $userId');
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // Use AIService to generate the summary
      final Map<String, dynamic> summaryData =
          await aiService.generateWeeklySummaryFromGemini(foodScans, userData);

      // Save the summary to Firestore
      await saveWeeklySummary(userId, summaryData);
    } catch (e) {
      print('Error generating and saving weekly summary with AI: $e');
      rethrow;
    }
  }




}





