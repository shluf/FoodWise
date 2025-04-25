import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/food_scan_provider.dart';
import '../models/food_scan_model.dart';
import '../widgets/camera_overlay_widget.dart';
import '../widgets/food_comparison_result_widget.dart';

class FoodWasteScanScreen extends StatefulWidget {
  final String foodScanId;
  
  const FoodWasteScanScreen({
    Key? key,
    required this.foodScanId,
  }) : super(key: key);
  
  @override
  State<FoodWasteScanScreen> createState() => _FoodWasteScanScreenState();
}

class _FoodWasteScanScreenState extends State<FoodWasteScanScreen> {
  String? _previousImagePath;
  bool _isLoading = true;
  String? _errorMessage;
  FoodScanModel? _foodScan;
  
  @override
  void initState() {
    super.initState();
    _loadPreviousImage();
  }
  
  Future<void> _loadPreviousImage() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final provider = Provider.of<FoodScanProvider>(context, listen: false);
      _foodScan = provider.foodScans.firstWhere(
        (scan) => scan.id == widget.foodScanId,
        orElse: () => throw Exception('Food scan tidak ditemukan'),
      );
      
      final imagePath = await provider.getOverlayImagePath(widget.foodScanId);
      
      if (mounted) {
        setState(() {
          _previousImagePath = imagePath;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat gambar sebelumnya: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  void _handleImageCaptured(File imageFile) async {
    if (_foodScan == null || !mounted) return;
    
    try {
      final provider = Provider.of<FoodScanProvider>(context, listen: false);
      
      // Tampilkan loading screen
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Menganalisis gambar makanan...'),
            ],
          ),
        ),
      );
      
      // Proses perbandingan gambar
      final result = await provider.scanFoodWaste(imageFile, _foodScan!.id);
      
      if (!mounted) return;
      
      // Tutup dialog loading
      Navigator.of(context).pop();
      
      // Buka halaman hasil perbandingan
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => FoodComparisonResultWidget(
            foodScan: provider.foodScans.firstWhere((scan) => scan.id == _foodScan!.id),
            remainingPercentage: result['remainingPercentage'],
            confidence: result['confidence'],
            beforeImageFile: _previousImagePath != null ? File(_previousImagePath!) : null,
            afterImageFile: imageFile,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        // Tutup dialog loading jika masih terbuka
        Navigator.of(context, rootNavigator: true).pop();
        
        // Tampilkan pesan error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menganalisis makanan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Memuat...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Kembali'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Tampilkan layar kamera dengan overlay
    return CameraWithOverlayScreen(
      previousImagePath: _previousImagePath,
      onImageCaptured: _handleImageCaptured,
    );
  }
} 