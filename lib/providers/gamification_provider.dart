import 'package:flutter/material.dart';
import '../models/quest_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class GamificationProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<QuestModel> _quests = [];
  List<UserModel> _leaderboard = [];
  bool _isLoading = false;
  String? _error;
  
  List<QuestModel> get quests => _quests;
  List<UserModel> get leaderboard => _leaderboard;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Load all quests
  void loadQuests() {
    _setLoading(true);
    
    _firestoreService.getAllQuests().then((quests) {
      _quests = quests;
      _setLoading(false);
    }).catchError((e) {
      _error = 'Gagal memuat data quest: $e';
      _setLoading(false);
    });
  }
  
  // Load leaderboard
  void loadLeaderboard() {
    _setLoading(true);
    
    _firestoreService.getLeaderboard().listen((users) {
      _leaderboard = users;
      _setLoading(false);
    }, onError: (e) {
      _error = 'Gagal memuat data leaderboard: $e';
      _setLoading(false);
    });
  }
  
  // Update user points
  Future<bool> updateUserPoints(String userId, int points) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _firestoreService.updateUserPoints(userId, points);
      
      return true;
    } catch (e) {
      _error = 'Gagal memperbarui poin pengguna: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Get user rank
  int getUserRank(String userId) {
    for (int i = 0; i < _leaderboard.length; i++) {
      if (_leaderboard[i].id == userId) {
        return i + 1;
      }
    }
    return 0;
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
} 