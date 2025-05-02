import 'package:flutter/material.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final String _currentUserId = '19'; // Dummy user ID untuk pengguna yang sedang login
  final ScrollController _scrollController = ScrollController();

  List<LeaderboardUser> _leaderboard = [
    LeaderboardUser(id: '1', username: 'Alice', points: 250),
    LeaderboardUser(id: '2', username: 'Bob', points: 300),
    LeaderboardUser(id: '3', username: 'Charlie', points: 150),
    LeaderboardUser(id: '4', username: 'Diana', points: 400),
    LeaderboardUser(id: '5', username: 'Eve', points: 100),
    LeaderboardUser(id: '6', username: 'Frank', points: 350),
    LeaderboardUser(id: '7', username: 'Grace', points: 200),
    LeaderboardUser(id: '8', username: 'Hank', points: 50),
    LeaderboardUser(id: '9', username: 'Ivy', points: 180),
    LeaderboardUser(id: '10', username: 'LoggedUser', points: 220), // Dummy data untuk pengguna yang sedang login
    LeaderboardUser(id: '11', username: 'Jack', points: 90),
    LeaderboardUser(id: '12', username: 'Karen', points: 310),
    LeaderboardUser(id: '13', username: 'Leo', points: 400),
    LeaderboardUser(id: '14', username: 'Mia', points: 275),
    LeaderboardUser(id: '15', username: 'Nina', points: 125),
    LeaderboardUser(id: '16', username: 'Oscar', points: 50),
    LeaderboardUser(id: '17', username: 'Paul', points: 320),
    LeaderboardUser(id: '18', username: 'Quinn', points: 180),
    LeaderboardUser(id: '19', username: 'Rachel', points: 140),
    LeaderboardUser(id: '20', username: 'Steve', points: 400),
    LeaderboardUser(id: '21', username: 'Tina', points: 90),
    LeaderboardUser(id: '22', username: 'Uma', points: 60),
    LeaderboardUser(id: '23', username: 'Victor', points: 200),
    LeaderboardUser(id: '24', username: 'Wendy', points: 300),
    LeaderboardUser(id: '25', username: 'Xander', points: 250),
    LeaderboardUser(id: '26', username: 'Yara', points: 150),
    LeaderboardUser(id: '27', username: 'Zane', points: 100),
  ];

  Future<void> _refreshLeaderboard() async {
    // Simulasi refresh leaderboard
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      // Update leaderboard data (contoh: shuffle data untuk simulasi perubahan)
      _leaderboard.shuffle();
      _leaderboard.sort((a, b) => b.points.compareTo(a.points));
      for (int i = 0; i < _leaderboard.length; i++) {
        _leaderboard[i].rank = i + 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sort leaderboard by points in descending order
    _leaderboard.sort((a, b) => b.points.compareTo(a.points));

    // Assign ranks based on sorted order
    for (int i = 0; i < _leaderboard.length; i++) {
      _leaderboard[i].rank = i + 1; // Rank starts from 1
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: RefreshIndicator(
          onRefresh: _refreshLeaderboard,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                'Leaderboard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildLeaderboardTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardTable() {
    final currentUser = _leaderboard.firstWhere((user) => user.id == _currentUserId);
    final currentUserIndex = _leaderboard.indexWhere((user) => user.id == _currentUserId);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        // border: Border.all(color: Theme.of(context).primaryColor, width: 2),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    'Rank',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Username',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    'Point',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Scrollable leaderboard rows
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              itemCount: _leaderboard.length,
              itemBuilder: (context, index) {
                final user = _leaderboard[index];
                return _buildLeaderboardRow(user);
              },
            ),
          ),
          // Current user row at the bottom if rank is outside visible range
          if (currentUserIndex >= 10) // Tampilkan hanya jika peringkat pengguna di luar 10 besar
            GestureDetector(
              onTap: () {
                if (currentUserIndex != -1) {
                  _scrollController.animateTo(
                    currentUserIndex * 60.0, // Approximate height of each row
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: _buildCurrentUserRowWithHint(currentUser),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentUserRowWithHint(LeaderboardUser user) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '${user.rank}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              user.username,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          Row(
            
            children: [
              Icon(
                Icons.touch_app,
                color: Theme.of(context).primaryColor,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Tap to scroll',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardRow(LeaderboardUser user) {
    final isCurrentUser = user.id == _currentUserId;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: isCurrentUser ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '${user.rank}',
              style: TextStyle(
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                color: isCurrentUser ? Theme.of(context).primaryColor : Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Text(
              user.username,
              style: TextStyle(
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                color: isCurrentUser ? Theme.of(context).primaryColor : Colors.black,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.monetization_on,
                  color: Colors.amber,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${user.points}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                    color: isCurrentUser ? Theme.of(context).primaryColor : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LeaderboardUser {
  final String id;
  final String username;
  final int points;
  int rank;

  LeaderboardUser({
    required this.id,
    required this.username,
    required this.points,
    this.rank = 0, // Default rank is 0, will be assigned later
  });
}