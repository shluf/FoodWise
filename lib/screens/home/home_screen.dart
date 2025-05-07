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
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

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
    final double dashLength = 3;
    final double gapLength = 3;
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

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Color? _dominantColor;
  DateTime _selectedDate = DateTime.now();
  final DateTime _firstDay = DateTime.now().subtract(const Duration(days: 6));
  final DateTime _lastDay = DateTime.now().add(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    _extractDominantColor();

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
          heroTag: 'home',
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
    
    // Mengambil scan makanan sesuai dengan tanggal yang dipilih
    final selectedDateScans = _getScansForSelectedDate(foodScanProvider);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: null,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Weekly Calendar di paling atas
                _buildScrollableDayCircles(context, foodScanProvider),
                
                const SizedBox(height: 16),
                
                // Greeting section with background and shadow
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi, ${authProvider.user?.username ?? 'User'}!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "You haven't done anything, scan now to start!",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: Image.asset(
                          'assets/images/person-on-fire.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
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
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
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
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
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
                
                const SizedBox(height: 24),
                
                // Recently logged section - Menampilkan data sesuai tanggal yang dipilih
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recently Logged',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
                            'more',
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
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "No food data on ${DateFormat('d MMM yyyy').format(_selectedDate)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Start tracking food by taking a photo.",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
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
                          
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                                  Text('Weight: ${_calculateTotalWeight(scan).toStringAsFixed(1)} gram'),
                                  Text('Time: $formattedDate'),
                                  Text(
                                    scan.isDone 
                                      ? (scan.isEaten ? 'Status: Eaten' : 'Status: Wasted') 
                                      : 'Status: Not finished',
                                    style: TextStyle(
                                      color: scan.isDone 
                                        ? (scan.isEaten ? Colors.green : Colors.red) 
                                        : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: !scan.isDone ? ElevatedButton(
                                child: const Text('Finish'),
                                onPressed: () => _showFinishFoodDialog(context, scan),
                              ) : null,
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
      ),
    );
  }

  Widget _buildScrollableDayCircles(BuildContext context, FoodScanProvider foodScanProvider) {
    final days = ["S", "M", "T", "W", "T", "F", "S"];
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
                      Stack(
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
        if (_getScansForSelectedDate(foodScanProvider).isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.eco,
                  color: Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Anda menghemat ${_calculateCarbonSavedForDay(_getScansForSelectedDate(foodScanProvider)).toStringAsFixed(2)} kg CO₂',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDayCircles(BuildContext context, FoodScanProvider foodScanProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(8, (index) {
          final day = _firstDay.add(Duration(days: index));
          final isSelected = DateUtils.isSameDay(day, _selectedDate);
          final dayName = DateFormat('E', 'id_ID').format(day).substring(0, 1).toUpperCase();
          final dayNumber = day.day.toString();
          final hasScans = _getScansForDay(foodScanProvider, day).isNotEmpty;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = day;
              });
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Theme.of(context).primaryColor : (hasScans ? Colors.grey[300] : Colors.grey[200]),
              ),
              child: Stack(
                children: [
                  if (!isSelected)
                    CustomPaint(
                      size: const Size(36, 36),
                      painter: DashedCircleBorderPainter(
                        color: Colors.grey,
                      ),
                    ),
                  Center(
                    child: Text(
                      dayNumber,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
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
  
  Widget _buildScanList(FoodScanProvider provider) {
    final scans = _getScansForSelectedDate(provider);
    double totalCarbonSaved = _calculateCarbonSavedForDay(scans);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.eco,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  'Anda menghemat ${totalCarbonSaved.toStringAsFixed(2)} kg CO₂ hari ini',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: scans.length > 3 ? 3 : scans.length,
          itemBuilder: (context, index) {
            final scan = scans[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    color: Colors.amber,
                  ),
                ),
                title: Text(
                  scan.foodName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  DateFormat('HH:mm').format(scan.scanTime),
                ),
                trailing: Text(
                  '${_calculateTotalWeight(scan).toStringAsFixed(0)} g',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        ),
        if (scans.length > 3)
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CalendarScreen()),
                );
              },
              child: const Text('Lihat Semua'),
            ),
          ),
      ],
    );
  }
  
  double _calculateCarbonSavedForDay(List<FoodScanModel> scans) {
    double totalWeightSaved = 0;
    for (var scan in scans) {
      if (scan.isDone && scan.isEaten) {
        // Jika makanan dimakan, hitung sebagai penghematan
        double totalWeight = _calculateTotalWeight(scan);
        totalWeightSaved += totalWeight;
      }
    }
    // Asumsi: 1 kg makanan = 2.5 kg CO2
    return totalWeightSaved / 1000 * 2.5;
  }
  
  String _calculateCarbonEmission(FoodScanProvider provider) {
    List<FoodScanModel> allScans = provider.foodScans;
    if (allScans.isEmpty) {
      return "If you reduce food waste by 10%, you can reduce 0.5 kg of CO₂ every week!";
    }
    
    double totalWeightSaved = 0;
    for (var scan in allScans) {
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
    final firestoreService = FirestoreService(); // Add FirestoreService instance

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Makanan Selesai?'),
        content: const Text('Apakah makanan ini sudah habis atau masih tersisa?'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Update sebagai selesai tanpa sisa
              final foodScanProvider = Provider.of<FoodScanProvider>(context, listen: false);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final updatedScan = scan.copyWith(
                isDone: true,
                isEaten: true,
              );

              await foodScanProvider.updateFoodScan(updatedScan);

              // Trigger generate and save weekly summary
              if (authProvider.user != null) {
                await firestoreService.generateAndSaveWeeklySummary(authProvider.user!.id);
              }
            },
            child: const Text('Habis'),
          ),
          ElevatedButton(
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