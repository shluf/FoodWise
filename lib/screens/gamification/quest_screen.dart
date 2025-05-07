import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:foodwise/widgets/common_header.dart'; // Perbaiki jalur impor
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../models/quest_model.dart'; // Import the QuestModel class

class QuestScreen extends StatefulWidget {
  const QuestScreen({super.key});

  @override
  State<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen> {
  Color? _dominantColor;
  List<Map<String, dynamic>> _rawQuests = [];

  @override
  void initState() {
    super.initState();
    _extractDominantColor();
    _fetchUserQuests();
  }

  Future<void> _extractDominantColor() async {
    final paletteGenerator = await PaletteGenerator.fromImageProvider(
      const AssetImage('assets/images/background-pattern.png'),
    );
    setState(() {
      _dominantColor = paletteGenerator.dominantColor?.color ?? Colors.transparent;
    });

    // Atur warna status bar berdasarkan warna dominan
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: _dominantColor, // Gunakan warna dominan
        statusBarIconBrightness: Brightness.light, // Gunakan ikon terang
      ),
    );
  }

  Future<void> _fetchUserQuests() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final firestoreService = FirestoreService();

    if (authProvider.user != null) {
      try {
        final quests = await firestoreService.getUserQuests(authProvider.user!.id);
        setState(() {
          _rawQuests = quests.map((quest) => quest.toMap()).toList();
        });
        debugPrint('Quests fetched: $_rawQuests'); // Log fetched quests
      } catch (e) {
        debugPrint('Error fetching quests: $e'); // Log errors
      }
    } else {
      debugPrint('User is null, cannot fetch quests'); // Log if user is null
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final firestoreService = FirestoreService();

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent, // Buat latar belakang transparan
        body: StreamBuilder<List<QuestModel>>(
          stream: firestoreService.getUserQuestsStream(authProvider.user!.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final quests = snapshot.data ?? [];

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Judul yang ikut ter-scroll
                Text(
                  'Challenges',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor, // Warna primary
                  ),
                ),
                const SizedBox(height: 16),
                // Daftar kartu quest berdasarkan data dari Firestore
                ...quests.map((quest) {
                  return _buildQuestCard(
                    context,
                    name: quest.title,
                    description: quest.description,
                    point: quest.points,
                  );
                }).toList(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuestCard(BuildContext context, {required String name, required String description, required int point}) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor, // Background primary
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: Colors.amber, // Warna emas
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+$point',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Warna teks putih
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _showClaimOverlay(context, point);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Claim'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showClaimOverlay(BuildContext context, int point) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.all(24.0), // Tambahkan padding untuk jarak
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8, // Lebar 80% dari layar
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Congratulations!',
                  style: TextStyle(
                    fontSize: 28, // Ukuran font lebih besar
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor, // Warna primary
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16), // Jarak antar elemen
                Text(
                  "You've earned $point points",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16), // Jarak antar elemen
                const Icon(
                  Icons.monetization_on,
                  color: Colors.amber, // Warna emas
                  size: 64, // Ukuran ikon lebih besar
                ),
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity, // Lebar penuh
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor, // Background primary
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(fontSize: 16), // Ukuran font tombol
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}