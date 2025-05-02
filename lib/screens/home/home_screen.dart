import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/food_scan_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../models/food_scan_model.dart';
import '../history/history_screen.dart';
import '../educational/educational_screen.dart';
import '../calendar/calendar_screen.dart';
import '../scan/scan_screen.dart';
import '../settings/profile_screen.dart';
import '../gamification/leaderboard_screen.dart';
import '../../screens/food_waste_scan_screen.dart';
import '../progress/progresss_boardig_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  @override
  void initState() {
    super.initState();
    
    // Validasi sesi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final foodScanProvider = Provider.of<FoodScanProvider>(context, listen: false);
      final gamificationProvider = Provider.of<GamificationProvider>(context, listen: false);
      
      // Validasi sesi lokal dengan Firebase di belakang layar
      authProvider.validateSession();
      
      if (authProvider.user != null) {
        foodScanProvider.loadUserFoodScans(authProvider.user!.id);
        foodScanProvider.loadWeeklyFoodWaste(authProvider.user!.id);
        gamificationProvider.loadLeaderboard();
        gamificationProvider.loadQuests();
        
        // Cek apakah aplikasi dibuka dari widget
        _checkLaunchFromWidget();
      }
    });
  }
  
  Future<void> _checkLaunchFromWidget() async {
    // Periksa apakah aplikasi dibuka dari widget untuk scan
    final foodScanProvider = Provider.of<FoodScanProvider>(context, listen: false);
    final launchedFromWidget = await foodScanProvider.checkLaunchFromWidget();
    
    print('DEBUG: HomeScreen _checkLaunchFromWidget called, result: $launchedFromWidget');
    
    if (launchedFromWidget && mounted) {
      // Delay sedikit agar UI stabil sebelum navigasi
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (!mounted) return;
      
      print('DEBUG: Navigating to ScanScreen from widget launch');
      // Buka layar scan otomatis
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ScanScreen()),
      );
    }
  }
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final foodScanProvider = Provider.of<FoodScanProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    
    final screens = [
      _buildHomeContent(context, foodScanProvider, authProvider),
      const HistoryScreen(),
      Container(), // Placeholder untuk tombol scan
      // const EducationalScreen(),
      const ProgressBoardingScreen(),
      const ProfileScreen(),
    ];
    
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex == 2 ? 0 : _selectedIndex, // Jika tombol scan dipilih, tetap tampilkan home screen
        children: screens,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ScanScreen()),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 8,
        shape: const CircleBorder(),
        child: const 
        ImageIcon(
          AssetImage('assets/images/scan.png'),
          size: 28,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 10,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Left side of FAB
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavBarItem(0, Icons.home, 'Beranda'),
                    _buildNavBarItem(1, Icons.history, 'Riwayat'),
                  ],
                ),
              ),
              
              // Space for FAB
              const SizedBox(width: 80),
              
              // Right side of FAB
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavBarItem(3, Icons.show_chart, 'Progress'), // Ubah ikon dan label di sini
                    _buildNavBarItem(4, Icons.person, 'Profil'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHomeContent(BuildContext context, FoodScanProvider foodScanProvider, AuthProvider authProvider) {
    final unfinishedFoodScans = foodScanProvider.foodScans
        .where((scan) => !scan.isDone)
        .toList();
    
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'FoodWise',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting section
              Text(
                'Halo, ${authProvider.user?.username ?? 'Pengguna'}!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selamat datang di FoodWise',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              
              // Unfinished food section
              if (unfinishedFoodScans.isNotEmpty) ...[
                const Text(
                  'Makanan yang Belum Selesai',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: unfinishedFoodScans.length,
                  itemBuilder: (context, index) {
                    final scan = unfinishedFoodScans[index];
                    final formattedDate = DateFormat('d MMM yyyy, HH:mm').format(scan.scanTime);
                    
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: scan.imageUrl != null 
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                scan.imageUrl!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => 
                                  Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.fastfood),
                                  ),
                              ),
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.amber[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.fastfood, color: Colors.amber),
                            ),
                        title: Text(
                          scan.foodName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Berat: ${_calculateTotalWeight(scan).toStringAsFixed(1)} gram'),
                            Text('Discan pada: $formattedDate'),
                          ],
                        ),
                        trailing: ElevatedButton(
                          child: const Text('Selesai'),
                          onPressed: () => _showFinishFoodDialog(context, scan),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
              
              // Main features section
              const Text(
                'Fitur Utama',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Welcome section
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: authProvider.user?.photoURL != null && authProvider.user!.photoURL.isNotEmpty
                                ? NetworkImage(authProvider.user!.photoURL)
                                : null,
                            child: authProvider.user?.photoURL == null || authProvider.user!.photoURL.isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selamat Datang,',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Text(
                                authProvider.user?.username ?? 'Pengguna',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatCard(
                            context,
                            'Peringkat',
                            '#${Provider.of<GamificationProvider>(context).getUserRank(authProvider.user?.id ?? '')}',
                            Colors.blue,
                          ),
                          _buildStatCard(
                            context,
                            'Poin',
                            '${authProvider.user?.points ?? 0}',
                            Colors.green,
                          ),
                          _buildStatCard(
                            context,
                            'Scan',
                            '${foodScanProvider.foodScans.length}',
                            Colors.orange,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Calendar
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CalendarScreen()),
                  );
                },
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Hari Ini',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now()),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Features grid
              Text(
                'Fitur',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildFeatureCard(
                    context,
                    'Riwayat Scan',
                    'Lihat riwayat makanan yang pernah di-scan',
                    Icons.history,
                    Colors.blue,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HistoryScreen()),
                      );
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    'Edukasi',
                    'Pelajari cara mengurangi food waste',
                    Icons.school,
                    Colors.purple,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EducationalScreen()),
                      );
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    'Progress',
                    'Rangkuman statistik makanan anda',
                    Icons.show_chart,
                    Colors.purple,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProgressBoardingScreen()),
                      );
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    'Scan Makanan',
                    'Scan makanan dengan kamera',
                    Icons.camera_alt,
                    Colors.green,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ScanScreen()),
                      );
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    'Leaderboard',
                    'Lihat peringkat pengguna',
                    Icons.leaderboard,
                    Colors.orange,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
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
  
  Widget _buildStatCard(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getIconForStat(label),
            color: color,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
  
  IconData _getIconForStat(String stat) {
    switch (stat) {
      case 'Peringkat':
        return Icons.emoji_events;
      case 'Poin':
        return Icons.star;
      case 'Scan':
        return Icons.camera_alt;
      default:
        return Icons.info;
    }
  }
  
  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFinishFoodDialog(BuildContext context, FoodScanModel scan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Makanan Selesai?'),
        content: const Text('Apakah makanan ini sudah habis atau masih tersisa?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              
              // Update sebagai selesai tanpa sisa
              final foodScanProvider = Provider.of<FoodScanProvider>(context, listen: false);
              final updatedScan = scan.copyWith(
                isDone: true,
                isEaten: true,
              );
              
              foodScanProvider.updateFoodScan(updatedScan);
            },
            child: const Text('Habis'),
          ),
          ElevatedButton(
            onPressed: () {
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
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Scan dengan AI'),
          ),
        ],
      ),
    );
  }
  
  double _calculateTotalWeight(FoodScanModel scan) {
    if (scan.foodItems.isEmpty) {
      return 0.0;
    }
    return scan.foodItems.fold(0.0, (sum, item) => sum + item.weight);
  }
}