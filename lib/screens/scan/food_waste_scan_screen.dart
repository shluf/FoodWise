import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/food_scan_provider.dart';
import '../../models/food_scan_model.dart';
import '../../widgets/food_comparison_result_widget.dart';
import '../../widgets/food_scan_camera_widget.dart';

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
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => FoodComparisonResultWidget(
          foodScan: provider.foodScans.firstWhere((scan) => scan.id == _foodScan!.id),
          remainingPercentage: _scanResult!['remainingPercentage'],
          confidence: _scanResult!['confidence'],
          beforeImageFile: _previousImagePath != null ? File(_previousImagePath!) : null,
          afterImageFile: _capturedImage,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading...'),
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
      return const Scaffold(
        body: AnalyzingFoodWidget(),
      );
    }

    // Show success screen when analysis is complete
    if (_analysisComplete) {
      return Scaffold(
        body: AnalysisCompleteWidget(
          onDonePressed: _showResults,
        ),
      );
    }
    
    // Show camera with overlay
    return Scaffold(
      body: FoodScanCameraWidget(
        previousImagePath: _previousImagePath,
        onImageCaptured: _handleImageCaptured,
        showSwitchCameraButton: false,
      ),
    );
  }
} 