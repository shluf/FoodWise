import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/food_scan_provider.dart';
import '../../models/food_scan_model.dart';
import '../../widgets/food_comparison_result_widget.dart';
import '../../utils/dummy_data_generator.dart'; // Import DummyDataGenerator

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
        title: const Text('Riwayat Pemindaian'),
        // ===================== TEMPORARY DUMMY BUTTON START =====================
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white, // Button background color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final generator = DummyDataGenerator();
                await generator.loadAndSaveDummyData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dummy data uploaded to Firestore')),
                );
              },
              child: const Text(
                'Generate Dummy',
                style: TextStyle(
                  color: Colors.blue, // Text color
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
        // ===================== TEMPORARY DUMMY BUTTON END =====================
      ),
      body: foodScanProvider.isLoading 
          ? const Center(child: CircularProgressIndicator())
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
            'Belum ada riwayat pemindaian',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan makanan Anda untuk melihat riwayat di sini',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFoodScansList(List<FoodScanModel> foodScans) {
    // Sort berdasarkan waktu scan, dari yang terbaru
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
        // Jika item riwayat diklik, tampilkan hasil analisis jika ada
        if (scan.isDone) {
          _showAnalysisDetails(scan);
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar dengan badge AI jika ada analisis AI
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
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 180,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                  
                // Badge AI jika ada analisis AI
                if (hasAiAnalysis)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.9),
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
                          color: scan.isDone ? Colors.green[100] : Colors.red[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          scan.isDone ? Icons.check_circle : Icons.warning,
                          color: scan.isDone ? Colors.green : Colors.red,
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
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editScan(scan),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoItem('Berat Awal', '${_calculateTotalWeight(scan).toStringAsFixed(1)} gram'),
                      if (scan.isDone)
                        _buildInfoItem('Berat Sisa', '${_calculateTotalRemainingWeight(scan).toStringAsFixed(1)} gram'),
                      _buildInfoItem(
                        'Status', 
                        scan.isDone ? (scan.isEaten ? 'Habis dimakan' : 'Tersisa') : 'Belum selesai',
                        color: scan.isDone ? (scan.isEaten ? Colors.green : Colors.orange) : Colors.red,
                      ),
                    ],
                  ),
                  
                  // Informasi analisis AI jika ada
                  if (hasAiAnalysis) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Analisis AI',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Sisa: ${scan.aiRemainingPercentage!.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: scan.aiRemainingPercentage! / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ketuk untuk melihat detail analisis',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  
                  if (!scan.isDone) ...[
                    const SizedBox(height: 16),
                    Card(
                      margin: EdgeInsets.zero,
                      color: Colors.amber[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info,
                              color: Colors.amber[700],
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Makanan ini tidak dihabiskan, yang berarti terhitung sebagai food waste',
                                style: TextStyle(
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
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
          // Tidak perlu file lokal karena kita sudah punya URL gambar dari Firestore
        ),
      ),
    );
  }
  
  void _editScan(FoodScanModel scan) {
    // Implementasi edit akan dibuat nanti
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit fitur akan segera tersedia')),
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