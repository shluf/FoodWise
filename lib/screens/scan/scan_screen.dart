import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../../providers/food_scan_provider.dart';
import '../../models/food_scan_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/scan/result_view.dart';

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
      const Offset(0, 0),
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
  int _count = 1;
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
    if (widget.isRemainingFoodScan && widget.originalScan != null) {
      // Pre-fill data if it's a remaining food scan
      _foodName = widget.originalScan!.foodName;
      _foodItems = List<FoodItem>.from(widget.originalScan!.foodItems); // Create a mutable copy
      // Calculate initial total weight for the controller
      _weightController.text = _calculateTotalOriginalWeight().toStringAsFixed(0);
       // If original scan had an image, potentially show it or a placeholder
      // _image = widget.originalScan.imageUrl != null ? File(widget.originalScan.imageUrl) : null;
      // For simplicity, we will take a new picture for remaining food
    }
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
      
      await _analyzeFoodImage();
    } catch (e) {
      print('Error mengambil gambar: $e');
    }
  }

  void _switchCamera() async {
    if (cameras == null || cameras!.isEmpty || cameras!.length <= 1) return;
    
    _selectedCameraIndex = (_selectedCameraIndex + 1) % cameras!.length;
    
    await cameraController?.dispose();
    
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final result = await provider.scanFoodImage(_image!);
      
      if (result != null) {
        setState(() {
          _scanResult = result;
          _foodName = result['foodName'] as String?;
          _carbonFootprint = provider.calculateCarbonEmission(
            (result['estimatedWeight'] as num?)?.toDouble() ?? 0.0
          );
          
          if (!widget.isRemainingFoodScan) {
            if (result['estimatedWeight'] != null && result['estimatedWeight'] is num) {
              _weightController.text = (result['estimatedWeight'] as num).toStringAsFixed(0);
            }
          }
          
          // Handle foodItems from AIService (now returns List<FoodItem>)
          if (result.containsKey('foodItems') && result['foodItems'] is List) {
            if (!widget.isRemainingFoodScan) {
              _foodItems = (result['foodItems'] as List).whereType<FoodItem>().toList();
            } else if (widget.originalScan != null) {
              // For remaining scan, copy from original and set initial remaining weight
              _foodItems = List<FoodItem>.from(widget.originalScan!.foodItems.map((item) => 
                item.copyWith(remainingWeight: item.weight) // Ensure remainingWeight is set for adjustment
              ));
              _updateTotalWeightFromFoodItems(); 
            }
            // If foodItems is empty after AI processing and it's a new scan, add a default item.
            if (_foodItems.isEmpty && !widget.isRemainingFoodScan) {
               final defaultWeight = (result['estimatedWeight'] as num?)?.toDouble() ?? 100.0;
              _foodItems = [FoodItem(itemName: _foodName ?? 'Default Food Item', weight: defaultWeight, remainingWeight: null)];
            }
          } else if (!widget.isRemainingFoodScan) {
            // Fallback if foodItems key is missing or not a list for a new scan
            final defaultWeight = (result['estimatedWeight'] as num?)?.toDouble() ?? 100.0;
            _foodItems = [FoodItem(itemName: _foodName ?? 'Default Food Item', weight: defaultWeight, remainingWeight: null)];
          }
          
          // Handle potentialFoodWasteItems from AIService (now returns List<PotentialFoodWasteItem>)
          if (result.containsKey('potentialFoodWasteItems') && result['potentialFoodWasteItems'] is List) {
            _potentialFoodWasteItems = (result['potentialFoodWasteItems'] as List).whereType<PotentialFoodWasteItem>().toList();
          } else {
            _potentialFoodWasteItems = []; // Default to empty list
          }
          
          _isAnalyzing = false;
          _analysisComplete = true;
        });

        if (authProvider.user != null) {
          final firestoreService = FirestoreService();
          await firestoreService.updateQuestProgress(authProvider.user!.id, 'scan', {'scanCount': 1});
        }

      } else {
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
      // _count = 1; // Count should persist or be handled differently if it's per session
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
      _flashlightOn = false;
      if (widget.isRemainingFoodScan && widget.originalScan != null) {
        _foodName = widget.originalScan!.foodName;
        _foodItems = List<FoodItem>.from(widget.originalScan!.foodItems);
        _weightController.text = _calculateTotalOriginalWeight().toStringAsFixed(0);
      }
    });
    _initializeCamera(); // Re-initialize camera for a fresh start
  }

  void _removeWasteItem(int index) {
    setState(() {
      _potentialFoodWasteItems.removeAt(index);
    });
  }

  void _addNewWasteItem() {
    if (_newItemNameController.text.isEmpty || _newItemWeightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan berat item harus diisi')),
      );
      return;
    }
    
    double? weight = double.tryParse(_newItemWeightController.text);
    if (weight == null || weight <=0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berat harus berupa angka positif')),
      );
      return;
    }
    
    // Assuming carbon emission is related to weight for now for simplicity
    // This logic might need to be more sophisticated based on actual requirements
    double estimatedEmission = weight * 0.01; // Example: 10g waste = 0.1 kg CO2e
    
    setState(() {
      _potentialFoodWasteItems.add(
        PotentialFoodWasteItem(
          itemName: _newItemNameController.text,
          estimatedCarbonEmission: estimatedEmission, // This should be weight or a calculation based on it
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
      if (_showAddItemForm) {
        _showAddFoodItemForm = false; // Close other form if open
        _newItemNameController.clear();
        _newItemWeightController.clear();
      }
    });
  }

  void _addNewFoodItem() {
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
          remainingWeight: widget.isRemainingFoodScan ? weight : null,
        ),
      );
      _showAddFoodItemForm = false;
      _newItemNameController.clear();
      _newItemWeightController.clear();
      _updateTotalWeightFromFoodItems();
    });
  }

  void _toggleAddFoodItemForm() {
    setState(() {
      _showAddFoodItemForm = !_showAddFoodItemForm;
      if (_showAddFoodItemForm) {
        _showAddItemForm = false; // Close other form if open
        _newItemNameController.clear();
        _newItemWeightController.clear();
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
        remainingWeight: widget.isRemainingFoodScan ? newWeight : item.remainingWeight,
      );
      _updateTotalWeightFromFoodItems();
    });
  }

  void _removeFoodItem(int index) {
    if (index < 0 || index >= _foodItems.length) return;
    
    setState(() {
      _foodItems.removeAt(index);
      _updateTotalWeightFromFoodItems();
    });
  }
      
  void _updateTotalWeightFromFoodItems() {
      double totalWeight = _foodItems.fold(0, (sum, item) => sum + item.weight);
    _weightController.text = totalWeight.toStringAsFixed(0);
    // If it's a remaining food scan, recalculate percentage
    if (widget.isRemainingFoodScan) {
        setState(() {}); // Trigger rebuild to update percentage display
    }
  }

  void _saveFoodScan() async {
    if (_foodName == null && !widget.isRemainingFoodScan) { // For new scan, foodName must exist
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Food data is incomplete. Name is missing.')),
      );
      return;
    }

    double? weight = double.tryParse(_weightController.text);

    if (weight == null || weight < 0) { // Weight can be 0 if eaten completely
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid non-negative food weight.')),
      );
      return;
    }

    if (_foodItems.isEmpty && !widget.isRemainingFoodScan) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one food item component.')),
      );
      return;
    }
     if (widget.isRemainingFoodScan && _isEaten) {
        weight = 0;
        _weightController.text = '0';
        // Ensure all food items have remaining weight as 0 if eaten completely
        for (int i = 0; i < _foodItems.length; i++) {
          _foodItems[i] = _foodItems[i].copyWith(remainingWeight: 0);
        }
    } else if (widget.isRemainingFoodScan) {
        // Ensure remaining weights are consistent with the total current weight for leftover food
        final currentTotalWeight = weight; // This is the manually entered or slider-adjusted total
        final originalTotalWeight = _calculateTotalOriginalWeight();

        if (originalTotalWeight > 0) {
            for (int i = 0; i < _foodItems.length; i++) {
                final item = _foodItems[i];
                // Distribute the currentTotalWeight proportionally based on original item weights
                final proportion = item.weight / originalTotalWeight;
                _foodItems[i] = item.copyWith(remainingWeight: currentTotalWeight * proportion);
            }
        } else if (_foodItems.isNotEmpty) {
            // If original weight was 0 but there are items, distribute equally or handle as error
            // For simplicity, let's just set remaining to current item weight (which should sum up to total)
             _foodItems.forEach((item) => item.copyWith(remainingWeight: item.weight));
        }
    }

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
        setState(() {
          _isSaving = false;
        });
        return;
      }

      if (widget.isRemainingFoodScan && widget.originalScan != null) {
        final totalRemainingWeight = weight; // This is the final weight
        final originalWeight = _calculateTotalOriginalWeight();
        final remainingPercentage = (originalWeight > 0 && totalRemainingWeight != null) 
            ? (totalRemainingWeight / originalWeight) * 100 
            : (_isEaten ? 0.0 : 100.0); // if original is 0, if eaten is 0%, else 100%
        
        final updatedFoodItems = _foodItems.map((item) {
            double itemOriginalWeight = widget.originalScan!.foodItems
                .firstWhere((originalItem) => originalItem.itemName == item.itemName, orElse: () => item)
                .weight;
            double itemRemainingWeight = 0;
            if (originalWeight > 0 && totalRemainingWeight != null) {
                itemRemainingWeight = itemOriginalWeight * (totalRemainingWeight / originalWeight);
            }
             if (_isEaten) itemRemainingWeight = 0; // Ensure this is respected

            return item.copyWith(remainingWeight: itemRemainingWeight.isNaN ? 0 : itemRemainingWeight);
        }).toList();

        final updatedScan = widget.originalScan!.copyWith(
          isDone: true,
          isEaten: _isEaten,
          foodItems: updatedFoodItems,
          aiRemainingPercentage: remainingPercentage.isNaN ? (_isEaten ? 0 : 100) : remainingPercentage, 
          afterImageUrl: null, // Will be set by provider if _image is not null
          finishTime: DateTime.now(),
        );
        
        final success = await provider.updateFoodScan(updatedScan, imageFile: _image);
        
        setState(() {
          _isSaving = false;
        });
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEaten ? 'Food marked as eaten!' : 'Leftover food scan successful! ${remainingPercentage.toStringAsFixed(1)}% of food remaining'
              ),
            ),
          );
          
          Navigator.pop(context); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save leftover data: ${provider.error}')),
          );
        }
      } else {
        final foodScan = FoodScanModel(
          id: '', 
          userId: authProvider.user!.id,
          count: _count,
          foodName: _foodName ?? 'Unidentified Food',
          scanTime: DateTime.now(),
          finishTime: null,
          isDone: false,
          isEaten: false,
          foodItems: _foodItems,
          potentialFoodWasteItems: _potentialFoodWasteItems.isNotEmpty ? _potentialFoodWasteItems : null,
          imageUrl: null, 
        );

        final success = await provider.addFoodScan(foodScan, imageFile: _image);

        setState(() {
          _isSaving = false;
        });
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Food scan saved successfully!')),
          );

          if (authProvider.user != null) {
            final firestoreService = FirestoreService();
            await firestoreService.updateUserPoints(authProvider.user!.id, 5);
          }

          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (BuildContext context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(24.0), 
                  content: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8, 
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Congratulations!',
                          style: TextStyle(
                            fontSize: 28, 
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "You've earned 5 points",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Image.asset(
                        'assets/icons/point_icon_anim.gif',
                        width: 128,
                        height: 128,
                      ),
                      ],
                    ),
                  ),
                  actions: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor, 
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'OK',
                          style: TextStyle(fontSize: 16), 
                        ),
                      ),
                    ),
                  ],
                );
              },
            ).then((_) {
              _resetScan(); // Reset after dialog and before pop if needed
              if (mounted && Navigator.canPop(context)) {
                 Navigator.pop(context); // Go back to previous screen
              }
            });
          } else {
            _resetScan();
             if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
             }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save data: ${provider.error}')),
          );
        }
      }
    } catch (e) {
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
    // Fallback if not a remaining scan or no original items, use current food items if any
    if (_foodItems.isNotEmpty) {
        return _foodItems.fold(0, (sum, item) => sum + item.weight);
    }
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
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icons/camera_icon_anim.gif',
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 20),
                    const Text(
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
                  // Use ResultView here
                  : ResultView(
                      image: _image,
                      imageUrl: null,
                      isRemainingFoodScan: widget.isRemainingFoodScan,
                      originalScan: widget.originalScan,
                      foodName: _foodName,
                      scanResult: _scanResult,
                      carbonFootprint: _carbonFootprint,
                      foodItems: _foodItems,
                      potentialFoodWasteItems: _potentialFoodWasteItems,
                      isEaten: _isEaten,
                      isSaving: _isSaving,
                      showAddItemForm: _showAddItemForm,
                      weightController: _weightController,
                      newItemNameController: _newItemNameController,
                      newItemWeightController: _newItemWeightController,
                      formatTime: _formatTime,
                      formatDuration: _formatDuration,
                      calculateTotalOriginalWeight: _calculateTotalOriginalWeight,
                      calculatePercentageRemaining: _calculatePercentageRemaining,
                      scanTime: widget.originalScan?.scanTime ?? DateTime.now(),
                      count: _count,
                      onCountChanged: _updateCount,
                      onIsEatenChanged: (value) {
                        setState(() {
                          _isEaten = value;
                          if (_isEaten) {
                            _weightController.text = '0';
                            // Also update underlying foodItems to reflect 0 remaining weight for consistency upon saving
                            _foodItems = _foodItems.map((item) => item.copyWith(remainingWeight: 0)).toList();
                          } else {
                            // If unchecked, restore weight from food items sum
                            _updateTotalWeightFromFoodItems();
                          }
                           setState(() {}); // Trigger rebuild for percentage
                        });
                      },
                      onWeightChanged: (value) {
                        // Trigger rebuild to update percentage calculation if it's a remaining food scan
                        if (widget.isRemainingFoodScan) {
                          setState(() {});
                        }
                      },
                      toggleAddFoodItemForm: _toggleAddFoodItemForm,
                      addNewFoodItem: _addNewFoodItem,
                      updateFoodItemWeight: _updateFoodItemWeight,
                      removeFoodItem: _removeFoodItem,
                      toggleAddItemForm: _toggleAddItemForm,
                      addNewWasteItem: _addNewWasteItem,
                      removeWasteItem: _removeWasteItem,
                      resetScan: _resetScan,
                      saveFoodScan: _saveFoodScan,
                      onBackPressed: () {
                        if (widget.isRemainingFoodScan || _analysisComplete || _image != null) {
                          _resetScan(); // Go back to camera view or initial state for result view
                        } else {
                          Navigator.of(context).pop(); // Default back otherwise
                        }
                      },
                    ),
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
              child: Image.asset(
                'assets/icons/check_icon_anim.gif',
                width: 120,
                height: 120,
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
    if (!_isCameraInitialized || cameraController == null || !cameraController!.value.isInitialized) {
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

    return OrientationBuilder(
      builder: (context, orientation) {
        final CameraController controller = cameraController!;
        double previewAspectRatio;
        final double sensorAspectRatio = controller.value.aspectRatio;

        if (orientation == Orientation.portrait) {
          previewAspectRatio = sensorAspectRatio > 1 ? (1 / sensorAspectRatio) : sensorAspectRatio;
        } else { // Orientation.landscape
          previewAspectRatio = sensorAspectRatio > 1 ? sensorAspectRatio : (1 / sensorAspectRatio);
        }

        Widget cameraPreviewWidget = CameraPreview(controller);
        if (controller.description.lensDirection == CameraLensDirection.front) {
          cameraPreviewWidget = Transform.scale(
            scaleX: -1,
            child: cameraPreviewWidget,
          );
        }

        return Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: 100.0,
                  child: AspectRatio(
                    aspectRatio: previewAspectRatio,
                    child: cameraPreviewWidget, 
                  ),
                ),
              ),
            ),
            
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
                    CircleAvatar(
                      backgroundColor: Colors.white54,
                      radius: 25,
                      child: IconButton(
                        icon: const Icon(Icons.flip_camera_ios, color: Colors.black, size: 25),
                        onPressed: _switchCamera,
                      ),
                    ),
                    
                    const SizedBox(width: 40),
                    
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
      },
    );
  }

  // Helper functions that remain in ScanScreenState or are passed as callbacks
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
  
  double _calculatePercentageRemaining() {
    if (widget.originalScan == null && !_foodItems.isNotEmpty) return 0.0;
    
    final currentWeight = double.tryParse(_weightController.text) ?? 0.0;
    // For remaining scan, original weight is from originalScan.foodItems
    // For new scan, if we want to show a similar concept (e.g. based on initial detection vs. manual adjustment)
    // we might need another reference point. For now, let's use _calculateTotalOriginalWeight() which handles both.
    final referenceWeight = _calculateTotalOriginalWeight(); 
    
    if (referenceWeight <= 0) {
      // If reference is 0, and current is > 0, it implies 100% if we consider current as the new base.
      // Or 0% if nothing to compare against. Let's assume 0% if no valid reference.
      // If isEaten is true, it must be 0%.
      return _isEaten ? 0.0 : (currentWeight > 0 && referenceWeight == 0 ? 100.0 : 0.0) ;
    }
    if (_isEaten) return 0.0; // If marked as eaten, always 0%
    
    double percentage = (currentWeight / referenceWeight) * 100;
    return percentage.clamp(0.0, 100.0); // Clamp between 0 and 100
  }

  // Callback to update the count from ResultView
  void _updateCount(int newCount) {
    if (newCount > 0) { // Basic validation for count
      setState(() {
        _count = newCount;
      });
    }
  }
}