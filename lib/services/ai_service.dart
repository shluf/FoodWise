import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../models/food_scan_model.dart';

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

  double? _parseToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  double calculateCarbonEmission(double foodWasteWeight) {
    // Formula: 1 kg food waste = approximately 2.5 kg CO2 equivalent
    // Source: Example calculation (replace with actual data source)
    // Konversi gram ke kg
    double foodWasteWeightKg = foodWasteWeight / 1000.0;
    return foodWasteWeightKg * 2.5;
  }
} 