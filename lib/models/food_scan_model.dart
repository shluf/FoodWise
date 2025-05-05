import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class PotentialFoodWasteItem {
  final String itemName;
  final double estimatedCarbonEmission; // dalam kg CO2
  
  PotentialFoodWasteItem({
    required this.itemName,
    required this.estimatedCarbonEmission,
  });
  
  factory PotentialFoodWasteItem.fromMap(Map<String, dynamic> map) {
    return PotentialFoodWasteItem(
      itemName: map['itemName'] ?? '',
      estimatedCarbonEmission: (map['estimatedCarbonEmission'] ?? 0).toDouble(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'itemName': itemName,
      'estimatedCarbonEmission': estimatedCarbonEmission,
    };
  }
}

class FoodItem {
  final String itemName;
  final double weight; // dalam gram
  final double? remainingWeight; // dalam gram
  
  FoodItem({
    required this.itemName,
    required this.weight,
    this.remainingWeight,
  });
  
  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      itemName: map['itemName'] ?? '',
      weight: (map['weight'] ?? 0).toDouble(),
      remainingWeight: (map['remainingWeight'] ?? 0).toDouble(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'itemName': itemName,
      'weight': weight,
      'remainingWeight': remainingWeight,
    };
  }
}

class FoodScanModel {
  final String id;
  final String userId;
  final String foodName;
  final List<FoodItem> foodItems;
  final List<PotentialFoodWasteItem>? potentialFoodWasteItems; // item makanan yang berpotensi jadi foodwaste
  final DateTime scanTime;
  final DateTime finishTime;
  final bool isDone;
  final bool isEaten; // makanan habis atau sisa
  final String? imageUrl;
  final String? afterImageUrl; // URL gambar setelah makanan dimakan
  final double? aiRemainingPercentage; // Persentase makanan tersisa hasil dari AI
  final double? aiConfidence; // Tingkat kepercayaan prediksi AI
  
  FoodScanModel({
    required this.id,
    required this.userId,
    required this.foodName, 
    required this.foodItems,
    required this.scanTime,
    required this.finishTime,
    required this.isDone,
    this.isEaten = false,
    this.potentialFoodWasteItems,
    this.imageUrl,
    this.afterImageUrl,
    this.aiRemainingPercentage,
    this.aiConfidence,
  });
  
  factory FoodScanModel.fromMap(Map<String, dynamic> map, String id) {
    List<PotentialFoodWasteItem>? potentialItems;
    
    if (map['potentialFoodWasteItems'] != null) {
      potentialItems = (map['potentialFoodWasteItems'] as List)
          .map((item) => PotentialFoodWasteItem.fromMap(item))
          .toList();
    }
    
    List<FoodItem> foodItems = [];
    if (map['foodItems'] != null) {
      foodItems = (map['foodItems'] as List)
          .map((item) => FoodItem.fromMap(item))
          .toList();
    }
    
    return FoodScanModel(
      id: id,
      userId: map['userId'] ?? '',
      foodName: map['foodName'] ?? '',
      scanTime: (map['scanTime'] as Timestamp).toDate(),
      finishTime: map['finishTime'] != null 
          ? (map['finishTime'] as Timestamp).toDate() 
          : DateTime.now().add(const Duration(days: 7)),
      isDone: map['isDone'] ?? false,
      isEaten: map['isEaten'] ?? false,
      foodItems: foodItems,
      potentialFoodWasteItems: potentialItems,
      imageUrl: map['imageUrl'],
      afterImageUrl: map['afterImageUrl'],
      aiRemainingPercentage: map['aiRemainingPercentage'] != null ? (map['aiRemainingPercentage']).toDouble() : null,
      aiConfidence: map['aiConfidence'] != null ? (map['aiConfidence']).toDouble() : null,
    );
  }

  static Future<FoodScanModel> fromMapAsync(Map<String, dynamic> map, String id) async {
    return compute(_parseFoodScanModel, {'map': map, 'id': id});
  }

  static FoodScanModel _parseFoodScanModel(Map<String, dynamic> args) {
    final map = args['map'] as Map<String, dynamic>;
    final id = args['id'] as String;

    List<PotentialFoodWasteItem>? potentialItems;
    if (map['potentialFoodWasteItems'] != null) {
      potentialItems = (map['potentialFoodWasteItems'] as List)
          .map((item) => PotentialFoodWasteItem.fromMap(item))
          .toList();
    }

    List<FoodItem> foodItems = [];
    if (map['foodItems'] != null) {
      foodItems = (map['foodItems'] as List)
          .map((item) => FoodItem.fromMap(item))
          .toList();
    }

    // Validasi tipe data scanTime
    DateTime scanTime;
    if (map['scanTime'] is Timestamp) {
      scanTime = (map['scanTime'] as Timestamp).toDate();
    } else if (map['scanTime'] is String) {
      scanTime = DateTime.parse(map['scanTime']);
    } else {
      throw Exception('Invalid scanTime format for document ID: $id');
    }

    DateTime finishTime;
    if (map['finishTime'] is Timestamp) {
      finishTime = (map['finishTime'] as Timestamp).toDate();
    } else if (map['finishTime'] is String) {
      finishTime = DateTime.parse(map['finishTime']);
    } else {
      finishTime = DateTime.now().add(const Duration(days: 7));
    }

    return FoodScanModel(
      id: id,
      userId: map['userId'] ?? '',
      foodName: map['foodName'] ?? '',
      scanTime: scanTime,
      finishTime: finishTime,
      isDone: map['isDone'] ?? false,
      isEaten: map['isEaten'] ?? false,
      foodItems: foodItems,
      potentialFoodWasteItems: potentialItems,
      imageUrl: map['imageUrl'],
      afterImageUrl: map['afterImageUrl'],
      aiRemainingPercentage: map['aiRemainingPercentage'] != null
          ? (map['aiRemainingPercentage']).toDouble()
          : null,
      aiConfidence: map['aiConfidence'] != null
          ? (map['aiConfidence']).toDouble()
          : null,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'foodName': foodName,
      'scanTime': scanTime,
      'finishTime': finishTime,
      'isDone': isDone,
      'isEaten': isEaten,
      'foodItems': foodItems.map((item) => item.toMap()).toList(),
      'potentialFoodWasteItems': potentialFoodWasteItems?.map((item) => item.toMap()).toList(),
      'imageUrl': imageUrl,
      'afterImageUrl': afterImageUrl,
      'aiRemainingPercentage': aiRemainingPercentage,
      'aiConfidence': aiConfidence,
    };
  }
  
  FoodScanModel copyWith({
    String? userId,
    String? foodName,
    DateTime? scanTime,
    DateTime? finishTime,
    bool? isDone,
    bool? isEaten,
    List<FoodItem>? foodItems,
    List<PotentialFoodWasteItem>? potentialFoodWasteItems,
    String? imageUrl,
    String? afterImageUrl,
    double? aiRemainingPercentage,
    double? aiConfidence,
  }) {
    return FoodScanModel(
      id: id,
      userId: userId ?? this.userId,
      foodName: foodName ?? this.foodName,
      scanTime: scanTime ?? this.scanTime,
      finishTime: finishTime ?? this.finishTime,
      isDone: isDone ?? this.isDone,
      isEaten: isEaten ?? this.isEaten,
      foodItems: foodItems ?? this.foodItems,
      potentialFoodWasteItems: potentialFoodWasteItems ?? this.potentialFoodWasteItems,
      imageUrl: imageUrl ?? this.imageUrl,
      afterImageUrl: afterImageUrl ?? this.afterImageUrl,
      aiRemainingPercentage: aiRemainingPercentage ?? this.aiRemainingPercentage,
      aiConfidence: aiConfidence ?? this.aiConfidence,
    );
  }
}