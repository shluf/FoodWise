import 'package:flutter/material.dart';
import 'package:foodwise/screens/gamification/leaderboard_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // Tambahkan import ini
import 'package:google_fonts/google_fonts.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/food_scan_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../models/food_scan_model.dart';
import '../history/history_screen.dart';
import '../educational/educational_screen.dart';
import '../calendar/calendar_screen.dart';
import '../scan/scan_screen.dart';
import '../settings/profile_screen.dart';
import '../gamification/quest_screen.dart';
import '../../screens/food_waste_scan_screen.dart';
import '../progress/progress_boarding_screen.dart';
import '../gamification/main_screen.dart';
import '../../services/firestore_service.dart';
import '../../services/ai_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Color? _dominantColor;

  @override
  void initState() {
    super.initState();
    _extractDominantColor();

    // Validasi sesi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final foodScanProvider = Provider.of<FoodScanProvider>(context, listen: false);
      final gamificationProvider = Provider.of<GamificationProvider>(context, listen: false);

      authProvider.validateSession();

      if (authProvider.user != null) {
        foodScanProvider.loadUserFoodScans(authProvider.user!.id);
        foodScanProvider.loadWeeklyFoodWaste(authProvider.user!.id);
        gamificationProvider.loadLeaderboard();
        gamificationProvider.loadQuests();
      }
    });
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
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildHomeContent(context),
      const ProgressBoardingScreen(),
      Container(), // Placeholder untuk tombol scan
      const MainScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: Stack(
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8), // Transparansi pada latar belakang
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.emoji_events,
                              color: Colors.amber,
                              size: 28,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '120', // Contoh jumlah poin
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
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
      floatingActionButton: SizedBox(
        width: 60, 
        height: 60,
        child: FloatingActionButton(
          onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScanScreen()),
        );
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
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
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
                      child: _buildNavBarItem(0, Icons.home, 'Beranda'),
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
    
    final unfinishedFoodScans = foodScanProvider.foodScans
        .where((scan) => !scan.isDone)
        .toList();
    
    return Scaffold(
      backgroundColor: Colors.transparent, // Buat latar belakang transparan

      appBar:null,
      body: SafeArea( // Tambahkan SafeArea di sini
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Greeting section with background and shadow
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  
                  child: Row(
                    children: [
                      // Text section

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi, ${authProvider.user?.username ?? 'User'}!',
                              style: TextStyle(
                                fontSize: 18, // Ukuran lebih kecil
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor, // Warna teks primary
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "You haven't done anything yet, scan now to start.",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Image section
                      SizedBox(
                        width: 80, // Perbesar ukuran gambar
                        height: 80,
                        child: Image.asset(
                          'assets/images/person-on-fire.png', // Ganti dengan path gambar Anda
                          fit: BoxFit.contain, // Pastikan gambar tidak terpotong
                        ),
                      ),
                    ],
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
                          MaterialPageRoute(builder: (context) => const MainScreen()),
                        );
                      },
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (authProvider.user != null) {
                      await firestoreService.generateAndSaveWeeklySummaryWithAI(
                        authProvider.user!.id,
                        aiService,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Weekly summary generated successfully!')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User not logged in.')),
                      );
                    }
                  },
                  child: const Text('Generate Weekly Summary'),
                ),
              ],
            ),
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