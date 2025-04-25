class LeaderboardEntry {
  final String userId;
  final String username;
  final int points;
  final double wasteSaved;

  LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.points,
    required this.wasteSaved,
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      userId: map['userId'] as String,
      username: map['username'] as String,
      points: map['points'] as int,
      wasteSaved: (map['wasteSaved'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'points': points,
      'wasteSaved': wasteSaved,
    };
  }
} 