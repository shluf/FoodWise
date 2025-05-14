import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/food_scan_provider.dart';
import '../../models/food_scan_model.dart';
import '../../widgets/camera_overlay_widget.dart';
import '../../widgets/food_comparison_result_widget.dart';

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
  String? _previousImageUrl;
  bool _isLoading = true;
  bool _isAnalyzing = false;
  bool _analysisComplete = false;
  String? _errorMessage;
  FoodScanModel? _foodScan;
  File? _capturedImage;
  
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
        orElse: () => throw Exception('Food scan not found'),
      );
      
      // Set URL gambar dari Firestore untuk overlay
      setState(() {
        _previousImageUrl = _foodScan?.imageUrl;
        _isLoading = false;
      });
      
      // Cadangan: Jika ada masalah dengan URL, load gambar lokal
      if (_previousImageUrl == null || _previousImageUrl!.isEmpty) {
        final imagePath = await provider.getOverlayImagePath(widget.foodScanId);
        if (mounted) {
          setState(() {
            _previousImagePath = imagePath;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load previous image: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  void _handleImageCaptured(File imageFile) async {
    if (_foodScan == null || !mounted) return;
    
    setState(() {
      _isAnalyzing = true;
      _capturedImage = imageFile;
    });
    
    try {
      final provider = Provider.of<FoodScanProvider>(context, listen: false);
      
      // Process image comparison
      final result = await provider.scanFoodWaste(imageFile, _foodScan!.id);
      
      if (!mounted) return;
      
      setState(() {
        _isAnalyzing = false;
        _analysisComplete = true;
      });
      
      // Save analysis results to display after user taps Done button
      _scanResult = result;
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = 'Failed to analyze food: $e';
        });
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to analyze food: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Store analysis results
  Map<String, dynamic>? _scanResult;
  
  void _showResults() {
    if (_capturedImage == null || _scanResult == null || !mounted) return;
    
    final provider = Provider.of<FoodScanProvider>(context, listen: false);
    final updatedFoodScan = provider.foodScans.firstWhere(
      (scan) => scan.id == _foodScan!.id, 
      orElse: () => _foodScan!
    );
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => FoodComparisonResultWidget(
          foodScan: updatedFoodScan,
          remainingPercentage: _scanResult!['remainingPercentage'],
          confidence: _scanResult!['confidence'],
          beforeImageFile: _previousImagePath != null ? File(_previousImagePath!) : null,
          afterImageFile: _capturedImage,
          beforeImageUrl: _previousImageUrl,
          afterImageUrl: updatedFoodScan.afterImageUrl,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Scaffold(
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
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Show analysis screen when analyzing
    if (_isAnalyzing) {
      return Scaffold(
        body: Container(
          color: Colors.white,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/icons/ai_icon_anim.gif',
                  width: 240,
                  height: 240,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Gemini still trying to fix your result',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show success screen when analysis is complete
    if (_analysisComplete) {
      return Scaffold(
        body: Container(
          color: Colors.white,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Great!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your food has been analyzed',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                Image.asset(
                  'assets/icons/check_icon_anim.gif',
                  width: 120,
                  height: 120,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 200,
                  child: TextButton(
                    onPressed: _showResults,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Show camera with overlay
    return CameraWithOverlayScreen(
      previousImagePath: _previousImagePath,
      previousImageUrl: _previousImageUrl,
      onImageCaptured: _handleImageCaptured,
    );
  }
} 