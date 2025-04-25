import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/leaderboard_entry_model.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<LeaderboardEntry> _weeklyLeaderboard = [];
  List<LeaderboardEntry> _monthlyLeaderboard = [];
  List<LeaderboardEntry> _allTimeLeaderboard = [];
  bool _isLoading = true;
  UserModel? _currentUser;
  int _currentUserWeeklyRank = 0;
  int _currentUserMonthlyRank = 0;
  int _currentUserAllTimeRank = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLeaderboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _currentUser = authProvider.user;

      if (_currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final firestoreService = FirestoreService();

      // Ambil data leaderboard mingguan
      _weeklyLeaderboard = await firestoreService.getLeaderboardData(
        timeFrame: 'weekly',
        limit: 100,
      );

      // Ambil data leaderboard bulanan
      _monthlyLeaderboard = await firestoreService.getLeaderboardData(
        timeFrame: 'monthly',
        limit: 100,
      );

      // Ambil data leaderboard sepanjang masa
      _allTimeLeaderboard = await firestoreService.getLeaderboardData(
        timeFrame: 'all_time',
        limit: 100,
      );

      // Cari peringkat pengguna saat ini
      _findCurrentUserRanks();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading leaderboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _findCurrentUserRanks() {
    if (_currentUser == null) return;

    // Cari peringkat di leaderboard mingguan
    final weeklyIndex = _weeklyLeaderboard.indexWhere(
      (entry) => entry.userId == _currentUser!.id,
    );
    _currentUserWeeklyRank = weeklyIndex != -1 ? weeklyIndex + 1 : 0;

    // Cari peringkat di leaderboard bulanan
    final monthlyIndex = _monthlyLeaderboard.indexWhere(
      (entry) => entry.userId == _currentUser!.id,
    );
    _currentUserMonthlyRank = monthlyIndex != -1 ? monthlyIndex + 1 : 0;

    // Cari peringkat di leaderboard sepanjang masa
    final allTimeIndex = _allTimeLeaderboard.indexWhere(
      (entry) => entry.userId == _currentUser!.id,
    );
    _currentUserAllTimeRank = allTimeIndex != -1 ? allTimeIndex + 1 : 0;
  }

  Widget _buildLeaderboardTab(List<LeaderboardEntry> leaderboard, int currentUserRank) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (leaderboard.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada data leaderboard tersedia',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return Column(
      children: [
        // Informasi peringkat pengguna saat ini
        if (_currentUser != null && currentUserRank > 0)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Peringkat Anda: #$currentUserRank',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${leaderboard.firstWhere(
                    (entry) => entry.userId == _currentUser!.id,
                    orElse: () => LeaderboardEntry(
                      userId: '',
                      username: '',
                      points: 0,
                      wasteSaved: 0,
                    ),
                  ).points} poin',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        
        // Daftar leaderboard
        Expanded(
          child: ListView.builder(
            itemCount: leaderboard.length,
            itemBuilder: (context, index) {
              final entry = leaderboard[index];
              final isCurrentUser = _currentUser != null && entry.userId == _currentUser!.id;
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                color: isCurrentUser
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : null,
                child: ListTile(
                  leading: _buildRankWidget(index + 1),
                  title: Text(
                    entry.username,
                    style: TextStyle(
                      fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text('${entry.wasteSaved.toStringAsFixed(2)} kg limbah makanan disimpan'),
                  trailing: Text(
                    '${entry.points} poin',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRankWidget(int rank) {
    IconData icon;
    Color color;

    switch (rank) {
      case 1:
        icon = Icons.emoji_events;
        color = Colors.amber;
        break;
      case 2:
        icon = Icons.emoji_events;
        color = Colors.grey.shade400;
        break;
      case 3:
        icon = Icons.emoji_events;
        color = Colors.brown.shade300;
        break;
      default:
        return CircleAvatar(
          radius: 14,
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            '$rank',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
    }

    return Icon(
      icon,
      color: color,
      size: 30,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mingguan'),
            Tab(text: 'Bulanan'),
            Tab(text: 'Sepanjang Masa'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaderboardTab(_weeklyLeaderboard, _currentUserWeeklyRank),
          _buildLeaderboardTab(_monthlyLeaderboard, _currentUserMonthlyRank),
          _buildLeaderboardTab(_allTimeLeaderboard, _currentUserAllTimeRank),
        ],
      ),
    );
  }
} 