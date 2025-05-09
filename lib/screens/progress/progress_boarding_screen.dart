import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/food_scan_provider.dart';
import '../../models/food_scan_model.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firestore_service.dart';
import '../../services/ai_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 

class ProgressBoardingScreen extends StatefulWidget {
  const ProgressBoardingScreen({super.key});

  @override
  State<ProgressBoardingScreen> createState() => _ProgressBoardingScreenState();
}

class _ProgressBoardingScreenState extends State<ProgressBoardingScreen> {
  String? _selectedBarData;
  final FirestoreService _firestoreService = FirestoreService();
  final AIService _aiService = AIService(dotenv.env['GEMINI_API_KEY']!);
  Map<String, dynamic>? _weeklySummary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _listenToWeeklySummary(); 

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final foodScanProvider = Provider.of<FoodScanProvider>(context, listen: false);

      if (authProvider.user != null) {
        foodScanProvider.loadUserFoodScans(authProvider.user!.id);
      }
    });
  }

  void _listenToWeeklySummary() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;

    if (userId != null) {
      _firestoreService.getWeeklySummaryStream(userId).listen((snapshot) {
        setState(() {
          _weeklySummary = snapshot.data()?['weekly_summary'];
          _isLoading = false;
        });

        // debugPrint('Real-time Weekly Summary Data:');
        // debugPrint(_weeklySummary.toString());
      }, onError: (e) {
        debugPrint('Error listening to weekly summary: $e');
        setState(() {
          _isLoading = false;
        });
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_weeklySummary == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, 
            crossAxisAlignment: CrossAxisAlignment.center, 
            children: [
              Text('No weekly summary data available.'),
            ],
          ),
        ),
      );
    }

    final foodScanProvider = Provider.of<FoodScanProvider>(context);
    
    // Extract data from weekly summary
    final foodWasteByDayOfWeek = _weeklySummary!['foodWasteByDayOfWeek'] as List<dynamic>;
    final foodWasteByMealTime = _weeklySummary!['foodWasteByMealTime'] as List<dynamic>;
    final totalFoodWaste = _weeklySummary!['totalFoodWaste'] as Map<String, dynamic>;
    final wasteByCategory = _weeklySummary!['wasteByCategory'] as Map<String, dynamic>;
    final topWastedFoodItems = (_weeklySummary!['topWastedFoodItems'] as List<dynamic>).take(3).toList();
    final generalUserRecommendations = _weeklySummary!['generalUserRecommendations'] as List<dynamic>;
    final mostFinishedItems = (_weeklySummary!['mostFinishedItems'] as List<dynamic>)
        .take(3)
        .toList(); 

    // Convert foodWasteByDayOfWeek to Map for the chart
    Map<int, double> weeklyWasteMap = {};
    for (var dayData in foodWasteByDayOfWeek) {
      int dayIndex = _getDayIndex(dayData['day']);
      weeklyWasteMap[dayIndex] = dayData['totalWasteGram'].toDouble();
    }

    // Calculate total waste amount
    final totalWaste = totalFoodWaste['totalWeight_gram'].toDouble();
    
    // Create meal time waste map
    Map<String, double> mealTimeWaste = {};
    for (var mealData in foodWasteByMealTime) {
      mealTimeWaste[mealData['mealTime']] = mealData['averageRemainingPercentage'].toDouble();
    }

    // Get recommendations
    List<String> recommendations = [];
    if (generalUserRecommendations.isNotEmpty) {
      final recommendation = generalUserRecommendations[0];
      final suggestions = recommendation['suggestions'];
      recommendations = [
        suggestions['portionAdjustment'],
        suggestions['foodTypeRecommendation'],
        suggestions['behavioralTip'],
      ];
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            child: foodScanProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      const Text(
                        'Weekly Statistics',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Inter',
                          color: Color(0xFF000000),
                        ),
                      ),
                      const SizedBox(height: 16),
                    
                      // Food Waste Bar Chart
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Food Waste Statistics',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Inter',
                                color: Color(0xFF000000),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hi ${Provider.of<AuthProvider>(context).user!.username}, these are your food waste stats for this week',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Inter',
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Stack(
                              children: [
                                Container(
                                  height: MediaQuery.of(context).size.height * 0.5,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      maxY: weeklyWasteMap.values.isEmpty 
                                        ? 100 
                                        : weeklyWasteMap.values.reduce((a, b) => a > b ? a : b) + 50,
                                      barTouchData: BarTouchData(
                                        touchCallback: (event, response) {
                                          if (response != null && response.spot != null) {
                                            final touchedIndex = response.spot!.touchedBarGroupIndex;

                                            if (touchedIndex >= 0 && touchedIndex < 7) {
                                              // Find the day corresponding to this index
                                              final day = _getDayName(touchedIndex);
                                              final wasteInGrams = weeklyWasteMap[touchedIndex]?.toStringAsFixed(2) ?? '0.00';

                                              // Format date 
                                              final date = DateTime.now().subtract(Duration(days: DateTime.now().weekday - touchedIndex - 1));
                                              final formattedDate = '${date.day} ${_getMonthName(date.month)} ${date.year}';

                                              // Show data as overlay
                                              setState(() {
                                                _selectedBarData = 'Date: $formattedDate\nWaste Amount: $wasteInGrams g';
                                              });

                                              // Remove overlay after a few seconds
                                              Future.delayed(const Duration(seconds: 3), () {
                                                if (_selectedBarData == 'Date: $formattedDate\nWaste Amount: $wasteInGrams g') {
                                                  setState(() {
                                                    _selectedBarData = null;
                                                  });
                                                }
                                              });
                                            }
                                          }
                                        },
                                        touchTooltipData: BarTouchTooltipData(
                                          tooltipBgColor: Colors.transparent,
                                          tooltipPadding: EdgeInsets.zero,
                                          tooltipMargin: 0,
                                          getTooltipItem: (group, groupIndex, rod, rodIndex) => null, // Disable default tooltip
                                        ),
                                      ),
                                      titlesData: FlTitlesData(
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, meta) => Text(
                                              value.toInt().toString(),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontFamily: 'Inter',
                                                color: Color(0xFF000000),
                                              ),
                                            ),
                                            reservedSize: 30,
                                            interval: 200, // Fixed interval of 200 grams
                                          ),
                                        ),
                                        rightTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false), // Remove Y-axis on the right
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, meta) {
                                              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                              return Text(
                                                days[value.toInt()],
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontFamily: 'Inter',
                                                  color: Color(0xFF000000),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      gridData: const FlGridData(show: true),
                                      borderData: FlBorderData(show: false),
                                      barGroups: List.generate(7, (index) {
                                        final isToday = index == DateTime.now().weekday - 1; // Check if today
                                        return BarChartGroupData(
                                          x: index,
                                          barRods: [
                                            BarChartRodData(
                                              fromY: 0,
                                              toY: weeklyWasteMap[index]?.toDouble() ?? 0.0,
                                              color: isToday ? const Color(0xFF070707) : const Color(0xFF226CE0), // Different color for today
                                              width: 24, // Thicker bar graph
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ],
                                          showingTooltipIndicators: [], // Remove numbers above the bars
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                                if (_selectedBarData != null)
                                  Positioned(
                                    top: MediaQuery.of(context).size.height * 0.25, // Move overlay higher
                                    left: MediaQuery.of(context).size.width * 0.2,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _selectedBarData!,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'Inter',
                                            color: Colors.white, // White color for overlay
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Food Waste Summary Section
                      
                      // Carbon Emmisionsion Converter
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Carbon Emissions Converter',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Inter',
                                color: Color(0xFF070707),
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (totalFoodWaste['totalWeight_gram'] == 0)
                              const Center(
                                child: Text(
                                  'Belum ada makanan yang terbuang.',
                                  style: TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                              )
                            else
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                        ),
                                        child: SizedBox(
                                          width: 20, 
                                          height: 20, 
                                          child: Image.asset(
                                            'assets/images/fw_gram.png',
                                            fit: BoxFit.contain, 
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Total food waste: ${totalFoodWaste['totalWeight_gram'].toStringAsFixed(2)} gram',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            fontFamily: 'Inter',
                                            color: Color(0xFF070707),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                        ),
                                        child: SizedBox(
                                          width: 20, 
                                          height: 20, 
                                          child: Image.asset(
                                            'assets/images/fw_emissions.png',
                                            fit: BoxFit.contain, 
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Total carbon emissions from food waste: ${totalFoodWaste['totalCarbonEmission_kgCO2'].toStringAsFixed(3)} kg',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            fontFamily: 'Inter',
                                            color: Color(0xFF070707),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          "Let's aim to reduce that",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            fontStyle: FontStyle.italic, 
                                            fontFamily: 'Inter',
                                            color: Color(0xFF070707),
                                          ),
                                        ),
                                    ],
                                  )
                                ],
                              ),
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                      ),
                                      child: SizedBox(
                                        width: 20, 
                                        height: 20, 
                                        child: Image.asset(
                                          'assets/images/fw_gram.png',
                                          fit: BoxFit.contain, 
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Total food waste: ${totalFoodWaste['totalWeight_gram'] > 0 ? totalFoodWaste['totalWeight_gram'].toStringAsFixed(2) : "0.00"} gram',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          fontFamily: 'Inter',
                                          color: Color(0xFF070707),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                      ),
                                      child: SizedBox(
                                        width: 20, 
                                        height: 20, 
                                        child: Image.asset(
                                          'assets/images/fw_emissions.png',
                                          fit: BoxFit.contain, 
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Total carbon emissions from food waste: ${totalFoodWaste['totalCarbonEmission_kgCO2'] > 0 ? totalFoodWaste['totalCarbonEmission_kgCO2'].toStringAsFixed(3) : "0.000"} kg',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          fontFamily: 'Inter',
                                          color: Color(0xFF070707),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        "Let's aim to reduce that",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          fontStyle: FontStyle.italic, 
                                          fontFamily: 'Inter',
                                          color: Color(0xFF070707),
                                        ),
                                      ),
                                  ],
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Waste by Meal Time Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Waste by Meal Time',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Inter',
                                color: Color(0xFF070707),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (foodWasteByMealTime.isEmpty)
                              const Center(
                                child: Text(
                                  'Belum ada data waktu makan.',
                                  style: TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                              )
                            else
                              _buildMealTimeCharts(foodWasteByMealTime),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Most Wasted Items Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Most Wasted Items',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Inter',
                                color: Color(0xFF070707),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (topWastedFoodItems.isEmpty)
                              const Center(
                                child: Text(
                                  'Belum ada makanan yang terbuang.',
                                  style: TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                              )
                            else
                              ...topWastedFoodItems.take(3).map((item) => _buildWastedItemCard(
                                item['itemName'], 
                                '${item['totalRemainingWeight'].toStringAsFixed(1)} g', 
                                '${item['totalOccurrences']} times',
                              )),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Most Finished Items Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          const Text(
                            'Most Finished Items',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                              color: Color(0xFF070707),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (mostFinishedItems.isEmpty)
                            const Center(
                              child: Text(
                                'Belum ada makanan yang dihabiskan.',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            )
                          else
                            ...mostFinishedItems.map((item) => _buildFinishedItemCard(
                                  item['itemName'],
                                  '${item['finishedCount']} times',
                                )),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                      
                    // AI Recommendations Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Personalized Insights',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Inter',
                                  color: Color(0xFF070707),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF226CE0).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'AI',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Inter',
                                    color: Color(0xFF226CE0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (generalUserRecommendations.isEmpty)
                            const Center(
                              child: Text(
                                'Belum ada rekomendasi yang tersedia.',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Facts Section
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF226CE0).withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.lightbulb_outline,
                                            color: const Color(0xFF226CE0),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Your Eating Patterns',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Inter',
                                              color: const Color(0xFF226CE0),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      _buildFactItem(
                                        'Breakfast Consistency', 
                                        generalUserRecommendations[0]['facts']['breakfastConsistency'] ?? 'No data',
                                        Icons.free_breakfast
                                      ),
                                      _buildFactItem(
                                        'Meal Portion Control', 
                                        generalUserRecommendations[0]['facts']['mealPortionControl'] ?? 'No data',
                                        Icons.balance
                                      ),
                                      _buildFactItem(
                                        'Waste Reduction', 
                                        generalUserRecommendations[0]['facts']['wasteReduction'] ?? 'No data',
                                        Icons.eco
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Suggestions Section
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF81C784).withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.tips_and_updates_outlined,
                                            color: const Color(0xFF81C784),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Suggested Improvements',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Inter',
                                              color: const Color(0xFF81C784),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      _buildSuggestionItem(
                                        'Portion Adjustment',
                                        generalUserRecommendations[0]['suggestions']['portionAdjustment'] ?? 'No suggestion',
                                        Icons.restaurant
                                      ),
                                      _buildSuggestionItem(
                                        'Food Type Recommendation',
                                        generalUserRecommendations[0]['suggestions']['foodTypeRecommendation'] ?? 'No suggestion',
                                        Icons.eco
                                      ),
                                      _buildSuggestionItem(
                                        'Behavioral Tip',
                                        generalUserRecommendations[0]['suggestions']['behavioralTip'] ?? 'No suggestion',
                                        Icons.psychology
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                      
                    const SizedBox(height: 24),
                     
                      
                      const SizedBox(height: 24),

                      // Generate Summary Button
                      // ElevatedButton(
                      //   onPressed: () async {
                      //     final userId = Provider.of<AuthProvider>(context, listen: false).user?.id;
                      //     if (userId != null) {
                      //       try {
                      //         await _firestoreService.generateAndSaveWeeklySummaryWithAI(userId, _aiService);
                      //         ScaffoldMessenger.of(context).showSnackBar(
                      //           const SnackBar(content: Text('Summary generated successfully!')),
                      //         );
                      //         // Refresh data after generating summary
                      //         _fetchWeeklySummary();
                      //       } catch (e) {
                      //         ScaffoldMessenger.of(context).showSnackBar(
                      //           SnackBar(content: Text('Error generating summary: $e')),
                      //         );
                      //       }
                      //     } else {
                      //       ScaffoldMessenger.of(context).showSnackBar(
                      //         const SnackBar(content: Text('User not logged in.')),
                      //       );
                      //     }
                      //   },
                      //   child: const Text('Generate New Summary'),
                      // ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }


  // New UI helper methods
  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
              color: Colors.grey[900],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double value, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
                color: Colors.grey[800],
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)} g',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                color: Color.fromARGB(255, 92, 40, 57),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Container(
              height: 8,
              width: MediaQuery.of(context).size.width * 0.8 * percentage,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMealTimeItem(String mealTime, String value) {
    final double percentage = double.tryParse(value.replaceAll('%', '')) ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mealTime,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: percentage,
                    color: Colors.blue,
                    title: '${percentage.toStringAsFixed(1)}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 100 - percentage,
                    color: Colors.grey[300],
                    title: '',
                    radius: 50,
                  ),
                ],
                sectionsSpace: 0,
                centerSpaceRadius: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWastedItemCard(String itemName, String weight, String occurrences) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE57373).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.fastfood_outlined,
              color: Color(0xFFE57373),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                    color: Colors.grey[900],
                  ),
                ),
                Text(
                  'Wasted $occurrences',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Inter',
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            weight,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
              color: Color(0xFFE57373),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecommendationCard(String title, List<String> recommendations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF81C784).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF81C784).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 12),
          ...recommendations.map((recommendation) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF81C784),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendation,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Inter',
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
  // Helper methods for data translation
  String _translateCategory(String category) {
    switch (category) {
      case 'Karbohidrat':
        return 'Carbohydrates';
      case 'Protein':
        return 'Protein';
      case 'Sayuran':
        return 'Vegetables';
      default:
        return category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Karbohidrat':
        return const Color(0xFFFFB74D); // Orange
      case 'Protein':
        return const Color(0xFF64B5F6); // Blue
      case 'Sayuran':
        return const Color(0xFF81C784); // Green
      default:
        return const Color(0xFF9575CD); // Purple
    }
  }

  int _getDayIndex(String day) {
  switch (day) {
    case 'Monday': return 0;
    case 'Tuesday': return 1;
    case 'Wednesday': return 2;
    case 'Thursday': return 3;
    case 'Friday': return 4;
    case 'Saturday': return 5;
    case 'Sunday': return 6;
    default: throw ArgumentError('Invalid day: $day');
  }
}


  String _getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
  }

  String _getDayName(int dayIndex) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[dayIndex];
  }

  // Helper method to build the finished item card
  Widget _buildFinishedItemCard(String itemName, String finishedCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF81C784).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF81C784),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                    color: Colors.grey[900],
                  ),
                ),
                Text(
                  'Finished $finishedCount',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Inter',
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealTimeCharts(List<dynamic> foodWasteByMealTime) {
    final colors = [Color(0xFF000000), Color(0xFF000000), Color(0xFF000000)];
    
    // Define default meal times to always show even if data is empty
    final defaultMealTimes = ['Breakfast', 'Lunch', 'Dinner'];
    
    // Create a map of meal times to their percentage values from the data
    Map<String, double> mealTimePercentages = {};
    for (var entry in foodWasteByMealTime) {
      String mealTime = entry['mealTime'] as String;
      double percentage = double.tryParse(entry['averageRemainingPercentage'].toString()) ?? 0.0;
      mealTimePercentages[mealTime] = percentage;
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: defaultMealTimes.asMap().entries.map((entry) {
        final index = entry.key;
        final mealTime = entry.value;
        // Use the percentage from data if available, otherwise default to 0.0
        final percentage = mealTimePercentages[mealTime] ?? 0.0;

        return Column(
          children: [
            SizedBox(
              height: 100,
              width: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // The pie chart (only shown when percentage > 0)
                  if (percentage > 0)
                    PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: percentage,
                            color: colors[index % colors.length],
                            title: '${percentage.toStringAsFixed(1)}%',
                            radius: 40,
                            titleStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            color: const Color(0xFF226CE0),
                            value: 100 - percentage,
                            title: '',
                            radius: 40,
                          ),
                        ],
                        sectionsSpace: 0,
                        centerSpaceRadius: 0,
                      ),
                    ),
                  // If percentage is 0, show a full blue circle with "0.0%" text overlay
                  if (percentage == 0)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF226CE0),
                      ),
                    ),
                  // Always show the text for 0% cases
                  if (percentage == 0)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '0.0%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mealTime,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
                color: Colors.grey,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // Helper method to build a fact item
  Widget _buildFactItem(String title, String content, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF226CE0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF226CE0),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                    color: Color(0xFF616161),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Inter',
                    color: Color(0xFF212121),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build a suggestion item
  Widget _buildSuggestionItem(String title, String content, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF81C784).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF81C784),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                    color: Color(0xFF616161),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Inter',
                    color: Color(0xFF212121),
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
