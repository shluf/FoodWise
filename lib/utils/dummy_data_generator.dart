import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/food_scan_model.dart';

class DummyDataGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> loadAndSaveDummyData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No user is currently logged in.');
        return;
      }

      final userId = user.uid;

      // Load JSON file
      final String jsonString = await rootBundle.loadString('lib/utils/food_dummies.json');
      final List<dynamic> jsonData = json.decode(jsonString);

      for (var item in jsonData) {
        // Map JSON data to FoodScanModel
        final foodScan = FoodScanModel(
          id: '', // Firestore will generate this
          userId: userId,
          foodName: item['foodName'] ?? 'Unknown Food', // Default value for foodName
          imageUrl: item['imageUrl'] ?? '', // Default empty string for imageUrl
          afterImageUrl: item['afterImageUrl'] ?? '', // Default empty string for afterImageUrl
          aiConfidence: item['aiConfidence']?.toDouble() ?? 0.0, // Default value for aiConfidence
          aiRemainingPercentage: item['aiRemainingPercentage']?.toDouble() ?? 0.0, // Default value for aiRemainingPercentage
          finishTime: DateTime.parse(item['finishTime']),
          scanTime: DateTime.now(), // Use current time if scanTime is not provided
          foodItems: (item['foodItems'] as List<dynamic>).map((foodItem) {
            return FoodItem(
              itemName: foodItem['itemName'] ?? 'Unknown Item', // Default value for itemName
              weight: (foodItem['weight'] ?? 0).toDouble(), // Parse weight correctly
              remainingWeight: (foodItem['remainingWeight'] ?? 0).toDouble(), // Parse remainingWeight correctly
            );
          }).toList(),
          isDone: item['isDone'] ?? false, // Default value for isDone
          isEaten: item['isEaten'] ?? false, // Default value for isEaten
          potentialFoodWasteItems: (item['potentialFoodWasteItems'] as List<dynamic>?)
                  ?.map((wasteItem) {
                return PotentialFoodWasteItem(
                  itemName: wasteItem['itemName'] ?? 'Unknown Waste Item', // Default value for itemName
                  estimatedCarbonEmission: (wasteItem['estimatedCarbonEmission'] ?? 0).toDouble(), // Parse estimatedCarbonEmission correctly
                );
              }).toList() ??
              [], // Default empty list if potentialFoodWasteItems is null
        );

        // Save to Firestore
        await _firestore.collection('foodScans').add(foodScan.toMap());
      }

      print('Dummy data successfully saved to Firestore.');
    } catch (e) {
      print('Error loading and saving dummy data: $e');
    }
  }
}
