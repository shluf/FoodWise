import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart'; // Import the AuthProvider class

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  
  late final String _currentUserId;
  final ScrollController _scrollController = ScrollController();

  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _currentUserId = authProvider.user?.id ?? ''; // Get the logged-in user's ID
    if (_currentUserId.isEmpty) {
      debugPrint('No user is logged in.'); // Debug log if no user is logged in
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: firestoreService.getLeaderboardStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              debugPrint('Error in StreamBuilder: ${snapshot.error}');
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final leaderboardData = snapshot.data ?? [];
            leaderboardData.sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));

            return ListView(
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
                _buildLeaderboardTable(leaderboardData),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLeaderboardTable(List<Map<String, dynamic>> leaderboardData) {
    final currentUserIndex = leaderboardData.indexWhere((user) => user['id'] == _currentUserId);
    final currentUser = currentUserIndex != -1
        ? LeaderboardUser(
            id: leaderboardData[currentUserIndex]['id'],
            username: leaderboardData[currentUserIndex]['username'] ?? 'Unknown',
            points: leaderboardData[currentUserIndex]['points'] ?? 0,
            rank: currentUserIndex + 1,
          )
        : null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
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
              itemCount: leaderboardData.length,
              itemBuilder: (context, index) {
                final user = leaderboardData[index];
                return _buildLeaderboardRow(
                  rank: index + 1,
                  username: user['username'] ?? 'Unknown',
                  points: user['points'] ?? 0,
                  isCurrentUser: user['id'] == _currentUserId,
                );
              },
            ),
          ),
          
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
              child: currentUser != null
                  ? _buildCurrentUserRowWithHint(currentUser)
                  : const SizedBox.shrink(),
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
        SizedBox(
          width: 120, // Berikan lebar yang cukup untuk teks dan ikon
          child: Row(
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
        ),
      ],
    ),
  );
}

  Widget _buildLeaderboardRow({
    required int rank,
    required String username,
    required int points,
    required bool isCurrentUser,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white, // Highlight current user
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
              '$rank',
              style: TextStyle(
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                color: isCurrentUser ? Theme.of(context).primaryColor : Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Text(
              username,
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
                  '$points',
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
  final int rank;

  LeaderboardUser({
    required this.id,
    required this.username,
    required this.points,
    required this.rank,
  });
}