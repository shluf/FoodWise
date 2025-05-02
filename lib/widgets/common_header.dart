import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CommonHeader extends StatelessWidget {
  final int totalPoints;

  const CommonHeader({super.key, required this.totalPoints});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
              color: Colors.white,
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
                  '$totalPoints',
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
    );
  }
}
