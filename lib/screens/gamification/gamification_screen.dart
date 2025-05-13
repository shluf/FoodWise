import 'package:flutter/material.dart';
import 'leaderboard_screen.dart';
import 'quest_screen.dart';

class GamificationMainScreen extends StatelessWidget {
  final int currentQuestIndex;
  final VoidCallback onFabPressed;

  GamificationMainScreen({
    super.key,
    required this.currentQuestIndex,
    required this.onFabPressed,
  });

  final List<Widget> _screens = [
    const LeaderboardScreen(),
    const QuestScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      body: Stack(
        children: [
          IndexedStack(
            index: currentQuestIndex,
            children: _screens,
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'gamification_fab',
              onPressed: onFabPressed,
              backgroundColor: Theme.of(context).primaryColor,
              child: Icon(
                currentQuestIndex == 0 ? Icons.assignment : Icons.leaderboard,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
