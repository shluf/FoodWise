import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/food_scan_model.dart';

class FoodScanDetail extends StatelessWidget {
  final String foodScanId;

  const FoodScanDetail({Key? key, required this.foodScanId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return StreamBuilder<FoodScanModel?>(
      stream: firestoreService.getFoodScanById(foodScanId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('Food scan not found.'));
        }

        final foodScan = snapshot.data!;
        return Scaffold(
          appBar: AppBar(title: Text(foodScan.foodName)),
          body: ListView(
            children: [
              Text('Food Name: ${foodScan.foodName}'),
              Text('Scan Time: ${foodScan.scanTime}'),
              // ...display other fields...
            ],
          ),
        );
      },
    );
  }
}
