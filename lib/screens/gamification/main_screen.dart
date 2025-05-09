import 'package:flutter/material.dart';
import 'leaderboard_screen.dart';
import 'quest_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1; // Ubah nilai awal ke 0 untuk menjadikan Leaderboard default

  final List<Widget> _screens = [
    const LeaderboardScreen(),
    const QuestScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Buat latar belakang transparan

      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  _currentIndex = _currentIndex == 0 ? 1 : 0;
                });
              },
              backgroundColor: Theme.of(context).primaryColor,
              child: Icon(
                _currentIndex == 0 ? Icons.assignment : Icons.leaderboard,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
