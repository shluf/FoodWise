import 'package:cloud_firestore/cloud_firestore.dart';
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
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return FoodScanModel.fromMap(doc.data(), doc.id);
          }).toList();
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
          .where('isDone', isEqualTo: true) // Perbaikan: gunakan 'isDone' bukan 'isFinished'
          .get();
      
      Map<DateTime, double> weeklyFoodWaste = {};
      
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
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
        var weight = (data['weight'] ?? 0).toDouble(); // Tambahkan nilai default 0
        
        if (userWasteSaved.containsKey(userId)) {
          userWasteSaved[userId] = userWasteSaved[userId]! + weight;
        } else {
          userWasteSaved[userId] = weight;
          
          var userDoc = await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            var userData = userDoc.data() as Map<String, dynamic>;
            usernames[userId] = userData['username'] as String? ?? 'Unknown'; // Nilai default 'Unknown'
            userPoints[userId] = userData['points'] as int? ?? 0; // Nilai default 0
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
}