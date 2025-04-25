package com.ahshaka.foodwise

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import androidx.annotation.NonNull
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Widget penyedia untuk aplikasi FoodWise yang menampilkan statistik limbah makanan
 * dan tombol pintas menuju scanner makanan.
 */
class FoodWiseWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_SCAN_FOOD = "com.ahshaka.foodwise.ACTION_SCAN_FOOD"
        private const val PREFS_NAME = "com.ahshaka.foodwise.FoodWiseWidget"
        private const val PREF_TOTAL_WASTE = "total_waste"
        private const val PREF_CARBON_SAVED = "carbon_saved"
        private const val PREF_UNFINISHED_FOODS = "unfinished_foods"
        private const val MAX_FOODS_TO_SHOW = 3
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.foodwise_widget)
        
        // Ambil data statistik dari SharedPreferences
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val totalWaste = prefs.getFloat(PREF_TOTAL_WASTE, 0f)
        val carbonSaved = prefs.getFloat(PREF_CARBON_SAVED, 0f)
        
        // Update tampilan widget dengan data statistik
        views.setTextViewText(R.id.widget_total_waste, "${String.format("%.2f", totalWaste)} g")
        views.setTextViewText(R.id.widget_carbon_saved, "${String.format("%.2f", carbonSaved)} g")
        
        // Update tampilan makanan yang belum selesai
        updateUnfinishedFoodsView(context, views, prefs)
        
        // Siapkan intent untuk membuka aplikasi dengan scanner
        val intent = Intent(context, Class.forName("${context.packageName}.MainActivity")).apply {
            action = ACTION_SCAN_FOOD
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            
            putExtra("timestamp", System.currentTimeMillis())
        }
        
        // Buat PendingIntent untuk tombol scan
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_scan_button, pendingIntent)
        
        // Update widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
    
    /**
     * Update data statistik yang ditampilkan di widget
     */
    fun updateStatistics(context: Context, totalWaste: Float, carbonSaved: Float) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val editor = prefs.edit()
        editor.putFloat(PREF_TOTAL_WASTE, totalWaste)
        editor.putFloat(PREF_CARBON_SAVED, carbonSaved)
        editor.apply()
        
        // Trigger pembaruan widget
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(
            android.content.ComponentName(context, FoodWiseWidgetProvider::class.java)
        )
        onUpdate(context, appWidgetManager, appWidgetIds)
    }
    
    /**
     * Update daftar makanan yang belum selesai di widget
     */
    fun updateUnfinishedFoods(context: Context, unfinishedFoods: List<UnfinishedFoodItem>) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val editor = prefs.edit()
        
        // Konversi list ke JSON untuk disimpan di SharedPreferences
        val jsonArray = JSONArray()
        for (food in unfinishedFoods.take(MAX_FOODS_TO_SHOW)) {
            val foodObj = JSONObject()
            foodObj.put("id", food.id)
            foodObj.put("foodName", food.foodName)
            foodObj.put("weight", food.weight)
            foodObj.put("scanTime", food.scanTime)
            jsonArray.put(foodObj)
        }
        
        editor.putString(PREF_UNFINISHED_FOODS, jsonArray.toString())
        editor.apply()
        
        // Trigger pembaruan widget
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(
            android.content.ComponentName(context, FoodWiseWidgetProvider::class.java)
        )
        onUpdate(context, appWidgetManager, appWidgetIds)
    }
    
    /**
     * Update tampilan makanan yang belum selesai
     */
    private fun updateUnfinishedFoodsView(context: Context, views: RemoteViews, prefs: SharedPreferences) {
        val unfinishedFoodsJson = prefs.getString(PREF_UNFINISHED_FOODS, null)
        
        // Jika tidak ada data makanan yang belum selesai
        if (unfinishedFoodsJson.isNullOrEmpty()) {
            views.setViewVisibility(R.id.unfinished_foods_container, View.VISIBLE)
            views.setViewVisibility(R.id.unfinished_foods_empty, View.VISIBLE)
            views.setViewVisibility(R.id.unfinished_foods_list, View.GONE)
            return
        }
        
        try {
            val jsonArray = JSONArray(unfinishedFoodsJson)
            
            // Jika array kosong
            if (jsonArray.length() == 0) {
                views.setViewVisibility(R.id.unfinished_foods_container, View.VISIBLE)
                views.setViewVisibility(R.id.unfinished_foods_empty, View.VISIBLE)
                views.setViewVisibility(R.id.unfinished_foods_list, View.GONE)
                return
            }
            
            views.setViewVisibility(R.id.unfinished_foods_container, View.VISIBLE)
            views.setViewVisibility(R.id.unfinished_foods_empty, View.GONE)
            views.setViewVisibility(R.id.unfinished_foods_list, View.VISIBLE)
            
            // Menggunakan tampilan yang lebih sederhana karena keterbatasan widget
            // Menampilkan hanya makanan pertama
            if (jsonArray.length() > 0) {
                val foodObj = jsonArray.getJSONObject(0)
                val foodName = foodObj.getString("foodName")
                val weight = foodObj.getDouble("weight")
                
                val foodText = "$foodName (${String.format("%.1f", weight)}g)"
                views.setTextViewText(R.id.unfinished_foods_list, foodText)
            }
            
            // Jika ada lebih banyak makanan, tampilkan jumlahnya
            if (jsonArray.length() > 1) {
                val remainingCount = jsonArray.length() - 1
                val message = "Dan $remainingCount makanan lainnya"
                views.setTextViewText(R.id.unfinished_foods_empty, message)
                views.setViewVisibility(R.id.unfinished_foods_empty, View.VISIBLE)
            }
            
        } catch (e: Exception) {
            e.printStackTrace()
            views.setViewVisibility(R.id.unfinished_foods_container, View.VISIBLE)
            views.setViewVisibility(R.id.unfinished_foods_empty, View.VISIBLE)
            views.setViewVisibility(R.id.unfinished_foods_list, View.GONE)
        }
    }
} 