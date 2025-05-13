import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/food_scan_provider.dart';
import '../../models/food_scan_model.dart';
import '../../widgets/food_comparison_result_widget.dart';
// Import DummyDataGenerator
import '../scan/food_waste_scan_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
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
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        // ===================== TEMPORARY DUMMY BUTTON START =====================
        // actions: [
        //   Padding(
        //     padding: const EdgeInsets.symmetric(horizontal: 8.0),
        //     child: TextButton(
        //       style: TextButton.styleFrom(
        //         backgroundColor: Colors.white, // Button background color
        //         shape: RoundedRectangleBorder(
        //           borderRadius: BorderRadius.circular(8),
        //         ),
        //       ),
        //       onPressed: () async {
        //         final generator = DummyDataGenerator();
        //         await generator.loadAndSaveDummyData();
        //         ScaffoldMessenger.of(context).showSnackBar(
        //           const SnackBar(content: Text('Dummy data uploaded to Firestore')),
        //         );
        //       },
        //       child: const Text(
        //         'Generate Dummy',
        //         style: TextStyle(
        //           color: Colors.black, // Changed to black
        //           fontWeight: FontWeight.bold,
        //         ),
        //       ),
        //     ),
        //   ),
        // ],
        // ===================== TEMPORARY DUMMY BUTTON END =====================
      ),
      body: foodScanProvider.isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : foodScanProvider.foodScans.isEmpty
              ? _buildEmptyState()
              : _buildFoodScansList(foodScanProvider.foodScans),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No scan history',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan your food to see history here',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFoodScansList(List<FoodScanModel> foodScans) {
    // Sort based on scan time, newest first
    final sortedScans = List<FoodScanModel>.from(foodScans)
      ..sort((a, b) => b.scanTime.compareTo(a.scanTime));
      
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedScans.length,
      itemBuilder: (context, index) {
        final scan = sortedScans[index];
        return _buildFoodScanCard(scan);
      },
    );
  }
  
  Widget _buildFoodScanCard(FoodScanModel scan) {
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(scan.scanTime);
    final hasAiAnalysis = scan.isDone && scan.aiRemainingPercentage != null;
    
    return GestureDetector(
      onTap: () {
        // If history item is clicked, show analysis results if available
        if (scan.isDone) {
          _showAnalysisDetails(scan);
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with AI badge if AI analysis exists
            Stack(
              children: [
                if (scan.imageUrl != null && scan.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: CachedNetworkImage(
                      imageUrl: scan.imageUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(color: Colors.black),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 180,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                  
                // AI badge if AI analysis exists
                if (hasAiAnalysis)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'AI',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scan.isDone ? Colors.grey[200] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          scan.isDone ? Icons.check_circle : Icons.warning,
                          color: scan.isDone ? Colors.green : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              scan.foodName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (scan.isDone && !scan.isEaten)
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.black),
                          onPressed: () => _editScan(scan),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoItem('Initial Weight', '${_calculateTotalWeight(scan).toStringAsFixed(1)} grams'),
                      if (scan.isDone)
                        _buildInfoItem('Remaining Weight', '${_calculateTotalRemainingWeight(scan).toStringAsFixed(1)} grams'),
                      _buildInfoItem(
                        'Status', 
                        scan.isDone ? (scan.isEaten ? 'Consumed' : 'Leftover') : 'Incomplete',
                        color: scan.isDone ? (scan.isEaten ? Colors.black : Colors.grey[700]) : Colors.grey[600],
                      ),
                    ],
                  ),
                  
                  // AI analysis information if available
                  if (hasAiAnalysis) ...[
                    const SizedBox(height: 12),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.black),
                        const SizedBox(width: 8),
                        const Text(
                          'AI Analysis',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Remaining: ${scan.aiRemainingPercentage!.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: 1 - (scan.aiRemainingPercentage! / 100),
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to view analysis details',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  
                  if (!scan.isDone) ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FoodWasteScanScreen(
                              foodScanId: scan.id,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        margin: EdgeInsets.zero,
                        color: Colors.grey[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info,
                                color: Colors.grey[700],
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'This food is not finished yet, please update once it\'s done',
                                  style: TextStyle(
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoItem(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  
  void _showAnalysisDetails(FoodScanModel scan) {
    // If there's no AI Remaining Percentage, there's no AI analysis
    if (scan.aiRemainingPercentage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No AI analysis results for this scan')),
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
          // Local file not needed as we already have the image URL from Firestore
        ),
      ),
    );
  }
  
  void _editScan(FoodScanModel scan) {
    if (scan.aiRemainingPercentage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No AI analysis results available for editing')),
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

  double _calculateTotalWeight(FoodScanModel scan) {
    if (scan.foodItems.isEmpty) {
      return 0.0;
    }
    return scan.foodItems.fold(0.0, (sum, item) => sum + item.weight);
  }

  double _calculateTotalRemainingWeight(FoodScanModel scan) {
    if (scan.foodItems.isEmpty) {
      return 0.0;
    }
    return scan.foodItems.fold(0.0, (sum, item) => sum + (item.remainingWeight ?? 0.0));
  }
}