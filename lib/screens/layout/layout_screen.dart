import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math' as math;

import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../home/home_screen.dart'; // Akan diubah nanti
import '../progress/progress_boarding_screen.dart';
import '../scan/scan_screen.dart';
import '../gamification/gamification_screen.dart';
import '../settings/profile_screen.dart'; // Import ProfileScreen
import 'package:palette_generator/palette_generator.dart'; // Import PaletteGenerator


class LayoutScreen extends StatefulWidget {
  const LayoutScreen({super.key});

  @override
  State<LayoutScreen> createState() => _LayoutScreenState();
}

class _LayoutScreenState extends State<LayoutScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  int _selectedQuestIndex = 1;
  Color? _dominantColor;
  int _userRank = 0;
  bool _isLoadingRank = true;
  StreamSubscription? _pointsSubscription;

  // Welcome animation controllers
  late AnimationController _welcomeAnimationController;
  late Animation<double> _welcomeFadeAnimation;
  late Animation<Offset> _welcomeSlideAnimation;
  bool _showWelcome = true;
  bool _mainContentReady = false;
  String _greeting = "Hello";

  // FAB Pulse animation
  late AnimationController _fabPulseController;
  late Animation<double> _fabPulseAnimation;

  @override
  void initState() {
    super.initState();
    _setGreetingByTimeOfDay();
    _initializeWelcomeAnimation();
    _initializeFabPulseAnimation();

    // Delay other initializations until welcome animation starts fading
    Future.delayed(const Duration(milliseconds: 300), () {
      _extractDominantColor();
      _initializeUserRank();
      _initializeQuests();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.validateSession();
    });
  }

  void _initializeFabPulseAnimation() {
     _fabPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fabPulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(
        parent: _fabPulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  // Method to set greeting based on time of day
  void _setGreetingByTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = "Good Morning";
    } else if (hour < 17) {
      _greeting = "Good Afternoon";
    } else {
      _greeting = "Good Evening";
    }
  }

   // Initialize the welcome animation
  void _initializeWelcomeAnimation() {
     _welcomeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _welcomeFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _welcomeAnimationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _welcomeSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _welcomeAnimationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Start the animation immediately
    _welcomeAnimationController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _mainContentReady = true;
          });
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              setState(() {
                _showWelcome = false;
              });
            }
          });
        }
      });
    });
  }

  Future<void> _initializeQuests() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    if (authProvider.user != null) {
      await firestoreService.initializeUserQuests(authProvider.user!.id);
    }
  }

   Future<void> _extractDominantColor() async {
     try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        const AssetImage('assets/images/background-pattern.png'),
      );
      if (mounted) {
        setState(() {
          _dominantColor = paletteGenerator.dominantColor?.color ?? Theme.of(context).primaryColor;
        });
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: _dominantColor,
            statusBarIconBrightness: ThemeData.estimateBrightnessForColor(_dominantColor ?? Theme.of(context).primaryColor) == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
          ),
        );
      }
    } catch (e) {
      print("Error extracting dominant color: $e");
      if (mounted) {
         setState(() {
          _dominantColor = Theme.of(context).primaryColor;
        });
         SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: _dominantColor,
            statusBarIconBrightness: Brightness.light,
          ),
        );
      }
    }
  }

   void _initializeUserRank() {
    final userId = Provider.of<AuthProvider>(context, listen: false).user?.id ?? '';
    if (userId.isNotEmpty) {
      
      final firestoreService = FirestoreService();
      _pointsSubscription = firestoreService.getUserLeaderboardStream(userId).listen((leaderboardData) {
        if (mounted) {
           final currentRank = (leaderboardData.isNotEmpty ? (leaderboardData[0]['rank'] ?? 0) : 0);
           final displayRank = currentRank > 99 ? 99 : currentRank;
           if (_userRank != displayRank || _isLoadingRank) {
              setState(() {
                _userRank = displayRank;
                _isLoadingRank = false;
              });
           }
        }
      }, onError: (e) {
        if (mounted) {
            setState(() {
              _isLoadingRank = false; // Stop loading on error
               _userRank = 0; // Reset rank or show error state
            });
         }
      });
    } else {
       if (mounted) {
          setState(() {
            _isLoadingRank = false; // No user ID, stop loading
             _userRank = 0; // Reset rank
          });
       }
    }
  }

  Widget _buildUserPointsDisplay(BuildContext context) {
     if (_isLoadingRank) {
      return TweenAnimationBuilder<int>(
        tween: IntTween(begin: 1, end: 3),
        duration: const Duration(milliseconds: 900),
        builder: (context, value, child) {
          String dots = '.' * value;
          return Text(
            dots,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          );
        },
      );
    }

    return Text(
      '$_userRank',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }


  @override
  void dispose() {
    _pointsSubscription?.cancel();
    _welcomeAnimationController.dispose();
    _fabPulseController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    } else if (index == 3) {
      setState(() {
        if (_selectedIndex != 3) {
            _selectedQuestIndex = 1;
        }
        _selectedIndex = index;
      });
    } else if (index != 2) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Widget _buildNavBarItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    // Placeholder index 2 untuk FAB
    if (index == 2) {
      return const SizedBox(width: 60); // Spacer untuk FAB
    }

    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 30,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleQuestLeaderboard() {
    setState(() {
      _selectedQuestIndex = _selectedQuestIndex == 0 ? 1 : 0;
      if (_selectedIndex != 3) {
        _selectedIndex = 3;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
     final List<Widget> screens = [
      const HomeScreenContent(),
      const ProgressBoardingScreen(),
      Container(),
      GamificationMainScreen(
        currentQuestIndex: _selectedQuestIndex,
        onFabPressed: _toggleQuestLeaderboard,
      ),
    ];


    return Scaffold(
      body: Stack(
        children: [
          if (_mainContentReady)
            Stack(
              children: [
                 Positioned.fill(
                  child: Container(color: Theme.of(context).colorScheme.background),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Image.asset(
                    'assets/images/background-pattern.png',
                    width: MediaQuery.of(context).size.width,
                    fit: BoxFit.cover,
                  ),
                ),
                SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       // Header Aplikasi Umum
                       Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                // Gambar logo Ahshaka
                                ClipOval(
                                  child: Image.asset(
                                    'assets/images/logo-ahshaka.png',
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Tulisan "Ahshaka"
                                Text(
                                  'Ahshaka',
                                  style: GoogleFonts.merriweather(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            // Ikon piala dan jumlah poin
                            GestureDetector(
                              onTap: () {
                                 setState(() {
                                  if (_selectedIndex == 3) {
                                     _selectedQuestIndex = _selectedQuestIndex == 0 ? 1 : 0;
                                  } else {
                                    _selectedQuestIndex = 0;
                                  }
                                  _selectedIndex = 3; 
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(50),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.emoji_events,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 2),
                                    _buildUserPointsDisplay(context), // Gunakan widget poin
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                       // Konten Layar Aktif
                       Expanded(
                         child: IndexedStack(
                          index: _selectedIndex,
                          children: screens,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

           // Welcome Overlay
           if (_showWelcome)
            AnimatedBuilder(
              animation: _welcomeAnimationController,
              builder: (context, child) {
                return Container(
                  color: Colors.white,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: FadeTransition(
                    opacity: _welcomeFadeAnimation,
                    child: SlideTransition(
                      position: _welcomeSlideAnimation,
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            // App logo
                            TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0.8, end: 1.0),
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.elasticOut,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: Image.asset(
                                    'assets/images/logo-ahshaka.png',
                                    width: 120,
                                    height: 120,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            // Welcome text
                            Text(
                              _greeting,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF226CE0),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Consumer<AuthProvider>(
                               builder: (context, authProvider, child) {
                                return Text(
                                  authProvider.user?.username ?? 'Friend',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF333333),
                                  ),
                                );
                              }
                            ),
                            const SizedBox(height: 32),
                            const Text(
                              "Let's reduce food waste together!",
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF666666),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
       // Bottom Navigation dan FAB (hanya tampil jika welcome screen hilang)
       floatingActionButton: !_showWelcome ? SizedBox(
        width: 60,
        height: 60,
        child: AnimatedBuilder(
          animation: _fabPulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _fabPulseAnimation.value,
              child: FloatingActionButton(
                heroTag: 'layout_fab',
                onPressed: () {
                  _fabPulseController.stop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ScanScreen()),
                  ).then((_) {
                     if (mounted) _fabPulseController.repeat(reverse: true);
                  });
                },
                backgroundColor: Theme.of(context).primaryColor,
                elevation: 8,
                shape: const CircleBorder(),
                child: Center(
                  child: Image.asset(
                    'assets/images/scan.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            );
          }
        ),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: !_showWelcome ? BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 10,
        clipBehavior: Clip.antiAlias,
        height: 100,
        child: SizedBox(
           height: 80,
           child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Flexible(
                      child: _buildNavBarItem(0, Icons.home, 'Home'),
                    ),
                    Flexible(
                      child: _buildNavBarItem(1, Icons.show_chart, 'Progress'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 80),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Flexible(
                      child: _buildNavBarItem(3, Icons.assignment, 'Quest'),
                    ),
                    Flexible(
                      child: _buildNavBarItem(4, Icons.settings, 'Setting'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ) : null,
    );
  }
}

