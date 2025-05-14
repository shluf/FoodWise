import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/food_scan_provider.dart';
import '../../models/food_scan_model.dart';
import '../history/history_screen.dart';
import '../calendar/calendar_screen.dart';
import '../scan/scan_screen.dart';
import '../scan/food_waste_scan_screen.dart';
import '../../services/firestore_service.dart';
import '../../widgets/food_comparison_result_widget.dart';
import '../../widgets/scan/result_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import 'dart:async';

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

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> with TickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  String? _randomAIInsight;
  final List<AnimationController> _dayAnimationControllers = [];
  final List<Animation<double>> _dayScaleAnimations = [];
  final TextEditingController _editItemNameController = TextEditingController();
  final TextEditingController _editItemWeightController = TextEditingController();
  bool _showAddItemFormState = false;
  bool _showAddFoodItemFormState = false;

  @override
  void initState() {
    super.initState();

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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final foodScanProvider = Provider.of<FoodScanProvider>(context, listen: false);
      final firestoreService = FirestoreService();

      if (authProvider.user != null) {
        foodScanProvider.loadUserFoodScans(authProvider.user!.id);
        foodScanProvider.loadWeeklyFoodWaste(authProvider.user!.id);
        await firestoreService.generateAndSaveWeeklySummary(authProvider.user!.id);
        _loadRandomAIInsight();
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _dayAnimationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadRandomAIInsight() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!mounted || authProvider.user == null) return;

    final firestoreService = FirestoreService();

    try {
      final docSnapshot = await firestoreService.getWeeklySummaryStream(authProvider.user!.id).first;

      if (!mounted) return;

      final weeklySummary = docSnapshot.data()?['weekly_summary'];

      if (weeklySummary != null) {
        final recommendations = weeklySummary['generalUserRecommendations'] as List<dynamic>?;

        if (recommendations != null && recommendations.isNotEmpty) {
          final firstRecommendation = recommendations[0];

          final allInsights = <String>[];
          final facts = firstRecommendation['facts'] as Map<String, dynamic>?;
          if (facts != null) {
            facts.forEach((key, value) {
              if (value is String && value.isNotEmpty && value != 'No data') {
                allInsights.add(value);
              }
            });
          }

          final suggestions = firstRecommendation['suggestions'] as Map<String, dynamic>?;
          if (suggestions != null) {
            suggestions.forEach((key, value) {
              if (value is String && value.isNotEmpty && value != 'No suggestion') {
                allInsights.add(value);
              }
            });
          }

          if (allInsights.isNotEmpty) {
            final random = math.Random();
            if (mounted) {
              setState(() {
                _randomAIInsight = allInsights[random.nextInt(allInsights.length)];
              });
            }
          } else {
            if (mounted) {
              setState(() {
                _randomAIInsight = null;
              });
            }
          }
        } else {
          if (mounted) {
            setState(() {
              _randomAIInsight = null;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _randomAIInsight = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading AI insight in HomeScreenContent: $e');
      if (mounted) {
        setState(() {
          _randomAIInsight = "Could not load insight.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildHomeContent(context);
  }

  Widget _buildHomeContent(BuildContext context) {
    final foodScanProvider = Provider.of<FoodScanProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    final selectedDateScans = _getScansForSelectedDate(foodScanProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScrollableDayCircles(context, foodScanProvider),

          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
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
                  Color(0xFF226CE0),
                  Color(0xFF3980E9),
                  Color(0xFF5295F3),
                ],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
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

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                        
                        Container(
                          margin: const EdgeInsets.only(top: 20),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: _loadRandomAIInsight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(26),
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

          SizedBox(
            height: 190,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width - 32,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(right: 16),
                  clipBehavior: Clip.none,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
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
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.play_circle_fill),
                          label: const Text('Watch the Explanation'),
                          onPressed: () => _launchYoutubeVideo('https://youtu.be/wgLuXvtaLyQ?si=0sIDH6tfSXAKt17I'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width - 32,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
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
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.play_circle_fill),
                          label: const Text('Watch the Explanation'),
                          onPressed: () => _launchYoutubeVideo('https://youtu.be/1MpfEeSem_4?si=MAaRCQM2Q-zqMd4v'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recently Logged',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
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
              
              if (selectedDateScans.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(26),
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
              
              if (selectedDateScans.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: selectedDateScans.length > 3 ? 3 : selectedDateScans.length,
                  itemBuilder: (context, index) {
                    final scan = selectedDateScans[index];
                    final formattedDate = DateFormat('HH:mm').format(scan.scanTime);

                    return GestureDetector(
                      onTap: () {
                        if (!scan.isDone) {
                          if (scan.imageUrl != null) {
                            final weightController = TextEditingController(text: _calculateTotalWeight(scan).toString());
                            
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return StatefulBuilder(
                                    builder: (context, setState) => ResultView(
                                      image: null,
                                      imageUrl: scan.imageUrl,
                                      isRemainingFoodScan: false,
                                      originalScan: scan,
                                      foodName: scan.foodName,
                                      scanResult: null,
                                      carbonFootprint: 0.0,
                                      foodItems: scan.foodItems,
                                      potentialFoodWasteItems: scan.potentialFoodWasteItems ?? [],
                                      isEaten: false,
                                      isSaving: false,
                                      showAddItemForm: _showAddItemFormState,
                                      weightController: weightController,
                                      newItemNameController: _editItemNameController,
                                      newItemWeightController: _editItemWeightController,
                                      formatTime: (time) => DateFormat('HH:mm').format(time),
                                      formatDuration: _formatDuration,
                                      calculateTotalOriginalWeight: () => _calculateTotalWeight(scan),
                                      calculatePercentageRemaining: () => 100.0,
                                      onIsEatenChanged: (_) {},
                                      onWeightChanged: (value) => _onWeightChanged(value, scan, setState),
                                      toggleAddFoodItemForm: () => _toggleAddFoodItemForm(scan, setState),
                                      addNewFoodItem: () => _addNewFoodItem(scan, setState),
                                      updateFoodItemWeight: (index, weight) => _updateFoodItemWeight(scan, index, weight),
                                      removeFoodItem: (index) => _removeFoodItem(scan, index),
                                      toggleAddItemForm: () => _toggleAddItemForm(setState),
                                      addNewWasteItem: () => _addNewWasteItem(scan, setState),
                                      removeWasteItem: (index) => _removeWasteItem(scan, index),
                                      resetScan: () => _resetEditScan(scan),
                                      saveFoodScan: () => _saveFoodScanEdit(scan, weightController),
                                      onBackPressed: () => Navigator.pop(context),
                                      scanTime: scan.scanTime,
                                      count: scan.count ?? 1,
                                      onCountChanged: (newCount) async {
                                        final updatedScan = scan.copyWith(count: newCount);
                                        await _updateFoodScan(updatedScan, showSnackbar: false);
                                        setState(() {});
                                      },
                                    ),
                                  );
                                },
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ScanScreen(
                                  isRemainingFoodScan: false,
                                  originalScan: scan,
                                ),
                              ),
                            );
                          }
                        } else if (scan.isDone && scan.aiRemainingPercentage != null) {
                          _showAnalysisDetails(scan);
                        } else if (scan.isDone && scan.isEaten) {
                          _showFinishFoodDialog(context, scan);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
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
                              borderRadius: const BorderRadius.all(Radius.circular(26)),
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
                                        child: const Icon(Icons.broken_image, color: Colors.grey),
                                      ),
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        width: 150,
                                        height: 150,
                                        color: Colors.grey[200],
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            value: loadingProgress.expectedTotalBytes != null
                                                   ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                   : null,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                  : Container(
                                      width: 150,
                                      height: 150,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.fastfood, color: Colors.grey),
                                    ),
                            ),
                            
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                        const SizedBox(width: 8),
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
                                    
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4.0),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.local_fire_department,
                                                size: 24,
                                                color: Colors.black,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                "${_calculateTotalWeight(scan).toStringAsFixed(0)} gram",
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (scan.isDone)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2.0),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 4,
                                                  height: 18,
                                                  margin: const EdgeInsets.only(right: 6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.transparent,
                                                    border: Border(
                                                      left: BorderSide(
                                                        color: Colors.grey[300]!,
                                                        width: 3,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Icon(Icons.timer_outlined,
                                                  size: 14,
                                                  color: Colors.grey[500],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _formatDuration(scan.finishTime?.difference(scan.scanTime) ?? Duration.zero),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[500],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    
                                    if (scan.isDone)
                                      Align(
                                        alignment: Alignment.bottomLeft,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: scan.isEaten ? Colors.green.shade100 : Colors.red.shade100,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            scan.isEaten ? "Eaten" : "Wasted",
                                            style: TextStyle(
                                              color: scan.isEaten ? Colors.green.shade400 : Colors.red.shade400,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    
                                    if (!scan.isDone)
                                      SizedBox(
                                        width: double.infinity,
                                        height: 36,
                                        child: ElevatedButton(
                                          onPressed: () => _showFinishFoodDialog(context, scan),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.black,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            padding: EdgeInsets.zero,
                                          ),
                                          child: const Text("Finish", style: TextStyle(fontSize: 14)),
                                        ),
                                      ),
                                  ],
                                ),
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
    );
  }

  Widget _buildScrollableDayCircles(BuildContext context, FoodScanProvider foodScanProvider) {
    final days = ["M", "T", "W", "T", "F", "S", "S"];
    final today = DateTime.now();

    if (_dayAnimationControllers.isEmpty || _dayScaleAnimations.isEmpty) {
      return const SizedBox(height: 70);
    }

    final startDate = today.subtract(const Duration(days: 7));
    const itemCount = 15;

    const double itemWidth = 32.0 + 12.0;
    final initialScrollOffset = (itemCount / 2).floor() * itemWidth - (MediaQuery.of(context).size.width / 2) + itemWidth / 2;

    final ScrollController scrollController = ScrollController(
      initialScrollOffset: initialScrollOffset < 0 ? 0 : initialScrollOffset,
    );

    return Column(
      children: [
        SizedBox(
          height: 70,
          child: ListView.builder(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: itemCount + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(left: 16, right: 6, top: 30),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CalendarScreen()),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CustomPaint(
                            size: const Size(32, 32),
                            painter: DashedCircleBorderPainter(color: Colors.grey),
                            child: const Center(
                              child: Icon(Icons.more_horiz, size: 16, color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (index == itemCount + 1) {
                return Padding(
                  padding: const EdgeInsets.only(left: 6, right: 16, top: 30),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CalendarScreen()),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CustomPaint(
                            size: const Size(32, 32),
                            painter: DashedCircleBorderPainter(color: Colors.grey),
                            child: const Center(
                              child: Icon(Icons.more_horiz, size: 16, color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final adjustedIndex = index - 1;
              if (adjustedIndex < 0 || adjustedIndex >= _dayAnimationControllers.length) {
                return const SizedBox.shrink();
              }
              final animationController = _dayAnimationControllers[adjustedIndex];
              final scaleAnimation = _dayScaleAnimations[adjustedIndex];
              final day = startDate.add(Duration(days: adjustedIndex));

              final isToday = DateUtils.isSameDay(day, today);
              final isSelected = DateUtils.isSameDay(day, _selectedDate);
              final dayNumber = day.day.toString();
              final weekDayIndex = day.weekday - 1;
              final dayAbbr = days[weekDayIndex];
              final hasScans = _getScansForDay(foodScanProvider, day).isNotEmpty;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () {
                    animationController.forward().then((_) => animationController.reverse());
                    setState(() {
                      _selectedDate = day;
                    });
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayNumber,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 32,
                        width: 32,
                        child: ScaleTransition(
                          scale: scaleAnimation,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                       ? Theme.of(context).primaryColor
                                       : (isToday ? Theme.of(context).primaryColor.withOpacity(0.5) : Colors.grey.shade300),
                                    width: isSelected || isToday ? 2 : 1.5,
                                  ),
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
                              if (!isSelected && !isToday && !hasScans)
                                SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CustomPaint(
                                    painter: DashedCircleBorderPainter(
                                      color: Colors.grey.shade400,
                                      strokeWidth: 1,
                                    ),
                                  ),
                                ),
                              if (hasScans)
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: CustomPaint(
                                        painter: DashedCircleBorderPainter(
                                          color: Colors.grey.shade400,
                                          strokeWidth: 1,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: -2,
                                      left: 13,
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected ? Colors.white : Colors.green,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<FoodScanModel> _getScansForDay(FoodScanProvider provider, DateTime day) {
    return provider.foodScans.where((scan) =>
      DateUtils.isSameDay(scan.scanTime, day)
    ).toList();
  }
  
  List<FoodScanModel> _getScansForSelectedDate(FoodScanProvider provider) {
    return _getScansForDay(provider, _selectedDate);
  }
  
  String _calculateCarbonEmission(FoodScanProvider provider) {
    final selectedDateScans = _getScansForSelectedDate(provider);
    if (selectedDateScans.isEmpty) {
      return "Scan your meals to see your impact!";
    }

    double totalWeightWasted = 0;
    for (var scan in selectedDateScans) {
      if (scan.isDone && !scan.isEaten && scan.aiRemainingPercentage != null) {
        double initialWeight = _calculateTotalWeight(scan);
        double remainingWeight = initialWeight * (scan.aiRemainingPercentage ?? 0.0);
        totalWeightWasted += remainingWeight;
      } else if (scan.isDone && !scan.isEaten) {
        totalWeightWasted += _calculateTotalWeight(scan);
      }
    }

    double carbonImpact = totalWeightWasted / 1000 * 2.5;

    if (carbonImpact > 0.01) {
      return "Your food waste today generated ~${carbonImpact.toStringAsFixed(1)} kg CO₂e.";
    } else if (selectedDateScans.any((s) => s.isDone && s.isEaten)){
      return "Great job reducing food waste today!";
    } else {
      return "Log your finished meals to track your CO₂ impact.";
    }
  }

  Future<void> _launchYoutubeVideo(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open video: $url')),
        );
      }
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
    return scan.foodItems.fold(0.0, (sum, item) => sum + (item.weight ?? 0.0));
  }
  
  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 1) {
      return '< 1 min';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes} min';
    } else if (duration.inHours < 24) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      if (minutes == 0) {
        return '$hours hr';
      } else {
        return '$hours hr ${minutes} min';
      }
    } else {
      final days = duration.inDays;
      final hours = duration.inHours.remainder(24);
      return '$days d $hours hr';
    }
  }

  void _showAnalysisDetails(FoodScanModel scan) {
    if (scan.aiRemainingPercentage == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(scan.foodName),
          content: Text(
              'This meal was marked as ${scan.isEaten ? "eaten" : "wasted"}. No detailed AI analysis is available for leftovers.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
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

  Future<void> _updateFoodScan(FoodScanModel updatedScan, {bool showSnackbar = true}) async {
    final foodScanProvider = Provider.of<FoodScanProvider>(context, listen: false);
    final success = await foodScanProvider.updateFoodScan(updatedScan);
    
    if (success && mounted && showSnackbar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data makanan berhasil diperbarui')),
      );
    }
  }
  
  void _toggleAddFoodItemForm(FoodScanModel scan, StateSetter setState) {
    setState(() {
      _showAddItemFormState = !_showAddItemFormState;
      
      if (_showAddItemFormState) {
        _editItemNameController.clear();
        _editItemWeightController.clear();
      }
    });
  }
  
  void _addNewFoodItem(FoodScanModel scan, StateSetter setState, {bool navigateBack = false}) async {
    if (_editItemNameController.text.isEmpty || _editItemWeightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan berat item harus diisi')),
      );
      return;
    }
    
    double? weight = double.tryParse(_editItemWeightController.text);
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berat harus berupa angka positif')),
      );
      return;
    }
    
    final updatedFoodItems = List<FoodItem>.from(scan.foodItems);
    updatedFoodItems.add(
      FoodItem(
        itemName: _editItemNameController.text,
        weight: weight,
        remainingWeight: null,
      ),
    );
    
    final updatedScan = scan.copyWith(
      foodItems: updatedFoodItems,
    );
    
    await _updateFoodScan(updatedScan, showSnackbar: false);
    
    setState(() {
      _showAddItemFormState = false;
      _editItemNameController.clear();
      _editItemWeightController.clear();
    });
    
    if (navigateBack && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item baru berhasil ditambahkan')),
      );
    }
  }
  
  void _updateFoodItemWeight(FoodScanModel scan, int index, double newWeight) async {
    if (index < 0 || index >= scan.foodItems.length) return;
    
    final updatedFoodItems = List<FoodItem>.from(scan.foodItems);
    
    final item = updatedFoodItems[index];
    updatedFoodItems[index] = FoodItem(
      itemName: item.itemName,
      weight: newWeight,
      remainingWeight: item.remainingWeight,
    );
    
    final updatedScan = scan.copyWith(
      foodItems: updatedFoodItems,
    );
    
    await _updateFoodScan(updatedScan);
  }
  
  void _removeFoodItem(FoodScanModel scan, int index) async {
    if (index < 0 || index >= scan.foodItems.length) return;
    
    final updatedFoodItems = List<FoodItem>.from(scan.foodItems);
    updatedFoodItems.removeAt(index);
    
    final updatedScan = scan.copyWith(
      foodItems: updatedFoodItems,
    );
    
    await _updateFoodScan(updatedScan);
  }
  
  void _resetEditScan(FoodScanModel scan) {
    Navigator.pop(context);
  }
  
  void _toggleAddItemForm(StateSetter setState) {
    setState(() {
      _showAddItemFormState = !_showAddItemFormState;
      if (_showAddItemFormState) {
        _editItemNameController.clear();
        _editItemWeightController.clear();
      }
    });
  }
  
  void _addNewWasteItem(FoodScanModel scan, StateSetter setState) async {
    if (_editItemNameController.text.isEmpty || _editItemWeightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan berat item harus diisi')),
      );
      return;
    }
    
    double? weight = double.tryParse(_editItemWeightController.text);
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berat harus berupa angka positif')),
      );
      return;
    }
    
    double estimatedEmission = weight * 0.01;
    
    final updatedWasteItems = List<PotentialFoodWasteItem>.from(scan.potentialFoodWasteItems ?? []);
    updatedWasteItems.add(
      PotentialFoodWasteItem(
        itemName: _editItemNameController.text,
        estimatedCarbonEmission: estimatedEmission,
      ),
    );
    
    final updatedScan = scan.copyWith(
      potentialFoodWasteItems: updatedWasteItems.isEmpty ? null : updatedWasteItems,
    );
    
    await _updateFoodScan(updatedScan);
    
    setState(() {
      _showAddItemFormState = false;
      _editItemNameController.clear();
      _editItemWeightController.clear();
    });
  }
  
  void _removeWasteItem(FoodScanModel scan, int index) async {
    if (scan.potentialFoodWasteItems == null || 
        index < 0 || 
        index >= scan.potentialFoodWasteItems!.length) return;
    
    final updatedWasteItems = List<PotentialFoodWasteItem>.from(scan.potentialFoodWasteItems!);
    updatedWasteItems.removeAt(index);
    
    final updatedScan = scan.copyWith(
      potentialFoodWasteItems: updatedWasteItems.isEmpty ? null : updatedWasteItems,
    );
    
    await _updateFoodScan(updatedScan);
  }
  
  void _onWeightChanged(String value, FoodScanModel scan, StateSetter setState) {
    final double? weight = double.tryParse(value);
    if (weight != null && weight >= 0) {
      setState(() {});
    }
  }
  
  void _saveFoodScanEdit(FoodScanModel scan, TextEditingController weightController) async {
    double? weight = double.tryParse(weightController.text);
    
    if (weight == null || weight < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan berat makanan yang valid')),
      );
      return;
    }
    
    final totalOriginalWeight = _calculateTotalWeight(scan);
    List<FoodItem> updatedFoodItems = [];
    
    if (totalOriginalWeight > 0) {
      updatedFoodItems = scan.foodItems.map((item) {
        final proportion = item.weight / totalOriginalWeight;
        final newWeight = weight! * proportion;
        return FoodItem(
          itemName: item.itemName,
          weight: newWeight,
          remainingWeight: item.remainingWeight,
        );
      }).toList();
    } else {
      updatedFoodItems = scan.foodItems;
    }
    
    final updatedScan = scan.copyWith(
      foodItems: updatedFoodItems,
    );
    
    await _updateFoodScan(updatedScan);
    
    if (mounted) {
      Navigator.pop(context);
    }
  }
}