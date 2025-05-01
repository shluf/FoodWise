import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ProgressBoardingScreen extends StatelessWidget {
  const ProgressBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Mingguan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Grafik Konsumsi Makanan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: MediaQuery.of(context).size.height * 0.5, // Tinggi diatur menjadi 1/2 layar
              margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              padding: const EdgeInsets.all(16),
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
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 500, // Maksimal nilai gram
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        reservedSize: 30,
                        interval: 100, // Interval nilai Y
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return const Text('Senin', style: TextStyle(color: Colors.grey, fontSize: 12));
                            case 1:
                              return const Text('Selasa', style: TextStyle(color: Colors.grey, fontSize: 12));
                            case 2:
                              return const Text('Rabu', style: TextStyle(color: Colors.grey, fontSize: 12));
                            case 3:
                              return const Text('Kamis', style: TextStyle(color: Colors.grey, fontSize: 12));
                            case 4:
                              return const Text('Jumat', style: TextStyle(color: Colors.grey, fontSize: 12));
                            case 5:
                              return const Text('Sabtu', style: TextStyle(color: Colors.grey, fontSize: 12));
                            case 6:
                              return const Text('Minggu', style: TextStyle(color: Colors.grey, fontSize: 12));
                            default:
                              return const Text('');
                          }
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  barGroups: _buildBarGroups(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Rangkuman Limbah Makanan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryItem('Total Limbah Makanan', '1.7504 kg'),
            _buildSummaryItem('Total Emisi Karbon', '0.00621 kg CO₂'),
            const SizedBox(height: 16),
            const Text(
              'Limbah Berdasarkan Kategori',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildCategoryItem('Karbohidrat', '350 gram'),
            _buildCategoryItem('Protein', '180 gram'),
            _buildCategoryItem('Sayuran', '90 gram'),
            const SizedBox(height: 16),
            const Text(
              'Limbah Berdasarkan Waktu Makan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildMealTimeItem('Breakfast', '3.2%'),
            _buildMealTimeItem('Lunch', '11.6%'),
            _buildMealTimeItem('Dinner', '5.1%'),
            const SizedBox(height: 16),
            const Text(
              'Limbah Berdasarkan Hari',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildDayWasteItem('Monday', '520.5 gram'),
            _buildDayWasteItem('Tuesday', '380.3 gram'),
            _buildDayWasteItem('Wednesday', '290.0 gram'),
            const SizedBox(height: 16),
            const Text(
              'Makanan yang Paling Sering Dihabiskan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildFinishedItem('Sayur Nangka', '12 kali'),
            _buildFinishedItem('Ayam Suwir', '9 kali'),
            const SizedBox(height: 16),
            const Text(
              'Makanan yang Paling Banyak Terbuang',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildWastedItem('Nasi', '200.5 gram', '15 kali'),
            _buildWastedItem('Rendang', '120.8 gram', '10 kali'),
            const SizedBox(height: 16),
            const Text(
              'Rekomendasi untuk Pengguna',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildRecommendationItem(
              'Frequent Waste Time',
              'Lunch',
              'Kurangi porsi nasi saat makan siang.',
              'Pilih makanan berbasis sayuran atau sup saat siang.',
              'Usahakan ambil porsi lebih kecil terlebih dahulu, dan tambah jika masih lapar.',
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    final data = [300, 250, 400, 350, 200, 450, 300]; // Contoh data gram
    return List.generate(data.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            fromY: 0,
            toY: data[index].toDouble(),
            color: Colors.blue,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String category, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            category,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFinishedItem(String itemName, String count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            itemName,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            count,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMealTimeItem(String mealTime, String percentage) {
    return _buildSummaryItem(mealTime, percentage);
  }

  Widget _buildDayWasteItem(String day, String waste) {
    return _buildSummaryItem(day, waste);
  }

  Widget _buildWastedItem(String itemName, String weight, String occurrences) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '$itemName ($occurrences)',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            weight,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(
    String label,
    String frequentWasteTime,
    String portionAdjustment,
    String foodTypeRecommendation,
    String behavioralTip,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: $frequentWasteTime',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text('Portion Adjustment: $portionAdjustment'),
        Text('Food Type Recommendation: $foodTypeRecommendation'),
        Text('Behavioral Tip: $behavioralTip'),
      ],
    );
  }
}
