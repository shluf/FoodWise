import 'dart:io';
import 'package:flutter/material.dart';
import '../models/food_scan_model.dart';
import '../services/firestore_service.dart';
import '../services/ai_service.dart';
import '../services/widget_service.dart';
import '../services/storage_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FoodScanProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final AIService _aiService;
  
  List<FoodScanModel> _foodScans = [];
  bool _isLoading = false;
  String? _error;
  Map<DateTime, double> _weeklyFoodWaste = {};
  String? userId;
  
  // Statistik total untuk aplikasi
  double _totalWaste = 0.0;
  double _totalCarbonSaved = 0.0;
  
  // Menyimpan path gambar yang sudah diambil sebelumnya untuk overlay
  File? _lastCapturedImage;
  
  FoodScanProvider(String apiKey) : _aiService = AIService(apiKey) {
    // Muat ulang data saat provider diinisialisasi
    _initialize();
  }

  void _initialize() {
    // Pastikan userId diatur sebelum memanggil ini
    final userId = _getCurrentUserId();
    if (userId != null) {
      loadUserFoodScans(userId);
    }
  }

  String? _getCurrentUserId() {
    // Ambil userId dari Firebase Authentication
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }
  
  List<FoodScanModel> get foodScans => _foodScans;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<DateTime, double> get weeklyFoodWaste => _weeklyFoodWaste;
  double get totalWaste => _totalWaste;
  double get totalCarbonSaved => _totalCarbonSaved;
  File? get lastCapturedImage => _lastCapturedImage;
  
  Future<void> loadUserFoodScans(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final foodScansStream = _firestoreService.getUserFoodScans(userId);
      foodScansStream.listen((foodScans) {
        _foodScans = foodScans;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      print('Error loading user food scans: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<Map<String, dynamic>?> scanFoodImage(File imageFile) async {
    try {
      _setLoading(true);
      var scanResult = await _aiService.scanFoodImage(imageFile);
      
      // Simpan gambar untuk digunakan nanti sebagai overlay
      _lastCapturedImage = await _saveImageLocally(imageFile);
      
      return scanResult;
    } catch (e) {
      _error = 'Gagal memindai gambar makanan: $e';
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> addFoodScan(FoodScanModel foodScan, {File? imageFile}) async {
    try {
      _setLoading(true);
      _error = null;
      
      // Upload gambar jika ada
      String? imageUrl;
      if (imageFile != null) {
        // Pastikan Firebase benar-benar siap
        await Future.delayed(const Duration(seconds: 1));
        
        // Coba upload dengan retry
        int retryCount = 0;
        while (retryCount < 3) {
          try {
            imageUrl = await _storageService.uploadFoodImage(imageFile, foodScan.userId);
            if (imageUrl != null) break;
            retryCount++;
            await Future.delayed(const Duration(seconds: 1));
          } catch (e) {
            print('Upload retry $retryCount failed: $e');
            retryCount++;
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      }
      
      // Update model dengan URL gambar
      final updatedFoodScan = imageUrl != null ? foodScan.copyWith(imageUrl: imageUrl) : foodScan;
      
      // Simpan ke Firestore
      final docId = await _firestoreService.addFoodScan(updatedFoodScan);
      
      // Jika sukses, perbarui statistik lokal dan widget
      final scanWithId = FoodScanModel(
        id: docId,
        userId: updatedFoodScan.userId,
        foodName: updatedFoodScan.foodName,
        scanTime: updatedFoodScan.scanTime,
        finishTime: updatedFoodScan.finishTime,
        isDone: updatedFoodScan.isDone,
        isEaten: updatedFoodScan.isEaten,
        foodItems: updatedFoodScan.foodItems,
        imageUrl: updatedFoodScan.imageUrl,
        afterImageUrl: updatedFoodScan.afterImageUrl,
        aiRemainingPercentage: updatedFoodScan.aiRemainingPercentage,
        aiConfidence: updatedFoodScan.aiConfidence,
        potentialFoodWasteItems: updatedFoodScan.potentialFoodWasteItems,
      );
      _foodScans.add(scanWithId);
      _calculateTotalStatistics();
      _updateWidget();
      
      return true;
    } catch (e) {
      _error = 'Gagal menambahkan scan makanan: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Scan food waste with overlay
  Future<Map<String, dynamic>> scanFoodWaste(File afterImageFile, String foodScanId) async {
    try {
      _setLoading(true);
      _error = null;
      
      // Cari data scan makanan dengan ID yang diberikan
      final originalScan = _foodScans.firstWhere(
        (scan) => scan.id == foodScanId,
        orElse: () => throw Exception('Food scan tidak ditemukan'),
      );
      
      // Pastikan ada URL gambar asli
      if (originalScan.imageUrl == null || originalScan.imageUrl!.isEmpty) {
        throw Exception('Tidak ada gambar asli untuk dibandingkan');
      }
      
      // Download gambar asli jika belum ada di lokal
      File beforeImageFile;
      if (_lastCapturedImage == null) {
        // Download dari Firebase Storage
        beforeImageFile = await _storageService.downloadFoodImage(originalScan.imageUrl!);
      } else {
        beforeImageFile = _lastCapturedImage!;
      }
      
      // Upload gambar makanan tersisa ke Storage dengan format nama yang konsisten
      final originalImageName = _extractImageName(originalScan.imageUrl!);
      final afterImageFileName = originalImageName != null ? 
          'after_$originalImageName' : 'after_food_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      String? afterImageUrl;
      int retryCount = 0;
      while (retryCount < 3) {
        try {
          afterImageUrl = await _storageService.uploadFoodImageWithName(
            afterImageFile, 
            originalScan.userId,
            afterImageFileName
          );
          if (afterImageUrl != null) break;
          retryCount++;
          await Future.delayed(const Duration(seconds: 1));
        } catch (e) {
          print('Upload after image retry $retryCount failed: $e');
          retryCount++;
          await Future.delayed(const Duration(seconds: 1));
        }
      }
      
      if (afterImageUrl == null) {
        throw Exception('Gagal mengupload gambar setelah makanan dimakan');
      }
      
      // Bandingkan gambar dengan Gemini AI
      final comparisonResult = await _aiService.compareFoodImages(
        beforeImageFile,
        afterImageFile,
      );
      
      // Hitung berat makanan tersisa berdasarkan persentase
      final remainingPercentage = comparisonResult['remainingPercentage'];
      final confidence = comparisonResult['confidence'];
      
      // Hitung remaining weight untuk setiap food item
      List<FoodItem> updatedFoodItems = [];
      double totalOriginalWeight = 0;
      
      // Hitung total berat original
      for (var item in originalScan.foodItems) {
        totalOriginalWeight += item.weight;
      }
      
      // Update setiap food item dengan remaining weight
      for (var item in originalScan.foodItems) {
        // Hitung sisa berdasarkan persentase
        final remainingWeight = item.weight * (remainingPercentage / 100);
        updatedFoodItems.add(FoodItem(
          itemName: item.itemName,
          weight: item.weight,
          remainingWeight: remainingWeight,
        ));
      }
      
      // Update data di Firestore
      final updatedScan = originalScan.copyWith(
        isDone: true,
        isEaten: remainingPercentage <= 5, // Jika sisa kurang dari 5%, anggap habis
        foodItems: updatedFoodItems,
        afterImageUrl: afterImageUrl,
        aiRemainingPercentage: remainingPercentage,
        aiConfidence: confidence,
      );
      
      await _firestoreService.updateFoodScan(updatedScan);
      
      // Update juga di data lokal
      final index = _foodScans.indexWhere((scan) => scan.id == foodScanId);
      if (index != -1) {
        _foodScans[index] = updatedScan;
      }
      
      _calculateTotalStatistics();
      _updateWidget();
      
      return {
        'remainingPercentage': remainingPercentage,
        'confidence': confidence,
        'remainingWeight': totalOriginalWeight * (remainingPercentage / 100),
      };
    } catch (e) {
      _error = 'Gagal memindai sisa makanan: $e';
      return {
        'remainingPercentage': 50.0,
        'confidence': 0.5,
        'remainingWeight': 0.0,
      };
    } finally {
      _setLoading(false);
    }
  }
  
  // Helper untuk mengekstrak nama file dari URL Firebase Storage
  String? _extractImageName(String url) {
    try {
      // Firebase Storage URL biasanya memiliki format: 
      // https://firebasestorage.googleapis.com/v0/b/[bucket]/o/[path]?token=[token]
      // Kita perlu mengambil [path] dan mendecode-nya
      
      // Parse URL
      final uri = Uri.parse(url);
      
      final pathSegment = uri.path.split('/o/').last;
      
      final decodedPath = Uri.decodeComponent(pathSegment);
      
      final segments = decodedPath.split('/');
      final fileName = segments.last;
      
      return fileName;
    } catch (e) {
      print('Error extracting image name from URL: $e');
      return null;
    }
  }
  
  // Helper untuk menyimpan gambar secara lokal
  Future<File> _saveImageLocally(File imageFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'last_food_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await imageFile.copy('${appDir.path}/$fileName');
      return savedFile;
    } catch (e) {
      print('Error saving image locally: $e');
      return imageFile;
    }
  }
  
  Future<String?> getOverlayImagePath(String foodScanId) async {
    try {
      if (_lastCapturedImage != null && _lastCapturedImage!.existsSync()) {
        return _lastCapturedImage!.path;
      }
      
      final originalScan = _foodScans.firstWhere(
        (scan) => scan.id == foodScanId,
        orElse: () => throw Exception('Food scan tidak ditemukan'),
      );
      
      if (originalScan.imageUrl == null || originalScan.imageUrl!.isEmpty) {
        return null;
      }
      
      final downloadedFile = await _storageService.downloadFoodImage(originalScan.imageUrl!);
      _lastCapturedImage = downloadedFile;
      return downloadedFile.path;
    } catch (e) {
      print('Error getting overlay image path: $e');
      return null;
    }
  }
  
  Future<bool> updateFoodScan(FoodScanModel foodScan, {File? imageFile}) async {
    try {
      _setLoading(true);
      _error = null;
      
      // Upload gambar baru jika ada
      String? imageUrl = foodScan.imageUrl;
      if (imageFile != null) {
        // Hapus gambar lama jika ada
        if (foodScan.imageUrl != null && foodScan.imageUrl!.isNotEmpty) {
          await _storageService.deleteFoodImage(foodScan.imageUrl!);
        }
        
        // Upload gambar baru
        imageUrl = await _storageService.uploadFoodImage(imageFile, foodScan.userId);
      }
      
      // Update model dengan URL gambar baru
      final updatedFoodScan = imageUrl != null ? foodScan.copyWith(imageUrl: imageUrl) : foodScan;
      
      // Update di Firestore
      await _firestoreService.updateFoodScan(updatedFoodScan);
      
      // Perbarui foodScan dalam list lokal
      final index = _foodScans.indexWhere((item) => item.id == updatedFoodScan.id);
      if (index != -1) {
        _foodScans[index] = updatedFoodScan;
      }
      
      _calculateTotalStatistics();
      _updateWidget();
      
      return true;
    } catch (e) {
      _error = 'Gagal memperbarui scan makanan: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> deleteFoodScan(String foodScanId) async {
    try {
      _setLoading(true);
      _error = null;
      
      // Cari data scan makanan
      final foodScan = _foodScans.firstWhere((scan) => scan.id == foodScanId, orElse: () => null as FoodScanModel);
      
      // Hapus gambar jika ada
      if (foodScan.imageUrl != null && foodScan.imageUrl!.isNotEmpty) {
        await _storageService.deleteFoodImage(foodScan.imageUrl!);
      }
      
      // Hapus gambar kedua jika ada
      if (foodScan.afterImageUrl != null && foodScan.afterImageUrl!.isNotEmpty) {
        await _storageService.deleteFoodImage(foodScan.afterImageUrl!);
      }
      
      // Hapus dari Firestore
      await _firestoreService.deleteFoodScan(foodScanId);
      
      // Hapus dari list lokal
      _foodScans.removeWhere((item) => item.id == foodScanId);
      _calculateTotalStatistics();
      _updateWidget();
      
      return true;
    } catch (e) {
      _error = 'Gagal menghapus scan makanan: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> loadWeeklyFoodWaste(String userId) async {
    try {
      _setLoading(true);
      _error = null;
      
      _weeklyFoodWaste = await _firestoreService.getTotalFoodWasteByWeek(userId);
      
    } catch (e) {
      _error = 'Gagal memuat data food waste: $e';
    } finally {
      _setLoading(false);
    }
  }
  
  double calculateCarbonEmission(double foodWasteWeight) {
    return _aiService.calculateCarbonEmission(foodWasteWeight);
  }
  
  void _calculateTotalStatistics() {
    if (_foodScans.isEmpty) {
      _totalWaste = 0.0;
      _totalCarbonSaved = 0.0;
      return;
    }
    
    double totalWaste = 0.0;
    for (var scan in _foodScans) {
      // Jika makanan sudah selesai
      if (scan.isDone) {
        // Hitung total sisa makanan
        double remainingWeight = 0;
        for (var item in scan.foodItems) {
          if (item.remainingWeight != null) {
            remainingWeight += item.remainingWeight!;
          }
        }
        totalWaste += remainingWeight;
      }
    }
    
    _totalWaste = totalWaste;
    _totalCarbonSaved = totalWaste * 2.5; // Estimasi kasar: 1kg food waste = 2.5kg CO2
  }
  
  Future<void> _updateWidget() async {
    try {
      await WidgetService.updateWidgetStatistics(
        totalWaste: _totalWaste,
        carbonSaved: _totalCarbonSaved,
      );
      
      // Update daftar makanan yang belum selesai
      try {
        final unfinishedFoods = _foodScans.where((scan) => !scan.isDone).toList();
        if (unfinishedFoods.isNotEmpty) {
          await WidgetService.updateUnfinishedFoods(unfinishedFoods);
        }
      } catch (e) {
        print('Error updating unfinished foods in widget: $e');
        // Error ini tidak kritis, jadi aplikasi masih bisa berjalan
      }
    } catch (e) {
      print('Error updating widget: $e');
    }
  }
  
  Future<bool> checkLaunchFromWidget() async {
    return WidgetService.checkLaunchForScan();
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setUserId(String? newUserId) {
    if (userId != newUserId && newUserId != null) {
      userId = newUserId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        loadUserFoodScans(newUserId);
      });
    } else {
      userId = newUserId;
    }
  }
}