import 'package:flutter/services.dart';
import '../models/food_scan_model.dart';

class WidgetService {
  static const _channel = MethodChannel('com.ahshaka.foodwise/foodwise_widget');
  
  static Future<bool> updateWidgetStatistics({
    required double totalWaste,
    required double carbonSaved,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'updateWidgetStatistics',
        {
          'totalWaste': totalWaste,
          'carbonSaved': carbonSaved,
        },
      );
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error updating widget statistics: ${e.message}');
      return false;
    } on MissingPluginException catch (e) {
      
      print('Widget plugin not implemented: ${e.message}');
      return false;
    }
  }
  
  static Future<bool> updateUnfinishedFoods(List<FoodScanModel> unfinishedFoods) async {
    try {
      final List<Map<String, dynamic>> foodList = unfinishedFoods
          .map((food) => {
                'id': food.id,
                'foodName': food.foodName,
                'scanTime': food.scanTime.millisecondsSinceEpoch,
                'totalWeight': food.foodItems.fold(0.0, (sum, item) => sum + item.weight),
              })
          .toList();
      
      final result = await _channel.invokeMethod<bool>(
        'updateUnfinishedFoods',
        {
          'foods': foodList,
        },
      );
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error updating unfinished foods widget: ${e.message}');
      return false;
    } on MissingPluginException catch (e) {
      print('updateUnfinishedFoods method not implemented in native code: ${e.message}');
      return false;
    }
  }
  
  static Future<bool> checkLaunchForScan() async {
    try {
      print('DEBUG Flutter: Checking if app was launched from widget');
      final result = await _channel.invokeMethod<bool>('checkLaunchIntent');
      print('DEBUG Flutter: Launch from widget result: $result');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error checking launch intent: ${e.message}');
      return false;
    } on MissingPluginException catch (e) {
      print('checkLaunchIntent method not implemented in native code: ${e.message}');
      return false;
    }
  }
}