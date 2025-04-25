package com.ahshaka.foodwise

import io.flutter.embedding.android.FlutterActivity
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.ahshaka.foodwise/foodwise_widget"
    
    private var launchedFromWidget = false
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }
    
    private fun handleIntent(intent: Intent) {
        if (intent.action == FoodWiseWidgetProvider.ACTION_SCAN_FOOD) {
            launchedFromWidget = true
            intent.action = null
        }
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        if (launchedFromWidget) {
            flutterEngine.navigationChannel.setInitialRoute("/scan")
        }
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidgetStatistics" -> {
                    val totalWaste = call.argument<Double>("totalWaste")?.toFloat() ?: 0f
                    val carbonSaved = call.argument<Double>("carbonSaved")?.toFloat() ?: 0f
                    
                    val widgetProvider = FoodWiseWidgetProvider()
                    widgetProvider.updateStatistics(applicationContext, totalWaste, carbonSaved)
                    
                    result.success(true)
                }
                "updateUnfinishedFoods" -> {
                    val foodsArg = call.argument<List<Map<String, Any>>>("foods")
                    
                    if (foodsArg != null) {
                        val unfinishedFoods = foodsArg.map { food ->
                            UnfinishedFoodItem(
                                id = food["id"] as String,
                                foodName = food["foodName"] as String,
                                weight = (food["weight"] as Number).toDouble(),
                                scanTime = food["scanTime"] as Long
                            )
                        }
                        
                        val widgetProvider = FoodWiseWidgetProvider()
                        widgetProvider.updateUnfinishedFoods(applicationContext, unfinishedFoods)
                        
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "foods parameter is required", null)
                    }
                }
                "checkLaunchIntent" -> {
                    val wasLaunchedForScan = launchedFromWidget
                    if (wasLaunchedForScan) {
                        launchedFromWidget = false
                    }

                    result.success(wasLaunchedForScan)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}

data class UnfinishedFoodItem(
    val id: String,
    val foodName: String,
    val weight: Double,
    val scanTime: Long
)
