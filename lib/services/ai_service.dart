import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../models/food_scan_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AIService {
  final String _apiKey; 
  late final GenerativeModel _model;

  AIService(this._apiKey) {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
  }

  Future<Map<String, dynamic>> scanFoodImage(File imageFile) async {
    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();

      final prompt = TextPart(
        'Identifikasi makanan pada gambar secara rinci. '
        'Berikan nama makanan umum secara keseluruhan (dalam Bahasa Indonesia), perkiraan berat total dalam gram, dan tingkat kepercayaan (0-1). '
        'Kemudian, identifikasi setiap komponen/item makanan yang terlihat dalam gambar (misalnya: nasi, ayam, sayuran, buah, dll) '
        'beserta perkiraan berat masing-masing dalam gram. '
        'Juga identifikasi komponen-komponen makanan yang berpotensi menjadi foodwaste (tidak dimakan atau dibuang) '
        'beserta perkiraan emisi karbon (dalam kg CO2) yang dihasilkan jika dibuang. '
        'Berikan output HANYA dalam format JSON yang valid tanpa markdown apa pun, '
        'dengan struktur berikut: '
        '{"foodName": "nama makanan keseluruhan", '
        '"estimatedWeight": berat_total, '
        '"confidence": keyakinan, '
        '"foodItems": ['
        '{"itemName": "nama item1", "weight": berat_gram1}, '
        '{"itemName": "nama item2", "weight": berat_gram2}'
        '], '
        '"potentialFoodWasteItems": ['
        '{"itemName": "nama item waste", "estimatedCarbonEmission": emisi_co2}'
        ']}'
      );

      final imagePart = DataPart('image/jpeg', imageBytes);

      print('Sending request to Gemini API...');

      final response = await _model.generateContent([Content.multi([prompt, imagePart])]);

      final responseText = response.text;
      print('Gemini API Response: $responseText');

      if (responseText != null && responseText.isNotEmpty) {
        String cleanedResponse = responseText
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        try {
          Map<String, dynamic> jsonResponse = json.decode(cleanedResponse);

          if (!jsonResponse.containsKey('foodName') ||
              !jsonResponse.containsKey('estimatedWeight') ||
              !jsonResponse.containsKey('confidence')) {
            throw const FormatException('Format JSON tidak sesuai yang diharapkan');
          }

          double? estimatedWeight = _parseToDouble(jsonResponse['estimatedWeight']);
          double? confidence = _parseToDouble(jsonResponse['confidence']);

          if (estimatedWeight == null || confidence == null) {
            throw const FormatException('estimatedWeight atau confidence bukan angka yang valid');
          }

          List<FoodItem> foodItems = [];
          if (jsonResponse.containsKey('foodItems') && 
              jsonResponse['foodItems'] is List) {
            
            for (var item in jsonResponse['foodItems']) {
              if (item is Map<String, dynamic> && 
                  item.containsKey('itemName') && 
                  item.containsKey('weight')) {
                
                String itemName = item['itemName'] as String;
                double weight = _parseToDouble(item['weight']) ?? 0.0;
                
                foodItems.add(FoodItem(
                  itemName: itemName,
                  weight: weight,
                  remainingWeight: null,
                ));
              }
            }
          }

          List<PotentialFoodWasteItem> potentialItems = [];
          if (jsonResponse.containsKey('potentialFoodWasteItems') && 
              jsonResponse['potentialFoodWasteItems'] is List) {
            
            for (var item in jsonResponse['potentialFoodWasteItems']) {
              if (item is Map<String, dynamic> && 
                  item.containsKey('itemName') && 
                  item.containsKey('estimatedCarbonEmission')) {
                
                String itemName = item['itemName'] as String;
                double estimatedCarbonEmission = _parseToDouble(item['estimatedCarbonEmission']) ?? 0.0;
                
                potentialItems.add(PotentialFoodWasteItem(
                  itemName: itemName,
                  estimatedCarbonEmission: estimatedCarbonEmission,
                ));
              }
            }
          }

          return {
            'foodName': jsonResponse['foodName'] as String,
            'estimatedWeight': estimatedWeight,
            'confidence': confidence,
            'foodItems': foodItems,
            'potentialFoodWasteItems': potentialItems,
          };
        } catch (e) {
          print('Error parsing JSON response: $e. Response: $cleanedResponse');
          throw Exception('Gagal memproses respons dari Gemini API');
        }
      } else {
        throw Exception('Respons dari Gemini API kosong');
      }
    } catch (e) {
      print('Error scanning food image with Gemini API: $e');

      return {
        'foodName': 'Makanan tidak terdeteksi',
        'estimatedWeight': 100.0,
        'confidence': 0.5,
        'foodItems': [
          FoodItem(
            itemName: 'Makanan umum',
            weight: 100.0,
            remainingWeight: null,
          ),
        ],
        'potentialFoodWasteItems': [
          PotentialFoodWasteItem(
            itemName: 'Sisa makanan tidak teridentifikasi',
            estimatedCarbonEmission: 0.25,
          ),
        ],
      };
    }
  }

  Future<Map<String, dynamic>> compareFoodImages(File beforeImage, File afterImage) async {
    try {
      final Uint8List beforeImageBytes = await beforeImage.readAsBytes();
      final Uint8List afterImageBytes = await afterImage.readAsBytes();

      final prompt = TextPart(
        'Bandingkan dua gambar makanan ini. Gambar pertama adalah makanan sebelum dimakan, '
        'gambar kedua adalah makanan yang tersisa setelah dimakan. '
        'Perkirakan berapa persen (%) makanan yang tersisa pada gambar kedua dibandingkan dengan gambar pertama. '
        'Berikan output HANYA dalam format JSON yang valid tanpa markdown apa pun, '
        'dengan struktur: {"remainingPercentage": persentase, "confidence": keyakinan}'
      );

      final beforeImagePart = DataPart('image/jpeg', beforeImageBytes);
      final afterImagePart = DataPart('image/jpeg', afterImageBytes);

      print('Membandingkan gambar makanan dengan Gemini API...');

      final response = await _model.generateContent([
        Content.multi([prompt, beforeImagePart, afterImagePart])
      ]);

      final responseText = response.text;
      print('Gemini API Response untuk perbandingan gambar: $responseText');

      if (responseText != null && responseText.isNotEmpty) {
        String cleanedResponse = responseText
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        try {
          Map<String, dynamic> jsonResponse = json.decode(cleanedResponse);

          if (jsonResponse.containsKey('remainingPercentage') &&
              jsonResponse.containsKey('confidence')) {

            double? remainingPercentage = _parseToDouble(jsonResponse['remainingPercentage']);
            double? confidence = _parseToDouble(jsonResponse['confidence']);

            if (remainingPercentage == null || confidence == null) {
              throw const FormatException('remainingPercentage atau confidence bukan angka yang valid');
            }

            return {
              'remainingPercentage': remainingPercentage,
              'confidence': confidence,
            };
          } else {
            throw const FormatException('Format JSON tidak sesuai yang diharapkan');
          }
        } catch (e) {
          print('Error parsing JSON response: $e. Response: $cleanedResponse');
          throw Exception('Gagal memproses respons dari Gemini API');
        }
      } else {
        throw Exception('Respons dari Gemini API kosong');
      }
    } catch (e) {
      print('Error membandingkan gambar makanan dengan Gemini API: $e');

      return {
        'remainingPercentage': 50.0,
        'confidence': 0.5,
      };
    }
  }

  Future<Map<String, dynamic>> generateWeeklySummaryFromGemini(
      List<FoodScanModel> foodScans, Map<String, dynamic> userData) async {
    try {
      // Persiapkan data untuk prompt
      final username = userData['username'] ?? 'pengguna';
      final gender = userData['gender'] ?? 'tidak diketahui';
      final height = userData['bodyHeight'] ?? 0;
      final weight = userData['bodyWeight'] ?? 0;
      
      // Kategorisasi waktu makan berdasarkan scanTime
      final categorizeTime = (DateTime time) {
        final hour = time.hour;
        if (hour >= 5 && hour < 11) return 'Breakfast';
        if (hour >= 11 && hour < 15) return 'Lunch';
        if (hour >= 15 && hour < 19) return 'Snack';
        return 'Dinner';
      };

      // Hitung hari dalam seminggu
      final Map<String, double> wasteByDay = {
        'Monday': 0.0, 'Tuesday': 0.0, 'Wednesday': 0.0,
        'Thursday': 0.0, 'Friday': 0.0, 'Saturday': 0.0, 'Sunday': 0.0
      };
      
      final Map<String, List<double>> wastePercentageByMealTime = {
        'Breakfast': [], 'Lunch': [], 'Snack': [], 'Dinner': []
      };
      
      final Map<String, int> itemOccurrences = {};
      final Map<String, double> itemWasteWeight = {};
      final Map<String, int> finishedItemCount = {};
      
      final Map<String, double> categoryWaste = {
        'Carbohydrate': 0.0, 'Protein': 0.0, 'Vegetables': 0.0, 'Others': 0.0
      };
      
      // Kategori makanan dasar (ini bisa diperluas)
      final Map<String, String> foodCategories = {
        'nasi': 'Carbohydrate', 'bubur': 'Carbohydrate', 'mie': 'Carbohydrate', 'roti': 'Carbohydrate',
        'kentang': 'Carbohydrate', 'ubi': 'Carbohydrate', 'jagung': 'Carbohydrate', 'pasta': 'Carbohydrate',
        
        'ayam': 'Protein', 'daging': 'Protein', 'ikan': 'Protein', 'telur': 'Protein', 
        'tempe': 'Protein', 'tahu': 'Protein', 'suwir': 'Protein', 'rendang': 'Protein',
        
        'sayur': 'Vegetables', 'bayam': 'Vegetables', 'kangkung': 'Vegetables', 'wortel': 'Vegetables',
        'brokoli': 'Vegetables', 'kubis': 'Vegetables', 'tomat': 'Vegetables', 'nangka': 'Vegetables'
      };

      // Helper function untuk mendapatkan nama hari dari weekday
      String _getDayName(int weekday) {
        switch (weekday) {
          case 1: return 'Monday';
          case 2: return 'Tuesday';
          case 3: return 'Wednesday';
          case 4: return 'Thursday';
          case 5: return 'Friday';
          case 6: return 'Saturday';
          case 7: return 'Sunday';
          default: return 'Unknown';
        }
      }

      // Analisis semua foodScans
      for (final scan in foodScans) {
        // Validasi format timestamp terlebih dahulu
        DateTime? scanTime;
        try {
          scanTime = DateTime.parse(scan.scanTime.toString());
        } catch (e) {
          print('Invalid scan time format: ${scan.scanTime}');
          continue; // Skip data ini jika format waktu tidak valid
        }
        
        final mealTime = categorizeTime(scanTime);
        final dayName = _getDayName(scanTime.weekday);
        
        double totalWasteForThisMeal = 0.0;
        double totalWeightForThisMeal = 0.0;
        
        // Periksa apakah foodItems ada dan valid
        if (scan.foodItems == null || scan.foodItems.isEmpty) {
          print('No food items in this scan');
          continue;
        }
        
        // Periksa item makanan
        for (final item in scan.foodItems) {
          // Skip jika item name kosong
          if (item.itemName == null || item.itemName.trim().isEmpty) {
            continue;
          }
          
          final itemName = item.itemName.toLowerCase();
          
          // Catat semua item yang dimakan
          if (scan.isEaten == true) {
            finishedItemCount[item.itemName] = (finishedItemCount[item.itemName] ?? 0) + 1;
          }
          
          // Hitung sisa makanan jika ada
          double remainingWeight = item.remainingWeight ?? 0.0;
          double originalWeight = item.weight ?? 0.0;
          
          // Pastikan nilai weight valid
          if (originalWeight <= 0) {
            continue; // Skip jika weight tidak valid
          }
          
          totalWeightForThisMeal += originalWeight;
          
          // Jika ada sisa makanan dan isEaten true (berarti makanan dimakan tapi tidak habis)
          if (remainingWeight > 0 && scan.isEaten == true) {
            // Validasi: pastikan remaining tidak lebih besar dari original
            if (remainingWeight > originalWeight) {
              remainingWeight = originalWeight;
            }
            
            totalWasteForThisMeal += remainingWeight;
            
            // Catat item yang tersisa
            itemOccurrences[item.itemName] = (itemOccurrences[item.itemName] ?? 0) + 1;
            itemWasteWeight[item.itemName] = (itemWasteWeight[item.itemName] ?? 0.0) + remainingWeight;
            
            // Kategorikan limbah makanan
            String category = 'Others';
            for (final key in foodCategories.keys) {
              if (itemName.contains(key)) {
                category = foodCategories[key]!;
                break;
              }
            }
            categoryWaste[category] = (categoryWaste[category] ?? 0.0) + remainingWeight;
          }
        }
        
        // Tambahkan data limbah berdasarkan hari
        wasteByDay[dayName] = (wasteByDay[dayName] ?? 0.0) + totalWasteForThisMeal;
        
        // Hitung persentase sisa untuk waktu makan ini
        if (totalWeightForThisMeal > 0) {
          final wastePercentage = (totalWasteForThisMeal / totalWeightForThisMeal) * 100;
          wastePercentageByMealTime[mealTime]?.add(wastePercentage);
        }
      }
      
      // PERBAIKAN: Deklarasi fungsi untuk mengkonversi Map ke format yang JSON-serializable
      
      
      // Buat salinan foodScans yang sepenuhnya bisa dikonversi ke JSON
      List<Map<String, dynamic>> serializedFoodScans = foodScans.map((scan) {
        // Gunakan helper function untuk membuat map yang aman untuk JSON
        Map<String, dynamic> scanMap = {};
        
        // Isi dengan data dari scan, pastikan semua properti dikonversi dengan aman
        scanMap['id'] = scan.id;
        scanMap['userId'] = scan.userId;
        scanMap['foodName'] = scan.foodName;
        scanMap['scanTime'] = scan.scanTime.toIso8601String();
        scanMap['finishTime'] = scan.finishTime.toIso8601String();
        scanMap['isDone'] = scan.isDone;
        scanMap['isEaten'] = scan.isEaten;
        
        // Konversi food items dengan aman
        scanMap['foodItems'] = scan.foodItems.map((item) => {
          'itemName': item.itemName,
          'weight': item.weight,
          'remainingWeight': item.remainingWeight,
        }).toList();
        
        // Konversi potential food waste items jika ada
        if (scan.potentialFoodWasteItems != null) {
          scanMap['potentialFoodWasteItems'] = scan.potentialFoodWasteItems!.map((item) => {
            'itemName': item.itemName,
            'estimatedCarbonEmission': item.estimatedCarbonEmission,
          }).toList();
        }
        
        // Tambahkan properti lainnya
        scanMap['imageUrl'] = scan.imageUrl;
        scanMap['afterImageUrl'] = scan.afterImageUrl;
        scanMap['aiRemainingPercentage'] = scan.aiRemainingPercentage;
        scanMap['aiConfidence'] = scan.aiConfidence;
        
        return scanMap;
      }).toList();

      
      
      // Gunakan userData yang aman untuk JSON
      Map<String, dynamic> serializedUserData = _sanitizeUserData(userData);

      
      // Ubah ke string JSON
      final foodScansJson = jsonEncode(serializedFoodScans);
      final userDataJson = jsonEncode(serializedUserData);
      
      // Debugging (opsional, bisa dihapus)
      print('Serialized User Data: $userDataJson');
      print('First food scan serialized: ${serializedFoodScans.isNotEmpty ? serializedFoodScans[0] : "none"}');
      
      final prompt = TextPart('''
Analisis data makan pengguna selama 7 hari terakhir dan buat ringkasan mingguan.

Data pengguna: $userDataJson

Data scan makanan 7 hari terakhir: $foodScansJson

PERHATIAN: 
1. Data makanan mungkin tidak lengkap untuk 7 hari penuh
2. Buat rekomendasi yang masuk akal berdasarkan data yang tersedia saja
3. Jika data terlalu sedikit, berikan saran umum yang tetap bermanfaat
4. Pastikan semua rekomendasi spesifik, akurat, dan berdasarkan pola nyata dari data
5. Gunakan hanya data scan dalam 7 hari terakhir dari waktu saat ini (berdasarkan nilai tanggal pada scanTime). Abaikan data lebih lama.

Berdasarkan analisis data tersebut, buatkan ringkasan dalam format JSON dengan struktur persis seperti berikut:
{
  "generalUserRecommendations": [
    {
      "userId": "[ID pengguna]",
      "eatingPattern": {
        "frequentWasteTime": "[Waktu makan dengan sisa terbanyak (Breakfast/Lunch/Dinner)]",
        "mostWastedItem": "[Nama item makanan yang paling sering tersisa]",
        "averageWastePercentage": [Persentase rata-rata sisa makanan]
      },
      "suggestions": {
        "portionAdjustment": "[Saran untuk penyesuaian porsi]",
        "foodTypeRecommendation": "[Rekomendasi jenis makanan]",
        "behavioralTip": "[Tips perilaku makan]"
      }
    }
  ],
  "topWastedFoodItems": [
    {
      "itemName": "[Nama item]",
      "totalRemainingWeight": [Total berat sisa dalam gram],
      "totalOccurrences": [Jumlah kejadian]
    }
  ],
  "foodWasteByMealTime": [
    {
      "mealTime": "[Waktu makan (Breakfast/Lunch/Dinner)]",
      "averageRemainingPercentage": [Persentase rata-rata sisa]
    }
  ],
  "foodWasteByDayOfWeek": [
    {
      "day": "[Hari (Monday/Tuesday/etc)]",
      "totalWasteGram": [Total limbah dalam gram]
    }
  ],
  "totalFoodWaste": {
    "totalWeight_gram": [Total berat limbah dalam gram],
    "totalWeight_kg": [Total berat limbah dalam kg],
    "totalCarbonEmission_kgCO2": [Estimasi emisi karbon dari limbah]
  },
  "mostFinishedItems": [
    {
      "itemName": "[Nama item]",
      "finishedCount": [Jumlah kali selesai dimakan]
    }
  ],
  "wasteByCategory": {
    "Carbohydrate": [Total limbah karbohidrat dalam gram],
    "Protein": [Total limbah protein dalam gram],
    "Vegetables": [Total limbah sayuran dalam gram]
  }
}

PENTING: 
1. Berikan output HANYA dalam format JSON yang valid tanpa markup atau penjelasan tambahan
2. Gunakan data yang tersedia untuk membuat estimasi yang masuk akal dan konsisten
3. Untuk bagian "suggestions", berikan rekomendasi yang relevan dan bervariasi berdasarkan data pengguna:
   - "portionAdjustment" bisa berupa saran untuk menambah, mengurangi, atau menyesuaikan porsi berdasarkan pola makan yang terdeteksi
   - "foodTypeRecommendation" bisa berupa jenis makanan yang disarankan atau hindari berdasarkan pola pembuangan makanan
   - "behavioralTip" berikan tips perilaku yang dapat membantu mengurangi sisa makanan
   - "mostFinishedItems" jika "finishedCount" 0 tidak usah disertakan

4. Jangan berikan rekomendasi yang terlalu umum atau stereotip. Gunakan data yang tersedia untuk membuat rekomendasi yang spesifik dan personal.
5. Jika data tidak cukup untuk membuat rekomendasi spesifik, berikan saran umum yang tetap bermanfaat tetapi akui keterbatasan data.
6. Rekomendasi harus masuk akal secara nutrisi dan tidak ekstrem.
7. Untuk bagian "foodWasteByDayOfWeek", hanya tampilkan hari-hari yang terdapat dalam data (berdasarkan scanTime). Jika tidak ada scan untuk hari tersebut, jangan dimunculkan. Jangan isi hari kosong dengan nilai nol atau hasil tebakan.
''');


      print('Mengirim prompt ke Gemini API untuk analisis mingguan...');

      final response = await _model.generateContent([
        Content.text(prompt.text)
      ]);

      final responseText = response.text;
      print('Gemini API Response untuk ringkasan mingguan: $responseText');

      if (responseText != null && responseText.isNotEmpty) {
        String cleanedResponse = responseText
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        try {
          Map<String, dynamic> jsonResponse = json.decode(cleanedResponse);
          return jsonResponse;
        } catch (e) {
          print('Error parsing JSON response: $e. Response: $cleanedResponse');
          
          // Jika gagal parsing, coba bersihkan response lebih lanjut dan coba lagi
          try {
            // Kadang Gemini menambahkan teks tambahan, coba bersihkan lebih agresif
            String moreCleanedResponse = cleanedResponse
                .replaceAll(RegExp(r'^.*?(\{)', dotAll: true), '{') // Hapus semua karakter sebelum tanda { pertama
                .replaceAll(RegExp(r'(\}).*$', dotAll: true), '}'); // Hapus semua karakter setelah tanda } terakhir
                
            Map<String, dynamic> jsonResponse = json.decode(moreCleanedResponse);
            print('JSON parsing berhasil setelah pembersihan tambahan');
            return jsonResponse;
          } catch (e2) {
            print('Gagal parsing JSON setelah pembersihan tambahan: $e2');
            
            // Jika tetap gagal, buat data ringkasan dasar dari analisis manual
            return _createFallbackSummary(
              userId: userData['userId'] ?? 'unknown',
              itemWasteWeight: itemWasteWeight,
              itemOccurrences: itemOccurrences,
              wastePercentageByMealTime: wastePercentageByMealTime,
              wasteByDay: wasteByDay,
              finishedItemCount: finishedItemCount,
              categoryWaste: categoryWaste
            );
          }
        }
      } else {
        throw Exception('Respons dari Gemini API kosong');
      }
    } catch (e) {
      print('Error generating weekly summary with Gemini API: $e');
      
      // Jika terjadi error, kembalikan data ringkasan placeholder
      return {
        "generalUserRecommendations": [
          {
            "userId": userData['userId'] ?? 'unknown',
            "eatingPattern": {
              "frequentWasteTime": "Lunch",
              "mostWastedItem": "Nasi",
              "averageWastePercentage": 10.0
            },
            "suggestions": {
              "portionAdjustment": "Coba kurangi porsi makanan Anda terutama saat makan siang.",
              "foodTypeRecommendation": "Pilih makanan yang Anda sukai agar dapat dihabiskan.",
              "behavioralTip": "Ambil porsi lebih kecil terlebih dahulu, dan tambah jika masih lapar."
            }
          }
        ],
        "topWastedFoodItems": [],
        "foodWasteByMealTime": [],
        "foodWasteByDayOfWeek": [],
        "totalFoodWaste": {
          "totalWeight_gram": 0.0,
          "totalWeight_kg": 0.0,
          "totalCarbonEmission_kgCO2": 0.0
        },
        "mostFinishedItems": [],
        "wasteByCategory": {
          "Carbohydrate": 0,
          "Protein": 0,
          "Vegetables": 0
        }
      };
    }
  }

  // Fungsi untuk membuat ringkasan manual jika Gemini gagal
  Map<String, dynamic> _createFallbackSummary({
    required String userId,
    required Map<String, double> itemWasteWeight,
    required Map<String, int> itemOccurrences,
    required Map<String, List<double>> wastePercentageByMealTime,
    required Map<String, double> wasteByDay,
    required Map<String, int> finishedItemCount,
    required Map<String, double> categoryWaste
  }) {
    // Cek apakah data cukup untuk membuat rekomendasi
    bool hasEnoughData = itemWasteWeight.isNotEmpty && 
                         wastePercentageByMealTime.values.any((list) => list.isNotEmpty);
    
    // Cari item dengan limbah terbanyak jika ada data cukup
    String mostWastedItem = 'Tidak ada data cukup';
    double maxWaste = 0;
    if (itemWasteWeight.isNotEmpty) {
      itemWasteWeight.forEach((item, weight) {
        if (weight > maxWaste) {
          mostWastedItem = item;
          maxWaste = weight;
        }
      });
    }

    // Cari waktu makan dengan persentase limbah terbesar
    String frequentWasteTime = 'Tidak ada data cukup';
    double maxAvgWastePercentage = 0;
    Map<String, double> avgWasteByMealTime = {};

    wastePercentageByMealTime.forEach((mealTime, percentages) {
      if (percentages.isNotEmpty) {
        double avg = percentages.reduce((a, b) => a + b) / percentages.length;
        avgWasteByMealTime[mealTime] = avg;
        
        if (avg > maxAvgWastePercentage) {
          maxAvgWastePercentage = avg;
          frequentWasteTime = mealTime;
        }
      } else {
        avgWasteByMealTime[mealTime] = 0;
      }
    });

    // Top wasted items
    List<Map<String, dynamic>> topWastedItems = [];
    itemWasteWeight.forEach((item, weight) {
      if (weight > 0) {
        topWastedItems.add({
          "itemName": item,
          "totalRemainingWeight": weight,
          "totalOccurrences": itemOccurrences[item] ?? 1
        });
      }
    });
    
    // Sort by weight
    topWastedItems.sort((a, b) => (b["totalRemainingWeight"] as double).compareTo(a["totalRemainingWeight"] as double));
    if (topWastedItems.length > 5) {
      topWastedItems = topWastedItems.sublist(0, 5);
    }

    // Food waste by meal time
    List<Map<String, dynamic>> wasteByMealTime = [];
    avgWasteByMealTime.forEach((mealTime, avgPercentage) {
      if (avgPercentage > 0) {
        wasteByMealTime.add({
          "mealTime": mealTime,
          "averageRemainingPercentage": double.parse(avgPercentage.toStringAsFixed(1))
        });
      }
    });

    // Food waste by day of week
    List<Map<String, dynamic>> wasteByDayOfWeek = [];
    wasteByDay.forEach((day, waste) {
      if (waste > 0) {
        wasteByDayOfWeek.add({
          "day": day,
          "totalWasteGram": waste
        });
      }
    });

    // Total food waste
    double totalWasteGram = wasteByDay.values.fold(0, (sum, waste) => sum + waste);
    double totalWasteKg = totalWasteGram / 1000;
    
    // Estimasi emisi karbon (0.00355 kgCO2 per kg limbah makanan)
    double carbonEmission = totalWasteKg * 0.00355;

    // Most finished items
    List<Map<String, dynamic>> mostFinishedItems = [];
    finishedItemCount.forEach((item, count) {
      if (count > 0) {
        mostFinishedItems.add({
          "itemName": item,
          "finishedCount": count
        });
      }
    });
    
    // Sort by count
    mostFinishedItems.sort((a, b) => (b["finishedCount"] as int).compareTo(a["finishedCount"] as int));
    if (mostFinishedItems.length > 5) {
      mostFinishedItems = mostFinishedItems.sublist(0, 5);
    }

    // Buat rekomendasi berdasarkan data yang tersedia
    Map<String, String> suggestions = {};
    
    if (hasEnoughData) {
      // Variasi rekomendasi untuk portionAdjustment
      final List<String> portionSuggestions = [
        "Sesuaikan porsi $mostWastedItem berdasarkan kebutuhan Anda",
        "Coba perhatikan porsi $mostWastedItem saat $frequentWasteTime",
        "Pertimbangkan untuk mengambil porsi yang lebih sesuai"
      ];
      
      // Variasi rekomendasi untuk foodTypeRecommendation
      final List<String> foodTypeSuggestions = [
        "Pilih makanan yang Anda sukai dan mampu dihabiskan",
        "Coba menu yang porsinya lebih mudah dikontrol saat $frequentWasteTime",
        "Pertimbangkan makanan yang lebih tahan lama jika tidak bisa dihabiskan"
      ];
      
      // Variasi rekomendasi untuk behavioralTip
      final List<String> behavioralSuggestions = [
        "Ambil porsi sedikit demi sedikit, tambah jika masih lapar",
        "Perhatikan rasa kenyang sebelum mengambil makanan tambahan",
        "Sisakan waktu makan yang cukup untuk menikmati makanan Anda" 
      ];
      
      suggestions = {
        "portionAdjustment": portionSuggestions[DateTime.now().microsecond % portionSuggestions.length],
        "foodTypeRecommendation": foodTypeSuggestions[DateTime.now().microsecond % foodTypeSuggestions.length],
        "behavioralTip": behavioralSuggestions[DateTime.now().microsecond % behavioralSuggestions.length]
      };
    } else {
      // Rekomendasi umum jika data tidak cukup
      suggestions = {
        "portionAdjustment": "Perhatikan porsi makanan yang sesuai dengan kebutuhan Anda",
        "foodTypeRecommendation": "Pilih jenis makanan yang Anda sukai dan dapat dihabiskan",
        "behavioralTip": "Pertimbangkan untuk mengambil porsi lebih kecil terlebih dahulu"
      };
    }

    return {
      "generalUserRecommendations": [
        {
          "userId": userId,
          "eatingPattern": {
            "frequentWasteTime": frequentWasteTime,
            "mostWastedItem": mostWastedItem,
            "averageWastePercentage": hasEnoughData ? double.parse(maxAvgWastePercentage.toStringAsFixed(1)) : 0.0
          },
          "suggestions": suggestions
        }
      ],
      "topWastedFoodItems": topWastedItems,
      "foodWasteByMealTime": wasteByMealTime,
      "foodWasteByDayOfWeek": wasteByDayOfWeek,
      "totalFoodWaste": {
        "totalWeight_gram": totalWasteGram,
        "totalWeight_kg": totalWasteKg,
        "totalCarbonEmission_kgCO2": carbonEmission
      },
      "mostFinishedItems": mostFinishedItems,
      "wasteByCategory": categoryWaste
    };
  }
  
  // Helper untuk mengubah berbagai format nilai ke double
  double? _parseToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll('%', ''));
    }
    return null;
  }
  
  // Add this method to fix the error in food_scan_provider.dart
  double calculateCarbonEmission(double foodWasteWeight) {
    // Convert waste weight from grams to kg and calculate carbon emission
    // Using factor 0.00355 kgCO2 per kg of food waste
    double wasteInKg = foodWasteWeight / 1000.0;
    return wasteInKg * 0.00355;
  }

  Map<String, dynamic> toJsonMap(Map map) {
        Map<String, dynamic> result = {};
        map.forEach((key, value) {
          result[key.toString()] = toJsonValue(value);
        });
        return result;
      }

      // Deklarasi fungsi untuk mengkonversi value ke format JSON-serializable  
      dynamic toJsonValue(dynamic value) {
        if (value == null) {
          return null;
        } else if (value is DateTime) {
          return value.toIso8601String();
        } else if (value.toString().contains('Timestamp')) {
          // Menangani Firestore Timestamp
          try {
            if (value.runtimeType.toString() == 'Timestamp') {
              return value.toDate().toIso8601String();
            }
          } catch (_) {
            return null;
          }
          return value.toString();
        } else if (value is Map) {
          return toJsonMap(value);
        } else if (value is List) {
          return value.map((item) => toJsonValue(item)).toList();
        }
        return value;
      }

      Map<String, dynamic> _sanitizeUserData(Map<String, dynamic> data) {
      return data.map((key, value) {
        if (value is Timestamp) {
          return MapEntry(key, value.toDate().toIso8601String());
        } else if (value is Map<String, dynamic>) {
          return MapEntry(key, _sanitizeUserData(value)); // recursive if nested
        } else {
          return MapEntry(key, value);
        }
      });
    }

}