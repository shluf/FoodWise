import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/food_scan_provider.dart';
import '../../models/food_scan_model.dart';
import 'package:google_fonts/google_fonts.dart';

class ProgressBoardingScreen extends StatefulWidget {
  const ProgressBoardingScreen({super.key});

  @override
  State<ProgressBoardingScreen> createState() => _ProgressBoardingScreenState();
}

class _ProgressBoardingScreenState extends State<ProgressBoardingScreen> {
  String? _selectedBarData;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final foodScanProvider = Provider.of<FoodScanProvider>(context, listen: false);

      if (authProvider.user != null) {
        foodScanProvider.loadUserFoodScans(authProvider.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final foodScanProvider = Provider.of<FoodScanProvider>(context);

    // Calculate data for charts and statistics
    final weeklyWaste = _calculateWeeklyWaste(foodScanProvider.foodScans);
    final categoryWaste = _calculateCategoryWaste(foodScanProvider.foodScans);
    final totalWaste = _calculateTotalWaste(foodScanProvider.foodScans);
    final mostWastedItems = _getMostWastedItems(foodScanProvider.foodScans);

    return Scaffold(
      appBar: null,
      body: SafeArea(
        child: foodScanProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : foodScanProvider.foodScans.isEmpty
                ? const Center(child: Text('No food scan data available.'))
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
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
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
                                      maxY: weeklyWaste.values.reduce((a, b) => a > b ? a : b) + 50,
                                      barTouchData: BarTouchData(
                                        touchCallback: (event, response) {
                                          if (response != null && response.spot != null) {
                                            final touchedIndex = response.spot!.touchedBarGroupIndex;

                                            if (touchedIndex >= 0 && touchedIndex < weeklyWaste.entries.length) {
                                              // Get data based on index from weeklyWaste.entries
                                              final selectedEntry = weeklyWaste.entries.elementAt(touchedIndex);
                                              final selectedDate = selectedEntry.key;
                                              final wasteInGrams = selectedEntry.value.toStringAsFixed(2);

                                              // Format date to "1 April 2025"
                                              final date = DateTime.now().subtract(Duration(days: DateTime.now().weekday - selectedDate - 1));
                                              final formattedDate = '${date.day} ${_getMonthName(date.month)} ${date.year}';

                                              // Show data as overlay
                                              setState(() {
                                                _selectedBarData = 'Date: $formattedDate\nWaste Amount: $wasteInGrams grams';
                                              });

                                              // Remove overlay after a few seconds, reset if another bar is clicked
                                              Future.delayed(const Duration(seconds: 3), () {
                                                if (_selectedBarData == 'Date: $formattedDate\nWaste Amount: $wasteInGrams grams') {
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
                                        rightTitles: AxisTitles(
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
                                      gridData: FlGridData(show: true),
                                      borderData: FlBorderData(show: false),
                                      barGroups: weeklyWaste.entries.map((entry) {
                                        final isToday = entry.key == DateTime.now().weekday - 1; // Check if today
                                        return BarChartGroupData(
                                          x: entry.key,
                                          barRods: [
                                            BarChartRodData(
                                              fromY: 0,
                                              toY: entry.value.toDouble(),
                                              color: isToday ? Color(0xFF070707) : Color(0xFF226CE0), // Different color for today
                                              width: 24, // Thicker bar graph
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ],
                                          showingTooltipIndicators: [], // Remove numbers above the bars
                                        );
                                      }).toList(),
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
                      
                      // Food Waste Summary Section - Redesigned and translated
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
                              'Food Waste Summary',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Inter',
                                color: Color(0xFF070707),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width * 0.45, // Berikan ukuran eksplisit
                                    child: _buildSummaryCard(
                                      'Total Food Waste', 
                                      '${totalWaste.toStringAsFixed(2)} g',
                                      Icons.delete_outline,
                                      Color(0xFFE57373), // Light red
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width * 0.45, // Berikan ukuran eksplisit
                                    child: _buildSummaryCard(
                                      'Carbon Emissions', 
                                      '${(totalWaste * 2.5 / 1000).toStringAsFixed(2)} kg',
                                      Icons.cloud_outlined,
                                      Color(0xFF81C784), // Light green
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Waste by Category Section - Redesigned and translated
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
                              'Waste by Category',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Inter',
                                color: Color(0xFF070707),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...categoryWaste.entries.map((entry) => _buildProgressBar(
                              _translateCategory(entry.key), 
                              entry.value, 
                              totalWaste > 0 ? (entry.value / totalWaste) : 0,
                              _getCategoryColor(entry.key),
                            )),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Waste by Meal Time Section - Redesigned and translated
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
                            _buildMealTimeItem('Breakfast', '${(weeklyWaste[0] ?? 0).toStringAsFixed(2)} g'),
                            const SizedBox(height: 8),
                            _buildMealTimeItem('Lunch', '${(weeklyWaste[1] ?? 0).toStringAsFixed(2)} g'),
                            const SizedBox(height: 8),
                            _buildMealTimeItem('Dinner', '${(weeklyWaste[2] ?? 0).toStringAsFixed(2)} g'),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Waste by Day Section - Redesigned and translated
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
                        // child: Column(
                        //   crossAxisAlignment: CrossAxisAlignment.start,
                        //   children: [
                        //     const Text(
                        //       'Waste by Day',
                        //       style: TextStyle(
                        //         fontSize: 18,
                        //         fontWeight: FontWeight.w700,
                        //         fontFamily: 'Inter',
                        //         color: Color(0xFF226CE0),
                        //       ),
                        //     ),
                        //     const SizedBox(height: 16),
                        //     ...weeklyWaste.entries.map((entry) {
                        //       const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
                        //       return _buildDayWasteItem(days[entry.key], '${entry.value.toStringAsFixed(2)} g');
                        //     }),
                        //   ],
                        // ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Most Wasted Items Section - Redesigned and translated
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
                            ...mostWastedItems.take(3).map((item) => _buildWastedItemCard(
                              item['itemName'], 
                              '${item['weight'].toStringAsFixed(1)} g', 
                              '${item['occurrences']} times'
                            )),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Recommendations Section - Redesigned and translated
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
                              'Recommendations',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Inter',
                                color: Color(0xFF070707),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildRecommendationCard(
                              'Frequent Waste Time: Lunch',
                              [
                                'Reduce rice portion during lunch',
                                'Choose vegetable-based meals or soups',
                                'Start with a smaller portion, and add more if still hungry'
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
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
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                color: Colors.grey[900],
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
              color: Colors.grey[900],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayWasteItem(String day, String waste) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
              color: Colors.grey[800],
            ),
          ),
          Text(
            waste,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
              color: Colors.grey[900],
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
              color: Color(0xFFE57373).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
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
            style: TextStyle(
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
        color: Color(0xFF81C784).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF81C784).withOpacity(0.3)),
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
                Icon(
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
        return Color(0xFFFFB74D); // Orange
      case 'Protein':
        return Color(0xFF64B5F6); // Blue
      case 'Sayuran':
        return Color(0xFF81C784); // Green
      default:
        return Color(0xFF9575CD); // Purple
    }
  }

  // Original calculation methods - unchanged
  double _calculateTotalWeight(FoodScanModel scan) {
    if (scan.foodItems.isEmpty) {
      return 0.0;
    }
    return scan.foodItems.fold(0.0, (sum, item) => sum + item.weight);
  }

  Map<int, double> _calculateWeeklyWaste(List<FoodScanModel> foodScans) {
    final Map<int, double> weeklyWaste = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
    for (var scan in foodScans) {
      if (scan.isDone) {
        final day = scan.scanTime.weekday - 1; // Monday = 0, Sunday = 6
        double totalRemainingWeight = scan.foodItems.fold(0.0, (sum, item) => sum + (item.remainingWeight ?? 0.0));
        weeklyWaste[day] = weeklyWaste[day]! + totalRemainingWeight;
      }
    }
    return weeklyWaste;
  }

  Map<String, double> _calculateCategoryWaste(List<FoodScanModel> foodScans) {
    final Map<String, double> categoryWaste = {'Karbohidrat': 0, 'Protein': 0, 'Sayuran': 0};
    for (var scan in foodScans) {
      for (var item in scan.foodItems) {
        if (item.itemName.toLowerCase().contains('nasi') || item.itemName.toLowerCase().contains('rice')) {
          categoryWaste['Karbohidrat'] = categoryWaste['Karbohidrat']! + (item.remainingWeight ?? 0.0);
        } else if (item.itemName.toLowerCase().contains('ayam') || item.itemName.toLowerCase().contains('daging') || 
                  item.itemName.toLowerCase().contains('chicken') || item.itemName.toLowerCase().contains('meat')) {
          categoryWaste['Protein'] = categoryWaste['Protein']! + (item.remainingWeight ?? 0.0);
        } else if (item.itemName.toLowerCase().contains('sayur') || item.itemName.toLowerCase().contains('vegetables')) {
          categoryWaste['Sayuran'] = categoryWaste['Sayuran']! + (item.remainingWeight ?? 0.0);
        }
      }
    }
    return categoryWaste;
  }

  double _calculateTotalWaste(List<FoodScanModel> foodScans) {
    double totalWaste = 0.0;
    for (var scan in foodScans) {
      if (scan.isDone) {
        totalWaste += scan.foodItems.fold(0.0, (sum, item) => sum + (item.remainingWeight ?? 0.0));
      }
    }
    return totalWaste;
  }

  List<Map<String, dynamic>> _getMostWastedItems(List<FoodScanModel> foodScans) {
    final Map<String, Map<String, dynamic>> itemStats = {};
    for (var scan in foodScans) {
      for (var item in scan.foodItems) {
        if (item.remainingWeight != null && item.remainingWeight! > 0) {
          if (!itemStats.containsKey(item.itemName)) {
            itemStats[item.itemName] = {'weight': 0.0, 'occurrences': 0};
          }
          itemStats[item.itemName]!['weight'] += item.remainingWeight!;
          itemStats[item.itemName]!['occurrences'] += 1;
        }
      }
    }
    final sortedItems = itemStats.entries.toList()
      ..sort((a, b) => b.value['weight'].compareTo(a.value['weight']));
    return sortedItems.map((entry) => {'itemName': entry.key, ...entry.value}).toList();
  }

  String _getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
  }
}
