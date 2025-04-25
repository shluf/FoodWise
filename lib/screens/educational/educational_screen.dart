import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EducationalScreen extends StatelessWidget {
  const EducationalScreen({super.key});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      throw Exception('Tidak bisa membuka $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edukasi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Pelajari Cara Mengurangi Food Waste',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Food waste atau sampah makanan adalah masalah global yang berdampak pada lingkungan dan ekonomi. Berikut adalah beberapa sumber edukasi yang dapat membantu Anda memahami dan mengurangi food waste.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          
          // Video edukasi
          _buildEducationalCard(
            context,
            'Tips Mengurangi Food Waste di Rumah',
            'Pelajari cara-cara praktis untuk mengurangi pembuangan makanan di rumah Anda',
            Icons.video_library,
            Colors.red,
            () => _launchUrl('https://www.youtube.com/watch?v=vKYLF8a6oKA'),
          ),
          
          _buildEducationalCard(
            context,
            'Menyimpan Makanan dengan Benar',
            'Teknik menyimpan berbagai jenis makanan agar lebih tahan lama',
            Icons.kitchen,
            Colors.green,
            () => _launchUrl('https://www.youtube.com/watch?v=tOYMnlD_w5U'),
          ),
          
          _buildEducationalCard(
            context,
            'Memanfaatkan Sisa Makanan',
            'Ide kreatif untuk mengolah kembali sisa makanan menjadi hidangan lezat',
            Icons.restaurant,
            Colors.orange,
            () => _launchUrl('https://www.youtube.com/watch?v=ZJy1ajvMU1k'),
          ),
          
          _buildEducationalCard(
            context,
            'Dampak Food Waste terhadap Lingkungan',
            'Memahami bagaimana food waste berkontribusi pada perubahan iklim',
            Icons.eco,
            Colors.blue,
            () => _launchUrl('https://www.youtube.com/watch?v=ishA6kry8nc'),
          ),
          
          const SizedBox(height: 24),
          
          // Artikel
          const Text(
            'Artikel yang Direkomendasikan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildArticleCard(
            context,
            'Panduan Lengkap Mengurangi Food Waste',
            'Pelajari strategi menyeluruh untuk mengurangi food waste di kehidupan sehari-hari',
            'https://zerowaste.id/zero-waste-lifestyle/7-tips-untuk-mengurangi-food-waste-di-rumah/',
          ),
          
          _buildArticleCard(
            context,
            'Kompos dari Sisa Makanan',
            'Cara mudah membuat kompos dari sisa makanan di rumah',
            'https://waste4change.com/blog/yuk-ketahui-cara-mengolah-sampah-makanan-di-rumah-menjadi-kompos/',
          ),
        ],
      ),
    );
  }
  
  Widget _buildEducationalCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildArticleCard(
    BuildContext context,
    String title,
    String description,
    String url,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _launchUrl(url),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Baca selengkapnya',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 