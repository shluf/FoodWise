import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../../providers/food_scan_provider.dart';
import '../../models/food_scan_model.dart';
import '../../utils/app_colors.dart';
import '../../providers/auth_provider.dart';

class CornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;

  CornerPainter({
    required this.color,
    this.strokeWidth = 4.0,
    this.cornerLength = 30.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final width = size.width;
    final height = size.height;

    // Top left corner
    canvas.drawLine(
      Offset(0, cornerLength),
      const Offset(0, 0),
      paint,
    );
    canvas.drawLine(
      Offset(0, 0),
      Offset(cornerLength, 0),
      paint,
    );

    // Top right corner
    canvas.drawLine(
      Offset(width - cornerLength, 0),
      Offset(width, 0),
      paint,
    );
    canvas.drawLine(
      Offset(width, 0),
      Offset(width, cornerLength),
      paint,
    );

    // Bottom right corner
    canvas.drawLine(
      Offset(width, height - cornerLength),
      Offset(width, height),
      paint,
    );
    canvas.drawLine(
      Offset(width, height),
      Offset(width - cornerLength, height),
      paint,
    );

    // Bottom left corner
    canvas.drawLine(
      Offset(cornerLength, height),
      Offset(0, height),
      paint,
    );
    canvas.drawLine(
      Offset(0, height),
      Offset(0, height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(CornerPainter oldDelegate) => false;
}

class ScanScreen extends StatefulWidget {
  final bool isRemainingFoodScan;
  final FoodScanModel? originalScan;
  
  const ScanScreen({
    Key? key, 
    this.isRemainingFoodScan = false,
    this.originalScan,
  }) : super(key: key);

  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _image;
  bool _isAnalyzing = false;
  bool _isEaten = false;
  bool _isSaving = false;
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _newItemNameController = TextEditingController();
  final TextEditingController _newItemWeightController = TextEditingController();
  String? _foodName;
  double? _carbonFootprint;
  Map<String, dynamic>? _scanResult;
  List<FoodItem> _foodItems = [];
  List<PotentialFoodWasteItem> _potentialFoodWasteItems = [];
  bool _showAddItemForm = false;
  bool _showAddFoodItemForm = false;
  bool _analysisComplete = false;
  bool _flashlightOn = false;

  // Kamera variables
  List<CameraDescription>? cameras;
  CameraController? cameraController;
  bool _isCameraInitialized = false;
  bool _showCameraView = true;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    cameraController?.dispose();
    _weightController.dispose();
    _newItemNameController.dispose();
    _newItemWeightController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras != null && cameras!.isNotEmpty) {
        cameraController = CameraController(
          cameras![_selectedCameraIndex],
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await cameraController!.initialize();
        
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      } else {
        print('Tidak ada kamera yang tersedia');
      }
    } catch (e) {
      print('Error inisialisasi kamera: $e');
    }
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || cameraController == null) return;
    
    try {
      final image = await cameraController!.takePicture();
      setState(() {
        _image = File(image.path);
        _showCameraView = false;
      });
      
      // Analyze the food image
      await _analyzeFoodImage();
    } catch (e) {
      print('Error mengambil gambar: $e');
    }
  }

  void _switchCamera() async {
    if (cameras == null || cameras!.isEmpty || cameras!.length <= 1) return;
    
    _selectedCameraIndex = (_selectedCameraIndex + 1) % cameras!.length;
    
    // Dispose current controller
    await cameraController?.dispose();
    
    // Reinitialize with new camera
    if (mounted) {
      setState(() {
        _isCameraInitialized = false;
      });
      
      _initializeCamera();
    }
  }

  Future<void> _analyzeFoodImage() async {
    if (_image == null) return;
    
    setState(() {
      _isAnalyzing = true;
    });
    
    try {
      final provider = Provider.of<FoodScanProvider>(context, listen: false);
      final result = await provider.scanFoodImage(_image!);
      
      if (result != null) {
        setState(() {
          _scanResult = result;
          _foodName = result['foodName'];
          _carbonFootprint = provider.calculateCarbonEmission(
            result['estimatedWeight'] is num 
                ? (result['estimatedWeight'] as num).toDouble() 
                : 0.0
          );
          
          // Isi berat otomatis jika tersedia
          if (result['estimatedWeight'] != null && result['estimatedWeight'] is num) {
            _weightController.text = result['estimatedWeight'].toString();
          }
          
          // Ambil daftar foodItems
          if (result.containsKey('foodItems')) {
            List<dynamic> items = result['foodItems'];
            _foodItems = List<FoodItem>.from(items);
          }
          
          // Ambil daftar potentialFoodWasteItems
          if (result.containsKey('potentialFoodWasteItems')) {
            List<dynamic> items = result['potentialFoodWasteItems'];
            _potentialFoodWasteItems = List<PotentialFoodWasteItem>.from(items);
          }
          
          _isAnalyzing = false;
          _analysisComplete = true;
        });
      } else {
        // Handle analysis failure
        setState(() {
          _isAnalyzing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menganalisis gambar. Silakan coba lagi.')),
        );
      }
    } catch (e) {
      print('Error menganalisis gambar: $e');
      setState(() {
        _isAnalyzing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _resetScan() {
    setState(() {
      _image = null;
      _isAnalyzing = false;
      _isEaten = false;
      _foodName = null;
      _carbonFootprint = null;
      _scanResult = null;
      _foodItems = [];
      _potentialFoodWasteItems = [];
      _weightController.clear();
      _showCameraView = true;
      _showAddItemForm = false;
      _showAddFoodItemForm = false;
      _analysisComplete = false;
    });
  }

  void _removeWasteItem(int index) {
    setState(() {
      _potentialFoodWasteItems.removeAt(index);
    });
  }

  void _addNewWasteItem() {
    // Validasi input
    if (_newItemNameController.text.isEmpty || _newItemWeightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan estimasi emisi karbon harus diisi')),
      );
      return;
    }
    
    double? estimatedEmission = double.tryParse(_newItemWeightController.text);
    if (estimatedEmission == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estimasi emisi karbon harus berupa angka')),
      );
      return;
    }
    
    setState(() {
      _potentialFoodWasteItems.add(
        PotentialFoodWasteItem(
          itemName: _newItemNameController.text,
          estimatedCarbonEmission: estimatedEmission,
        ),
      );
      _showAddItemForm = false;
      _newItemNameController.clear();
      _newItemWeightController.clear();
    });
  }

  void _toggleAddItemForm() {
    setState(() {
      _showAddItemForm = !_showAddItemForm;
    });
  }

  void _addNewFoodItem() {
    // Validasi input
    if (_newItemNameController.text.isEmpty || _newItemWeightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan berat item harus diisi')),
      );
      return;
    }
    
    double? weight = double.tryParse(_newItemWeightController.text);
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berat harus berupa angka positif')),
      );
      return;
    }
    
    setState(() {
      _foodItems.add(
        FoodItem(
          itemName: _newItemNameController.text,
          weight: weight,
          remainingWeight: null,
        ),
      );
      _showAddFoodItemForm = false;
      _newItemNameController.clear();
      _newItemWeightController.clear();
    });
  }

  void _toggleAddFoodItemForm() {
    setState(() {
      _showAddFoodItemForm = !_showAddFoodItemForm;
      if (_showAddFoodItemForm) {
        _showAddItemForm = false;
      }
    });
  }

  void _updateFoodItemWeight(int index, double newWeight) {
    if (index < 0 || index >= _foodItems.length) return;
    
    setState(() {
      final item = _foodItems[index];
      _foodItems[index] = FoodItem(
        itemName: item.itemName,
        weight: newWeight,
        remainingWeight: item.remainingWeight,
      );
      
      // Update total weight
      double totalWeight = _foodItems.fold(0, (sum, item) => sum + item.weight);
      _weightController.text = totalWeight.toString();
    });
  }

  void _removeFoodItem(int index) {
    if (index < 0 || index >= _foodItems.length) return;
    
    setState(() {
      _foodItems.removeAt(index);
      
      // Update total weight
      double totalWeight = _foodItems.fold(0, (sum, item) => sum + item.weight);
      _weightController.text = totalWeight.toString();
    });
  }

  void _saveFoodScan() async {
    if (_foodName == null || _scanResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Food data is incomplete.')),
      );
      return;
    }

    double? weight;
    if (_weightController.text.isNotEmpty) {
      weight = double.tryParse(_weightController.text);
    }

    if (weight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid food weight.')),
      );
      return;
    }

    // Set saving state to true
    setState(() {
      _isSaving = true;
    });

    try {
      final provider = Provider.of<FoodScanProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You need to login to save food data.')),
        );
        // Reset saving state
        setState(() {
          _isSaving = false;
        });
        return;
      }

      if (widget.isRemainingFoodScan && widget.originalScan != null) {
        // Process for leftover food
        final totalRemainingWeight = weight;
        final originalWeight = _calculateTotalOriginalWeight();
        final remainingPercentage = (totalRemainingWeight / originalWeight) * 100;
        
        // Update remaining weight for each food item
        for (int i = 0; i < _foodItems.length; i++) {
          final item = _foodItems[i];
          // Calculate remaining based on percentage
          final remainingWeight = item.weight * (totalRemainingWeight / originalWeight);
          _foodItems[i] = FoodItem(
            itemName: item.itemName,
            weight: item.weight,
            remainingWeight: remainingWeight,
          );
        }
        
        // Update existing food
        final updatedScan = widget.originalScan!.copyWith(
          isDone: true,
          isEaten: _isEaten,
          foodItems: _foodItems,
          aiRemainingPercentage: remainingPercentage,
          afterImageUrl: null,
          finishTime: DateTime.now(),
        );
        
        final success = await provider.updateFoodScan(updatedScan, imageFile: _image);
        
        // Reset saving state
        setState(() {
          _isSaving = false;
        });
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Leftover food scan successful! ${remainingPercentage.toStringAsFixed(1)}% of food remaining'
              ),
            ),
          );
          
          Navigator.pop(context); // Return to previous page
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save leftover data: ${provider.error}')),
          );
        }
      } else {
        // Process for new food
        final foodScan = FoodScanModel(
          id: '', // Will be provided by Firestore
          userId: authProvider.user!.id,
          foodName: _foodName ?? 'Unidentified Food',
          scanTime: DateTime.now(),
          finishTime: null,
          isDone: false,
          isEaten: false,
          foodItems: _foodItems,
          potentialFoodWasteItems: _potentialFoodWasteItems.isNotEmpty ? _potentialFoodWasteItems : null,
          imageUrl: null, // Image URL will be set after upload to Firebase Storage
        );

        final success = await provider.addFoodScan(foodScan, imageFile: _image);

        // Reset saving state
        setState(() {
          _isSaving = false;
        });
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Food scan saved successfully!')),
          );
          
          // Reset the scan view
          _resetScan();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save data: ${provider.error}')),
          );
        }
      }
    } catch (e) {
      // Reset saving state
      setState(() {
        _isSaving = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data: $e')),
      );
    }
  }

  double _calculateTotalOriginalWeight() {
    if (widget.originalScan != null && widget.originalScan!.foodItems.isNotEmpty) {
      return widget.originalScan!.foodItems
          .fold(0, (sum, item) => sum + item.weight);
    }
    // Fallback to total weight from text field
    return double.tryParse(_weightController.text) ?? 0.0;
  }

  void _toggleFlashlight() async {
    if (!_isCameraInitialized || cameraController == null) return;
    
    try {
      final newValue = !_flashlightOn;
      await cameraController!.setFlashMode(
        newValue ? FlashMode.torch : FlashMode.off
      );
      
      setState(() {
        _flashlightOn = newValue;
      });
    } catch (e) {
      print('Error toggling flashlight: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isAnalyzing
          ? Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt,
                      size: 80,
                      color: Colors.black,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'AI still analyzing your food',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _analysisComplete
              ? _buildAnalysisCompleteView()
              : _showCameraView
                  ? _buildCameraView()
                  : _buildResultView(),
    );
  }

  Widget _buildAnalysisCompleteView() {
    return Container(
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
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _showCameraView = false;
                    _analysisComplete = false;
                  });
                },
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
    );
  }

  Widget _buildCameraView() {
    if (!_isCameraInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              size: 60,
              color: Colors.black,
            ),
            SizedBox(height: 16),
            Text(
              'Initializing camera...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Camera preview
        SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: CameraPreview(cameraController!),
        ),
        
        // Scan frame corners
        Center(
          child: SizedBox(
            width: 250,
            height: 250,
            child: CustomPaint(
              painter: CornerPainter(
                color: Colors.white,
                strokeWidth: 3.0,
                cornerLength: 30.0,
              ),
            ),
          ),
        ),
        
        // Header dengan tombol kembali
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    margin: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: const EdgeInsets.all(8.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Bottom controls overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 120,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Switch camera button
                CircleAvatar(
                  backgroundColor: Colors.white54,
                  radius: 25,
                  child: IconButton(
                    icon: const Icon(Icons.flip_camera_ios, color: Colors.black, size: 25),
                    onPressed: _switchCamera,
                  ),
                ),
                
                const SizedBox(width: 40),
                
                // Capture button
                GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                
                // Flashlight button
                const SizedBox(width: 40),
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.7),
                  radius: 25,
                  child: IconButton(
                    icon: Icon(
                      _flashlightOn ? Icons.flash_on : Icons.flash_off,
                      color: _flashlightOn ? Colors.amber : Colors.black,
                      size: 24,
                    ),
                    onPressed: _toggleFlashlight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultView() {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // App Bar that stays visible when scrolling
            SliverAppBar(
              expandedHeight: _image != null ? 250 : 100,
              floating: false,
              pinned: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.only(left: 8, top: 8),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 6,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: _image != null
                  ? Container(
                      width: double.infinity,
                      height: 250,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: FileImage(_image!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : Container(color: Colors.grey[200]),
              ),
            ),
            
            // Content
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info about leftover food scan
                    if (widget.isRemainingFoodScan && widget.originalScan != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Initial Food Information',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text('Food: ${widget.originalScan!.foodName}'),
                            Text('Total weight: ${_calculateTotalOriginalWeight().toStringAsFixed(1)} grams'),
                            const SizedBox(height: 12),
                            const Text(
                              'Scan leftover food to estimate the percentage remaining',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    
                    // Show analysis results
                    if (_foodName != null) ...[
                      // Time and Food Name
                      Text(
                        _formatTime(DateTime.now()),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black.withOpacity(0.6),
                        ),
                      ),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _foodName!,
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                // Duration Badge
                                if (widget.originalScan != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.timer, size: 15, color: Colors.black54),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDuration(widget.originalScan!.finishTime?.difference(widget.originalScan!.scanTime) ?? Duration.zero),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Row(
                              children: [
                                Text('1 ', style: TextStyle(fontWeight: FontWeight.bold)),
                                Icon(Icons.colorize, size: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Food Weight
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_fire_department, color: Colors.black),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Carbon Footprint',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_carbonFootprint?.toStringAsFixed(2)} kg CO₂e',
                                  style: const TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Confidence Level Information
                      if (_scanResult?['confidence'] != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'AI Confidence Level',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_scanResult!['confidence'] is num)
                                    Text(
                                      '${((_scanResult!['confidence'] as num).toDouble() * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (_scanResult!['confidence'] is num)
                                    ? (_scanResult!['confidence'] as num).toDouble()
                                    : 0.0,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    (_scanResult!['confidence'] is num && (_scanResult!['confidence'] as num).toDouble() > 0.7)
                                      ? Colors.green
                                      : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Show percentage of leftover food if this is a leftover food scan
                      if (widget.isRemainingFoodScan && widget.originalScan != null && double.tryParse(_weightController.text) != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Leftover Food Analysis',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildAnalysisInfoItem("Initial Weight", "${_calculateTotalOriginalWeight().round()} grams"),
                                  _buildAnalysisInfoItem("Remaining Weight", "${double.tryParse(_weightController.text)?.round() ?? 0} grams"),
                                  _buildAnalysisInfoItem("Status", "Remaining"),
                                ],
                              ),
                              const Divider(height: 40),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.auto_awesome, color: Colors.black, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        "AI Analysis",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "Food Remaining: ${_calculatePercentageRemaining().toStringAsFixed(1)}%",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _buildPercentageIndicator(),
                            ],
                          ),
                        ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Food Components
                    const Text(
                      'Food Components',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Food Item Components',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              IconButton(
                                icon: Icon(_showAddFoodItemForm ? Icons.remove : Icons.add),
                                onPressed: _toggleAddFoodItemForm,
                                tooltip: _showAddFoodItemForm ? 'Close Form' : 'Add Item',
                              ),
                            ],
                          ),
                          
                          if (_showAddFoodItemForm) ...[
                            const SizedBox(height: 12),
                            const Text('Add Food Item:'),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _newItemNameController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Item Name',
                                hintText: 'example: Fried Chicken',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _newItemWeightController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Weight (grams)',
                                hintText: 'example: 150',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _addNewFoodItem,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('Add Item'),
                              ),
                            ),
                            const Divider(height: 24),
                          ],
                          
                          if (_foodItems.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  'No food item components detected',
                                  style: TextStyle(fontStyle: FontStyle.italic),
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _foodItems.length,
                              itemBuilder: (context, index) {
                                final item = _foodItems[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.itemName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${item.weight.toStringAsFixed(0)} g',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, size: 18),
                                            onPressed: () => _removeFoodItem(index),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      // Slider for adjusting weight
                                      Row(
                                        children: [
                                          const Text('0 g'),
                                          Expanded(
                                            child: Slider(
                                              value: item.weight,
                                              min: 0,
                                              max: 500,
                                              divisions: 50,
                                              label: item.weight.round().toString(),
                                              onChanged: (double value) {
                                                _updateFoodItemWeight(index, value);
                                              },
                                            ),
                                          ),
                                          const Text('500 g'),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Potential Food Waste Items
                    const Text(
                      'Potential Food Waste',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Potential Food Waste Items',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              IconButton(
                                icon: Icon(_showAddItemForm ? Icons.remove : Icons.add),
                                onPressed: _toggleAddItemForm,
                                tooltip: _showAddItemForm ? 'Close Form' : 'Add Item',
                              ),
                            ],
                          ),
                          
                          if (_showAddItemForm) ...[
                            const SizedBox(height: 12),
                            const Text('Add New Food Waste Item:'),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _newItemNameController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Item Name',
                                hintText: 'example: Chicken Bone',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _newItemWeightController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Weight (grams)',
                                hintText: 'example: 25',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _addNewWasteItem,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('Add Item'),
                              ),
                            ),
                            const Divider(height: 24),
                          ],
                          
                          if (_potentialFoodWasteItems.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  'No food waste items detected',
                                  style: TextStyle(fontStyle: FontStyle.italic),
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _potentialFoodWasteItems.length,
                              itemBuilder: (context, index) {
                                final item = _potentialFoodWasteItems[index];
                                return Dismissible(
                                  key: Key('waste_item_${index}_${item.itemName}'),
                                  background: Container(
                                    color: Colors.red,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 16),
                                    child: const Icon(Icons.delete, color: Colors.white),
                                  ),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (direction) {
                                    _removeWasteItem(index);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${item.itemName}: ${item.estimatedCarbonEmission.toStringAsFixed(2)} kg CO2',
                                            style: const TextStyle(fontSize: 15),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 18),
                                          onPressed: () => _removeWasteItem(index),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          splashRadius: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          
                          const SizedBox(height: 8),
                          if (_potentialFoodWasteItems.isNotEmpty)
                            const Text(
                              'Swipe item to the left to delete',
                              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                            ),
                          const SizedBox(height: 8),
                          const Text(
                            'Avoid throwing away leftover food to reduce carbon footprint.',
                            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Total Food Weight
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Food Weight',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Total Food Weight (grams)',
                              hintText: 'Example: 250',
                            ),
                            onChanged: (value) {
                              // Trigger rebuild to update percentage calculation
                              if (widget.isRemainingFoodScan) {
                                setState(() {});
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Switch to mark food as completely eaten
                          if (widget.isRemainingFoodScan)
                            SwitchListTile(
                              title: Text(
                                'Food eaten completely',
                                style: TextStyle(
                                  color: _isEaten ? Colors.green : Colors.black,
                                ),
                              ),
                              value: _isEaten,
                              onChanged: (value) {
                                setState(() {
                                  _isEaten = value;
                                  // If completely eaten, set remaining weight to 0
                                  if (_isEaten) {
                                    _weightController.text = '0';
                                  }
                                });
                              },
                              activeColor: Colors.black,
                            ),
                        ],
                      ),
                    ),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _resetScan,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.black),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Retake Photo',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveFoodScan,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              widget.isRemainingFoodScan ? 'Save Leftover Data' : 'Save Data',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        // Loading overlay
        if (_isSaving)
          Container(
            color: Colors.black.withOpacity(0.5),
            width: double.infinity,
            height: double.infinity,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 20),
                  Text(
                    'Saving food data...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildAnalysisInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$hour.$minute';
  }
  
  String _formatDuration(Duration duration) {
    if (duration.inHours < 1) {
      return '${duration.inMinutes} min';
    } else if (duration.inHours == 1) {
      return '1 hour';
    } else {
      return '${duration.inHours} hours';
    }
  }
  
  // Menghitung persentase makanan yang tersisa
  double _calculatePercentageRemaining() {
    if (widget.originalScan == null) return 0.0;
    
    final currentWeight = double.tryParse(_weightController.text) ?? 0.0;
    final originalWeight = _calculateTotalOriginalWeight();
    
    if (originalWeight <= 0) return 0.0;
    
    return (currentWeight / originalWeight) * 100;
  }
  
  // Membuat indikator visual persentase sisa makanan
  Widget _buildPercentageIndicator() {
    final percentage = _calculatePercentageRemaining();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              height: 20,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Container(
              height: 20,
              width: MediaQuery.of(context).size.width * 0.8 * (percentage / 100),
              decoration: BoxDecoration(
                color: _getColorForPercentage(percentage),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // Mendapatkan warna berdasarkan persentase sisa
  Color _getColorForPercentage(double percentage) {
    if (percentage <= 25) {
      return Colors.green;
    } else if (percentage <= 50) {
      return Colors.lightGreen;
    } else if (percentage <= 75) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}