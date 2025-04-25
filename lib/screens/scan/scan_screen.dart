import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../../providers/food_scan_provider.dart';
import '../../models/food_scan_model.dart';
import '../../utils/app_colors.dart';
import '../../providers/auth_provider.dart';

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
        const SnackBar(content: Text('Data makanan tidak lengkap.')),
      );
      return;
    }

    double? weight;
    if (_weightController.text.isNotEmpty) {
      weight = double.tryParse(_weightController.text);
    }

    if (weight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan berat makanan yang valid.')),
      );
      return;
    }

    try {
      final provider = Provider.of<FoodScanProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anda perlu login untuk menyimpan data makanan.')),
        );
        return;
      }

      if (widget.isRemainingFoodScan && widget.originalScan != null) {
        // Proses untuk sisa makanan
        final totalRemainingWeight = weight;
        final originalWeight = _calculateTotalOriginalWeight();
        final remainingPercentage = (totalRemainingWeight / originalWeight) * 100;
        
        // Perbarui remaining weight untuk setiap food item
        for (int i = 0; i < _foodItems.length; i++) {
          final item = _foodItems[i];
          // Hitung sisa berdasarkan persentase (bisa dioptimasi lebih lanjut)
          final remainingWeight = item.weight * (totalRemainingWeight / originalWeight);
          _foodItems[i] = FoodItem(
            itemName: item.itemName,
            weight: item.weight,
            remainingWeight: remainingWeight,
          );
        }
        
        // Update makanan yang sudah ada
        final updatedScan = widget.originalScan!.copyWith(
          isDone: true,
          isEaten: _isEaten,
          foodItems: _foodItems,
          aiRemainingPercentage: remainingPercentage,
          afterImageUrl: null,
        );
        
        final success = await provider.updateFoodScan(updatedScan, imageFile: _image);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Pemindaian sisa makanan berhasil! ${remainingPercentage.toStringAsFixed(1)}% makanan tersisa'
              ),
            ),
          );
          
          Navigator.pop(context); // Kembali ke halaman sebelumnya
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan data sisa: ${provider.error}')),
          );
        }
      } else {
        // Proses untuk makanan baru
        final foodScan = FoodScanModel(
          id: '', // Akan diberikan oleh Firestore
          userId: authProvider.user!.id,
          foodName: _foodName ?? 'Makanan tidak teridentifikasi',
          scanTime: DateTime.now(),
          finishTime: DateTime.now().add(const Duration(days: 7)),
          isDone: false,
          isEaten: false,
          foodItems: _foodItems,
          potentialFoodWasteItems: _potentialFoodWasteItems.isNotEmpty ? _potentialFoodWasteItems : null,
          imageUrl: null, // URL gambar akan diatur setelah upload ke Firebase Storage
        );

        final success = await provider.addFoodScan(foodScan, imageFile: _image);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pemindaian makanan berhasil disimpan!')),
          );
          
          // Reset the scan view
          _resetScan();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan data: ${provider.error}')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error menyimpan data: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isRemainingFoodScan 
            ? 'Pindai Sisa Makanan' 
            : (_showCameraView ? 'Pindai Makanan' : 'Hasil Pemindaian')),
        actions: [
          if (!_showCameraView)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetScan,
              tooltip: 'Pindai Ulang',
            ),
        ],
      ),
      body: _isAnalyzing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Menganalisis makanan...'),
                ],
              ),
            )
          : _showCameraView
              ? _buildCameraView()
              : _buildResultView(),
    );
  }

  Widget _buildCameraView() {
    if (!_isCameraInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Menginisialisasi kamera...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              // Camera preview
              CameraPreview(cameraController!),
              
              // Bottom controls overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Switch camera button
                      IconButton(
                        icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 32),
                        onPressed: _switchCamera,
                      ),
                      
                      // Capture button
                      GestureDetector(
                        onTap: _takePicture,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            margin: const EdgeInsets.all(8),
                          ),
                        ),
                      ),
                      
                      // Placeholder to balance the layout
                      const SizedBox(width: 50),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info tentang scan sisa makanan
          if (widget.isRemainingFoodScan && widget.originalScan != null)
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informasi Makanan Awal',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Makanan: ${widget.originalScan!.foodName}'),
                    Text('Berat total: ${_calculateTotalOriginalWeight().toStringAsFixed(1)} gram'),
                    const SizedBox(height: 12),
                    const Text(
                      'Pindai sisa makanan untuk memperkirakan berapa persen yang tersisa',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),

          // Menampilkan preview gambar
          if (_image != null)
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: FileImage(_image!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const SizedBox(height: 16),
          
          // Menampilkan hasil analisis
          if (_foodName != null)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Makanan Terdeteksi: $_foodName',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Carbon Footprint: ${_carbonFootprint?.toStringAsFixed(2)} kg CO₂e',
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (_scanResult?['confidence'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tingkat Keyakinan:'),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: (_scanResult!['confidence'] is num)
                                ? (_scanResult!['confidence'] as num).toDouble()
                                : 0.0,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                (_scanResult!['confidence'] is num && (_scanResult!['confidence'] as num).toDouble() > 0.7)
                                  ? Colors.green
                                  : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Tampilkan persentase sisa makanan jika ini adalah scan untuk sisa makanan
                    if (widget.isRemainingFoodScan && widget.originalScan != null && double.tryParse(_weightController.text) != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Perkiraan Sisa Makanan',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              _buildPercentageIndicator(),
                              const SizedBox(height: 8),
                              Text(
                                'Berat sisa: ${double.tryParse(_weightController.text)?.toStringAsFixed(1) ?? '0'} gram',
                              ),
                              Text(
                                'Persentase sisa: ${_calculatePercentageRemaining().toStringAsFixed(1)}%',
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Tampilkan daftar item makanan
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Komponen Makanan',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(_showAddFoodItemForm ? Icons.remove : Icons.add),
                        onPressed: _toggleAddFoodItemForm,
                        tooltip: _showAddFoodItemForm ? 'Tutup Form' : 'Tambah Item',
                      ),
                    ],
                  ),
                  
                  if (_showAddFoodItemForm) ...[
                    const SizedBox(height: 12),
                    const Text('Tambahkan Komponen Makanan:'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _newItemNameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Nama Item',
                        hintText: 'contoh: Ayam Goreng',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _newItemWeightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Berat (gram)',
                        hintText: 'contoh: 150',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addNewFoodItem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Tambahkan Item'),
                      ),
                    ),
                    const Divider(height: 24),
                  ],
                  
                  const SizedBox(height: 8),
                  if (_foodItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'Tidak ada komponen makanan terdeteksi',
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
                              // Slider untuk menyesuaikan berat
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
          ),
          const SizedBox(height: 24),
          
          // Tampilkan potensi foodwaste items yang dapat dimodifikasi
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Potensi Item Foodwaste',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(_showAddItemForm ? Icons.remove : Icons.add),
                        onPressed: _toggleAddItemForm,
                        tooltip: _showAddItemForm ? 'Tutup Form' : 'Tambah Item',
                      ),
                    ],
                  ),
                  
                  if (_showAddItemForm) ...[
                    const SizedBox(height: 12),
                    const Text('Tambahkan Item Foodwaste Baru:'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _newItemNameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Nama Item',
                        hintText: 'contoh: Tulang Ayam',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _newItemWeightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Berat (gram)',
                        hintText: 'contoh: 25',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addNewWasteItem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Tambahkan Item'),
                      ),
                    ),
                    const Divider(height: 24),
                  ],
                  
                  const SizedBox(height: 8),
                  if (_potentialFoodWasteItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'Tidak ada item foodwaste yang terdeteksi',
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
                            padding: const EdgeInsets.symmetric(vertical: 4),
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
                      'Geser item ke kiri untuk menghapus',
                      style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hindari membuang sisa makanan untuk mengurangi carbon footprint.',
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Form untuk berat makanan
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Berat Total Makanan (gram)',
              hintText: 'Contoh: 250',
            ),
            onChanged: (value) {
              // Trigger rebuild untuk memperbarui perhitungan persentase
              if (widget.isRemainingFoodScan) {
                setState(() {});
              }
            },
          ),
          const SizedBox(height: 16),
          
          // Switch untuk menandai makanan sudah dimakan
          if (widget.isRemainingFoodScan)
            SwitchListTile(
              title: Text(
                'Makanan habis dimakan',
                style: TextStyle(
                  color: _isEaten ? Colors.green : Colors.black,
                ),
              ),
              value: _isEaten,
              onChanged: (value) {
                setState(() {
                  _isEaten = value;
                  // Jika habis dimakan, set berat sisa menjadi 0
                  if (_isEaten) {
                    _weightController.text = '0';
                  }
                });
              },
              activeColor: AppColors.primaryColor,
            ),
          const SizedBox(height: 24),
          
          // Tombol simpan
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveFoodScan,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: AppColors.primaryColor,
              ),
              child: Text(
                widget.isRemainingFoodScan ? 'Simpan Data Sisa Makanan' : 'Simpan Data Makanan',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Tombol ambil ulang gambar
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _resetScan,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Ambil Ulang Foto',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
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