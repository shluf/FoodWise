import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/food_scan_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../models/food_scan_model.dart';
import '../history/history_screen.dart';
import '../calendar/calendar_screen.dart';
import '../scan/scan_screen.dart';
import '../settings/profile_screen.dart';
import '../scan/food_waste_scan_screen.dart';
import '../progress/progress_boarding_screen.dart';
import '../gamification/main_screen.dart';
import '../gamification/leaderboard_screen.dart';
import '../../services/firestore_service.dart';
import '../../services/ai_service.dart';
import '../../widgets/food_comparison_result_widget.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import 'dart:async'; // Add this import

// Menambahkan CustomPainter untuk garis putus-putus
class DashedCircleBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  
  DashedCircleBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    
    final double radius = math.min(size.width, size.height) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    
    // Menghitung jumlah dash
    const double dashLength = 3;
    const double gapLength = 3;
    final double dashCount = (2 * math.pi * radius) / (dashLength + gapLength) + 1;
    
    // Membuat dash
    for (int i = 0; i < dashCount.toInt(); i++) {
      final double startAngle = i * (dashLength + gapLength) / radius;
      final double endAngle = startAngle + dashLength / radius;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        endAngle - startAngle,
        false,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  Color? _dominantColor;
  DateTime _selectedDate = DateTime.now();
  final DateTime _firstDay = DateTime.now().subtract(const Duration(days: 6));
  final DateTime _lastDay = DateTime.now().add(const Duration(days: 1));
  String? _randomAIInsight; // Add this variable to store random insight
  int _userPoints = 0;
  bool _isLoadingPoints = true;
  StreamSubscription? _pointsSubscription;
  
  // Welcome animation controllers
  late AnimationController _welcomeAnimationController;
  late Animation<double> _welcomeFadeAnimation;
  late Animation<Offset> _welcomeSlideAnimation;
  bool _showWelcome = true;  // Changed from false to true initially
  bool _mainContentReady = false;  // New flag to control main content visibility
  String _greeting = "Hello";

  // FAB Pulse animation
  late AnimationController _fabPulseController;
  late Animation<double> _fabPulseAnimation;

  // Animation controllers for day circles
  final List<AnimationController> _dayAnimationControllers = [];
  final List<Animation<double>> _dayScaleAnimations = [];
  
  // Removing the tip carousel related variables and data

  @override
  void initState() {
    super.initState();
    
    // Initialize welcome animation first
    _setGreetingByTimeOfDay();
    
    // Initialize animation controllers
    _welcomeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Initialize FAB pulse animation controller
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

    _initializeWelcomeAnimation();
    
    // Delay other initializations until welcome animation is complete
    Future.delayed(const Duration(milliseconds: 300), () {
      _extractDominantColor();
      _initializeQuests();
      _loadRandomAIInsight();
      _initializeUserPoints();
      
      // Initialize animation controllers for day circles
      for (int i = 0; i < 15; i++) {
        final controller = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        );
        
        final scaleAnimation = Tween<double>(
          begin: 1.0,
          end: 1.2,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeInBack,
          ),
        );
        
        _dayAnimationControllers.add(controller);
        _dayScaleAnimations.add(scaleAnimation);
      }

      // Validasi sesi
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final foodScanProvider = Provider.of<FoodScanProvider>(context, listen: false);
        final gamificationProvider = Provider.of<GamificationProvider>(context, listen: false);
        final firestoreService = FirestoreService(); // Tambahkan instance FirestoreService

        authProvider.validateSession();

        if (authProvider.user != null) {
          foodScanProvider.loadUserFoodScans(authProvider.user!.id);
          foodScanProvider.loadWeeklyFoodWaste(authProvider.user!.id);
          gamificationProvider.loadLeaderboard();
          gamificationProvider.loadQuests();

          // Trigger generate and save weekly summary
          await firestoreService.generateAndSaveWeeklySummary(authProvider.user!.id);
        }
      });
    });
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
      // After animation completes, show main content and fade out welcome screen
      // Reduced the delay from 2 seconds to 0.8 seconds for a faster transition
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _mainContentReady = true;
          });
          
          // Reduced the fade-out delay from 500ms to 300ms
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

  @override
  void dispose() {
    // Dispose all animation controllers
    for (var controller in _dayAnimationControllers) {
      controller.dispose();
    }
    _pointsSubscription?.cancel(); // Cancel the subscription when the widget is disposed
    _welcomeAnimationController.dispose();
    _fabPulseController.dispose(); // Dispose the FAB pulse controller
    super.dispose();
  }

  // Add this new method to load a random AI insight
  Future<void> _loadRandomAIInsight() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final firestoreService = FirestoreService();

    if (authProvider.user != null) {
      try {
        final docSnapshot = await firestoreService.getWeeklySummaryStream(authProvider.user!.id).first;
        final weeklySummary = docSnapshot.data()?['weekly_summary'];
        
        if (weeklySummary != null) {
          final recommendations = weeklySummary['generalUserRecommendations'] as List<dynamic>?;
          
          if (recommendations != null && recommendations.isNotEmpty) {
            final firstRecommendation = recommendations[0];
            
            // Combine facts and suggestions into one list
            final allInsights = <String>[];
            
            // Add facts
            final facts = firstRecommendation['facts'] as Map<String, dynamic>?;
            if (facts != null) {
              facts.values.forEach((value) {
                if (value is String && value.isNotEmpty && value != 'No data') {
                  allInsights.add(value);
                }
              });
            }
            
            // Add suggestions
            final suggestions = firstRecommendation['suggestions'] as Map<String, dynamic>?;
            if (suggestions != null) {
              suggestions.values.forEach((value) {
                if (value is String && value.isNotEmpty && value != 'No suggestion') {
                  allInsights.add(value);
                }
              });
            }
            
            // Pick a random insight if available
            if (allInsights.isNotEmpty) {
              final random = math.Random();
              setState(() {
                _randomAIInsight = allInsights[random.nextInt(allInsights.length)];
              });
            }
          }
        }
      } catch (e) {
        debugPrint('Error loading AI insight: $e');
      }
    }
  }

  Future<void> _initializeQuests() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    if (authProvider.user != null) {
      await firestoreService.initializeUserQuests(authProvider.user!.id);
    }
  }

  Future<void> _extractDominantColor() async {
    final paletteGenerator = await PaletteGenerator.fromImageProvider(
      const AssetImage('assets/images/background-pattern.png'),
    );
    setState(() {
      _dominantColor = paletteGenerator.dominantColor?.color ?? Colors.transparent;
    });

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: _dominantColor, // Gunakan warna dominan
        statusBarIconBrightness: Brightness.light, // Gunakan ikon terang
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == 4) {
      // Buka profile screen sebagai layar terpisah
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // Add this method to initialize user points
  void _initializeUserPoints() {
    final userId = Provider.of<AuthProvider>(context, listen: false).user?.id ?? '';
    if (userId.isNotEmpty) {
      _pointsSubscription = FirestoreService().getUserPointsStream(userId).listen((points) {
        // Only update state if points actually changed
        if (_userPoints != points) {
          setState(() {
            _userPoints = points;
            _isLoadingPoints = false;
          });
        } else if (_isLoadingPoints) {
          // If points are the same but we're still loading, update loading state
          setState(() {
            _isLoadingPoints = false;
          });
        }
      }, onError: (e) {
        debugPrint('Error loading user points: $e');
        setState(() {
          _isLoadingPoints = false;
        });
      });
    } else {
      setState(() {
        _isLoadingPoints = false;
      });
    }
  }

  // Add this method to build the user points display
  Widget _buildUserPointsDisplay(BuildContext context) {
    if (_isLoadingPoints) {
      return const Text(
        '...',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      );
    }
    
    return Text(
      '$_userPoints',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildHomeContent(context),
      const ProgressBoardingScreen(),
      Container(), // Placeholder untuk tombol scan
      const MainScreen(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          // Show main content only when ready
          if (_mainContentReady)
            Stack(
              children: [
                // Gambar latar belakang
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
                      // Header dengan padding
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
                              );
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
                                  // Replace the StreamBuilder with a more efficient implementation
                                  // that only rebuilds when the points actually change
                                  _buildUserPointsDisplay(context),
                                ],
                              ),
                            ),
                          )
                          ],
                        ),
                      ),
                      // Konten utama tanpa padding
                      Expanded(
                        child: IndexedStack(
                          index: _selectedIndex == 2 ? 0 : _selectedIndex,
                          children: screens,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

          // Welcome overlay - always on top
          if (_showWelcome)
            AnimatedBuilder(
              animation: _welcomeAnimationController,
              builder: (context, child) {
                return Container(
                  color: Colors.white,  // Solid background instead of translucent
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
                            // App logo with bounce animation
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
                            // Welcome text that slides up
                            Text(
                              _greeting,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF226CE0),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              Provider.of<AuthProvider>(context).user?.username ?? 'Friend',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF333333),
                              ),
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
      // Only show bottom navigation and FAB when welcome screen is gone
      floatingActionButton: !_showWelcome ? SizedBox(
        width: 60, 
        height: 60,
        child: AnimatedBuilder(
          animation: _fabPulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _fabPulseAnimation.value,
              child: FloatingActionButton(
                heroTag: 'home',
                onPressed: () {
                  // Temporarily stop pulsing when pressed
                  _fabPulseController.stop();
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ScanScreen()),
                  ).then((_) {
                    // Resume pulsing animation when returning from scan screen
                    if (mounted) _fabPulseController.repeat(reverse: true);
                  });
                },
                backgroundColor: Theme.of(context).primaryColor,
                elevation: 8,
                shape: const CircleBorder(),
                child: Center( 
                  child: Image.asset(
                    'assets/images/scan.png',
                    width: 32, // Ukuran gambar ditingkatkan agar proporsional
                    height: 32, // Ukuran gambar ditingkatkan agar proporsional
                    fit: BoxFit.contain, // Pastikan gambar tidak terpotong
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
        clipBehavior: Clip.antiAlias, // Tambahkan ini untuk mencegah overflow
        height: 100,
        child: SizedBox(
          height: 80, // Tinggi ditingkatkan dari 60 ke 80
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Flexible( // Tambahkan Flexible untuk mencegah overflow
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

  Widget _buildNavBarItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;

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
              size: 30, // Ukuran ikon dikecilkan
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10, // Ukuran font teks dikecilkan
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    final foodScanProvider = Provider.of<FoodScanProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final firestoreService = FirestoreService();
    final aiService = AIService(dotenv.env['GEMINI_API_KEY']!); 
    
    // Mengambil scan makanan sesuai dengan tanggal yang dipilih
    final selectedDateScans = _getScansForSelectedDate(foodScanProvider);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              // Weekly Calendar di paling atas
              _buildScrollableDayCircles(context, foodScanProvider),
              
              const SizedBox(height: 16),
              
              // Creative Greeting Card with AI Insights - Integrated design with softer colors
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                      spreadRadius: 1,
                    ),
                  ],
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF226CE0), // Primary blue
                      Color(0xFF3980E9), // Lighter blue
                      Color(0xFF5295F3), // Even lighter blue
                    ],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Background design elements - softer light circles
                      Positioned(
                        top: -20,
                        right: -20,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -50,
                        left: -20,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                      ),
                      
                      // Main content with integrated design
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User greeting with AI tag - Integrated
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Avatar/icon - softer color
                                Container(
                                  width: 48,
                                  height: 48,
                                  margin: const EdgeInsets.only(right: 15),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome,
                                    color: Color(0xFF226CE0),
                                    size: 26,
                                  ),
                                ),
                                
                                // Greeting and tip content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Username with AI badge - inline
                                      Row(
                                        children: [
                                          Text(
                                            '${authProvider.user?.username ?? 'Friend'}, ',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontFamily: 'Inter',
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.25),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.lightbulb_outline,
                                                  color: Colors.white,
                                                  size: 12,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'AI',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      
                                      // The tip content
                                      Text(
                                        _randomAIInsight ?? _calculateCarbonEmission(foodScanProvider),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.5,
                                          color: Colors.white,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            // Bottom action area
                            Container(
                              margin: const EdgeInsets.only(top: 20),
                              child: Row(
                                children: [
                                  // Animated refresh button with softer colors
                                  GestureDetector(
                                    onTap: _loadRandomAIInsight,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.15),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.refresh_rounded,
                                            size: 16,
                                            color: Color(0xFF226CE0),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            "New Insight",
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF226CE0),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),

              // Video Educational Section
              SizedBox(
                height: 190,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Container(
                      width: 300,
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                'Food Waste Explained',
                                style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Why food waste is such a serious problem',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 60,
                                height: 60,
                                child: Image.asset(
                                  'assets/images/confused.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.play_circle_fill),
                                  label: const Text('Watch the Explanation'),
                                  onPressed: () => _launchYoutubeVideo('https://youtu.be/wgLuXvtaLyQ?si=0sIDH6tfSXAKt17I'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 300,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Food Waste Affects',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Food waste is the world\'s dumbest problem',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 60,
                                height: 60,
                                child: Image.asset(
                                  'assets/images/earth_guard.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.play_circle_fill),
                                  label: const Text('Watch the Explanation'),
                                  onPressed: () => _launchYoutubeVideo('https://youtu.be/1MpfEeSem_4?si=MAaRCQM2Q-zqMd4v'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),

              const SizedBox(height: 24),
              
              // Recently logged section - Menampilkan data sesuai tanggal yang dipilih
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recently Logged',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const HistoryScreen()),
                          );
                        },
                        child: Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Jika tidak ada data pada tanggal yang dipilih, tampilkan placeholder
                  if (selectedDateScans.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "You haven't uploaded any food",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Start tracking ${DateFormat('EEEE').format(_selectedDate)}'s meals by taking a quick picture.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Jika ada data pada tanggal yang dipilih, tampilkan datanya
                  if (selectedDateScans.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: selectedDateScans.length,
                      itemBuilder: (context, index) {
                        final scan = selectedDateScans[index];
                        final formattedDate = DateFormat('HH:mm').format(scan.scanTime);
                        
                        return GestureDetector(
                          onTap: () {
                            if (scan.isDone && scan.aiRemainingPercentage != null) {
                              _showAnalysisDetails(scan);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.all(Radius.circular(30)),
                                  child: scan.imageUrl != null 
                                    ? Image.network(
                                        scan.imageUrl!,
                                        width: 150,
                                        height: 150,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => 
                                          Container(
                                            width: 150,
                                            height: 150,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.fastfood),
                                          ),
                                    )
                                    : Container(
                                        width: 150,
                                        height: 150,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.fastfood, color: Colors.grey),
                                      ),
                                ),
                                
                                // Informasi makanan dan tombol
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header dengan informasi dan jam
                                      Padding(
                                        padding: const EdgeInsets.only(left: 12, top: 12, right: 12),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                scan.foodName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Colors.black,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                formattedDate,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // Informasi berat
                                      Padding(
                                        padding: const EdgeInsets.only(left: 12, top: 8, right: 12),
                                        child: Row(
                                          children: [
                                            Icon(Icons.local_fire_department, 
                                              size: 16, 
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "${_calculateTotalWeight(scan).toStringAsFixed(0)} gram",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      if (scan.isDone)
                                        Container(
                                          padding: const EdgeInsets.only(left: 12, top: 2, right: 12),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              left: BorderSide(
                                                color: Colors.grey[300]!,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.timer, 
                                                size: 12, 
                                                color: Colors.grey[500],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatDuration(scan.finishTime?.difference(scan.scanTime) ?? Duration.zero),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      
                                      // Status jika sudah selesai
                                      if (scan.isDone)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 12, top: 4, right: 12, bottom: 12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                scan.isEaten ? "Status: Eaten" : "Status: Wasted",
                                                style: TextStyle(
                                                  color: scan.isEaten ? Colors.green : Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      
                                      // Tombol Selesai jika belum selesai
                                      if (!scan.isDone)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8, top: 8, right: 8, bottom: 8),
                                          child: SizedBox(
                                            child: ElevatedButton(
                                              onPressed: () => _showFinishFoodDialog(context, scan),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.black,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                              ),
                                              child: const Text("Finish"),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableDayCircles(BuildContext context, FoodScanProvider foodScanProvider) {
    final days = ["M", "T", "W", "T", "F", "S", "S"];
    final today = DateTime.now();
    
    return Column(
      children: [
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 17, // 15 tanggal + 2 tombol navigasi
            itemBuilder: (context, index) {
              // Tombol navigasi di awal
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CalendarScreen()),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CustomPaint(
                            size: const Size(32, 32),
                            painter: DashedCircleBorderPainter(
                              color: Colors.grey,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.more_horiz,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              // Tombol navigasi di akhir
              if (index == 16) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CalendarScreen()),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CustomPaint(
                            size: const Size(32, 32),
                            painter: DashedCircleBorderPainter(
                              color: Colors.grey,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.more_horiz,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              // Item tanggal (index 1-15 dikonversi ke 0-14 untuk perhitungan tanggal)
              final adjustedIndex = index - 1;
              final animationController = _dayAnimationControllers[adjustedIndex];
              final scaleAnimation = _dayScaleAnimations[adjustedIndex];
              final day = today.subtract(Duration(days: 7 - adjustedIndex));
              final isToday = DateUtils.isSameDay(day, today);
              final isSelected = DateUtils.isSameDay(day, _selectedDate);
              final dayNumber = day.day.toString();
              final weekDay = day.weekday - 1;
              final dayAbbr = days[weekDay >= 0 && weekDay < 7 ? weekDay : 0];
              final hasScans = _getScansForDay(foodScanProvider, day).isNotEmpty;
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () {
                    // Play the animation when tapped
                    animationController.forward().then((_) => animationController.reverse());
                    
                    setState(() {
                      _selectedDate = day;
                    });
                  },
                  child: Column(
                    children: [
                      Text(
                        dayNumber,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 6),
                      ScaleTransition(
                        scale: scaleAnimation,
                        child: Stack(
                          children: [
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: Stack(
                                children: [
                                  if (!isSelected && !isToday)
                                    CustomPaint(
                                      size: const Size(32, 32),
                                      painter: DashedCircleBorderPainter(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                                      border: isToday || isSelected ? Border.all(
                                        color: isToday 
                                          ? Theme.of(context).primaryColor 
                                          : Theme.of(context).primaryColor,
                                        width: isToday ? 2 : 1,
                                      ) : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        dayAbbr,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected 
                                            ? Colors.white 
                                            : (isToday ? Theme.of(context).primaryColor : Colors.black87),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (hasScans && !isSelected)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            controller: ScrollController(
              initialScrollOffset: 8 * 44.0, // Posisikan hari ini di tengah
            ),
          ),
        ),
      ],
    );
  }

  
  List<FoodScanModel> _getScansForDay(FoodScanProvider provider, DateTime day) {
    return provider.foodScans.where((scan) => 
      scan.scanTime.year == day.year && 
      scan.scanTime.month == day.month && 
      scan.scanTime.day == day.day
    ).toList();
  }
  
  List<FoodScanModel> _getScansForSelectedDate(FoodScanProvider provider) {
    return _getScansForDay(provider, _selectedDate);
  }
  
  String _calculateCarbonEmission(FoodScanProvider provider) {
    final selectedDateScans = _getScansForSelectedDate(provider);
    if (selectedDateScans.isEmpty) {
      return "You haven't done anything, scan now to start!";
    }
    
    double totalWeightSaved = 0;
    for (var scan in selectedDateScans) {
      if (scan.isDone && scan.isEaten) {
        double totalWeight = _calculateTotalWeight(scan);
        totalWeightSaved += totalWeight;
      }
    }
    
    double carbonSaved = totalWeightSaved / 1000 * 2.5;
    
    if (carbonSaved > 0) {
      return "You have reduced ${carbonSaved.toStringAsFixed(1)} kg of CO₂ by reducing food waste!";
    } else {
      return "If you reduce food waste by 10%, you can reduce 0.5 kg of CO₂ every week!";
    }
  }

  Future<void> _launchYoutubeVideo(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      );
    } catch (e) {
      // Handle kasus ketika URL tidak dapat diluncurkan
      print('Could not launch $url: $e');
    }
  }

  void _showFinishFoodDialog(BuildContext context, FoodScanModel scan) {
    final firestoreService = FirestoreService();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.question_mark_rounded, size: 40, color: Colors.black),
              const Text(
                'Is it Finished?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Has this food run out or is there any left?',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.pop(context);

                        // Update sebagai selesai tanpa sisa
                        final foodScanProvider = Provider.of<FoodScanProvider>(context, listen: false);
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final updatedScan = scan.copyWith(
                          isDone: true,
                          isEaten: true,
                          finishTime: DateTime.now(),
                        );

                        await foodScanProvider.updateFoodScan(updatedScan);

                        // Trigger generate and save weekly summary
                        if (authProvider.user != null) {
                          await firestoreService.generateAndSaveWeeklySummary(authProvider.user!.id);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Finish',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);

                        // Navigate ke FoodWasteScanScreen untuk menggunakan AI perbandingan
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FoodWasteScanScreen(
                              foodScanId: scan.id,
                            ),
                          ),
                        );

                        // Trigger generate and save weekly summary
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        if (authProvider.user != null) {
                          await firestoreService.generateAndSaveWeeklySummary(authProvider.user!.id);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.auto_awesome, size: 20, color: Colors.white),
                      label: const Text('Scan Rest'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  double _calculateTotalWeight(FoodScanModel scan) {
    if (scan.foodItems.isEmpty) {
      return 0.0;
    }
    return scan.foodItems.fold(0.0, (sum, item) => sum + item.weight);
  }
  
  String _formatDuration(Duration duration) {
    if (duration.inHours < 1) {
      return '${duration.inMinutes} min';
    } else if (duration.inHours == 1) {
      return '1 hour';
    } else {
      return '${duration.inHours} hours';
    }
  }

  void _showAnalysisDetails(FoodScanModel scan) {
    // Jika tidak ada AI Remaining Percentage, berarti tidak ada analisis AI
    if (scan.aiRemainingPercentage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada hasil analisis AI untuk pemindaian ini')),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodComparisonResultWidget(
          foodScan: scan,
          remainingPercentage: scan.aiRemainingPercentage!,
          confidence: scan.aiConfidence ?? 0.5,
        ),
      ),
    );
  }
}