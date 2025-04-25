import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/food_scan_model.dart';

class FoodComparisonResultWidget extends StatelessWidget {
  final FoodScanModel foodScan;
  final double remainingPercentage;
  final double confidence;
  final File? beforeImageFile;
  final File? afterImageFile;
  
  const FoodComparisonResultWidget({
    Key? key,
    required this.foodScan,
    required this.remainingPercentage,
    required this.confidence,
    this.beforeImageFile,
    this.afterImageFile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil Analisis Makanan'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card untuk informasi makanan
              _buildFoodInfoCard(context),
              
              const SizedBox(height: 24),
              
              // Gambar sebelum dan sesudah
              _buildComparisonCard(context),
              
              const SizedBox(height: 24),
              
              // Hasil Analisis AI
              _buildAnalysisCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodInfoCard(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              foodScan.foodName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.scale, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Berat awal: ${_calculateTotalWeight().toStringAsFixed(1)} gram',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.restaurant_menu, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Sisa makanan: ${_calculateTotalRemainingWeight().toStringAsFixed(1)} gram',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Waktu scan: ${_formatDate(foodScan.scanTime)}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildComparisonCard(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Perbandingan Gambar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Sebelum',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AspectRatio(
                        aspectRatio: 1.0, // Membuat gambar persegi
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildBeforeImage(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Sesudah',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AspectRatio(
                        aspectRatio: 1.0, // Membuat gambar persegi
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildAfterImage(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBeforeImage() {
    if (beforeImageFile != null) {
      return Image.file(
        beforeImageFile!,
        fit: BoxFit.cover,
      );
    } else if (foodScan.imageUrl != null && foodScan.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: foodScan.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[300],
          child: const Center(
            child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
          ),
        ),
      );
    } else {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Text('Tidak ada gambar'),
        ),
      );
    }
  }
  
  Widget _buildAfterImage() {
    if (afterImageFile != null) {
      return Image.file(
        afterImageFile!,
        fit: BoxFit.cover,
      );
    } else if (foodScan.afterImageUrl != null && foodScan.afterImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: foodScan.afterImageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[300],
          child: const Center(
            child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
          ),
        ),
      );
    } else {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Text('Tidak ada gambar'),
        ),
      );
    }
  }
  
  Widget _buildAnalysisCard(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.blue, size: 24),
                SizedBox(width: 8),
                Text(
                  'Hasil Analisis AI',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressIndicator(
              label: 'Persentase Makanan Tersisa',
              value: remainingPercentage / 100,
              color: Colors.blue,
              text: '${remainingPercentage.toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 16),
            _buildProgressIndicator(
              label: 'Tingkat Keyakinan AI',
              value: confidence,
              color: Colors.green,
              text: '${(confidence * 100).toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 16),
            _buildImpactInformation(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProgressIndicator({
    required String label,
    required double value,
    required Color color,
    required String text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        Stack(
          children: [
            LinearProgressIndicator(
              value: value,
              minHeight: 20,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            Positioned.fill(
              child: Center(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 3,
                        color: Colors.black45,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildImpactInformation() {
    // Hitung dampak lingkungan dari makanan yang terbuang
    final wastedWeight = _calculateTotalRemainingWeight();
    final carbonEmission = wastedWeight * 0.0025; // 1 gram = 0.0025 kg CO2
    final waterUsage = wastedWeight * 1.2; // 1 gram = 1.2 liter air (perkiraan)
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dampak Lingkungan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.eco, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Emisi karbon dari sisa makanan: ${carbonEmission.toStringAsFixed(2)} kg CO2',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.water_drop, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Air terbuang dalam produksi: ${waterUsage.toStringAsFixed(1)} liter',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Dengan mengurangi makanan tersisa, Anda telah membantu mengurangi dampak lingkungan dari produksi dan pembuangan makanan.',
          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
  
  String _formatDate(DateTime dateTime) {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    
    final day = dateTime.day;
    final month = months[dateTime.month - 1];
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$day $month $year, $hour:$minute';
  }

  double _calculateTotalWeight() {
    if (foodScan.foodItems.isEmpty) {
      return 0.0;
    }
    return foodScan.foodItems.fold(0.0, (sum, item) => sum + item.weight);
  }

  double _calculateTotalRemainingWeight() {
    if (foodScan.foodItems.isEmpty) {
      return 0.0;
    }
    return foodScan.foodItems.fold(0.0, (sum, item) => sum + (item.remainingWeight ?? 0.0));
  }
} 