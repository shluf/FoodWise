import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import '../../models/food_scan_model.dart'; // Adjust import path as needed

class ResultView extends StatelessWidget {
  final File? image;
  final bool isRemainingFoodScan;
  final FoodScanModel? originalScan;
  final String? foodName;
  final Map<String, dynamic>? scanResult;
  final double? carbonFootprint;
  final List<FoodItem> foodItems;
  final List<PotentialFoodWasteItem> potentialFoodWasteItems;
  final bool isEaten;
  final bool isSaving;
  final bool showAddFoodItemForm;
  final bool showAddItemForm;
  final TextEditingController weightController;
  final TextEditingController newItemNameController;
  final TextEditingController newItemWeightController;
  final String Function(DateTime) formatTime;
  final String Function(Duration) formatDuration;
  final double Function() calculateTotalOriginalWeight;
  final double Function() calculatePercentageRemaining;
  final void Function(bool) onIsEatenChanged;
  final void Function(String) onWeightChanged;
  final void Function() toggleAddFoodItemForm;
  final void Function() addNewFoodItem;
  final void Function(int, double) updateFoodItemWeight;
  final void Function(int) removeFoodItem;
  final void Function() toggleAddItemForm;
  final void Function() addNewWasteItem;
  final void Function(int) removeWasteItem;
  final void Function() resetScan;
  final void Function() saveFoodScan;
  final void Function() onBackPressed;

  const ResultView({
    Key? key,
    required this.image,
    required this.isRemainingFoodScan,
    this.originalScan,
    this.foodName,
    this.scanResult,
    this.carbonFootprint,
    required this.foodItems,
    required this.potentialFoodWasteItems,
    required this.isEaten,
    required this.isSaving,
    required this.showAddFoodItemForm,
    required this.showAddItemForm,
    required this.weightController,
    required this.newItemNameController,
    required this.newItemWeightController,
    required this.formatTime,
    required this.formatDuration,
    required this.calculateTotalOriginalWeight,
    required this.calculatePercentageRemaining,
    required this.onIsEatenChanged,
    required this.onWeightChanged,
    required this.toggleAddFoodItemForm,
    required this.addNewFoodItem,
    required this.updateFoodItemWeight,
    required this.removeFoodItem,
    required this.toggleAddItemForm,
    required this.addNewWasteItem,
    required this.removeWasteItem,
    required this.resetScan,
    required this.saveFoodScan,
    required this.onBackPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // App Bar that stays visible when scrolling
            SliverAppBar(
              expandedHeight: image != null ? 250 : 100,
              floating: false,
              pinned: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.only(left: 8, top: 8),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 6,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: onBackPressed, // Use callback
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: image != null
                  ? Container(
                      width: double.infinity,
                      height: 250,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: FileImage(image!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : Container(color: Colors.grey[200]),
              ),
            ),
            
            // Content
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info about leftover food scan
                    if (isRemainingFoodScan && originalScan != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Initial Food Information',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text('Food: ${originalScan!.foodName}'),
                            Text('Total weight: ${calculateTotalOriginalWeight().toStringAsFixed(1)} grams'),
                            const SizedBox(height: 12),
                            const Text(
                              'Scan leftover food to estimate the percentage remaining',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    
                    // Show analysis results
                    if (foodName != null) ...[
                      // Time and Food Name
                      Text(
                        formatTime(DateTime.now()), // Use callback
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black.withOpacity(0.6),
                        ),
                      ),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  foodName!,
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                // Duration Badge
                                if (originalScan != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.timer, size: 15, color: Colors.black54),
                                      const SizedBox(width: 4),
                                      Text(
                                        formatDuration(originalScan!.finishTime?.difference(originalScan!.scanTime) ?? Duration.zero), // Use callback
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Row(
                              children: [
                                // Assuming count is always 1 for now, or needs to be passed if variable
                                Text('1 ', style: TextStyle(fontWeight: FontWeight.bold)), 
                                Icon(Icons.colorize, size: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Carbon Footprint (not food weight)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_fire_department, color: Colors.black), // Icon represents carbon
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Carbon Footprint',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${carbonFootprint?.toStringAsFixed(2)} kg CO₂e',
                                  style: const TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Confidence Level Information
                      if (scanResult?['confidence'] != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'AI Confidence Level',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (scanResult!['confidence'] is num)
                                    Text(
                                      '${((scanResult!['confidence'] as num).toDouble() * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (scanResult!['confidence'] is num)
                                    ? (scanResult!['confidence'] as num).toDouble()
                                    : 0.0,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    (scanResult!['confidence'] is num && (scanResult!['confidence'] as num).toDouble() > 0.7)
                                      ? Colors.green
                                      : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Show percentage of leftover food if this is a leftover food scan
                      if (isRemainingFoodScan && originalScan != null && double.tryParse(weightController.text) != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Leftover Food Analysis',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildAnalysisInfoItem("Initial Weight", "${calculateTotalOriginalWeight().round()} grams"),
                                  _buildAnalysisInfoItem("Remaining Weight", "${double.tryParse(weightController.text)?.round() ?? 0} grams"),
                                  _buildAnalysisInfoItem("Status", "Remaining"),
                                ],
                              ),
                              const Divider(height: 40),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.auto_awesome, color: Colors.black, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        "AI Analysis",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "Food Remaining: ${calculatePercentageRemaining().toStringAsFixed(1)}%", // Use callback
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _buildPercentageIndicator(context), // Pass context
                            ],
                          ),
                        ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Food Components
                    const Text(
                      'Food Components',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Food Item Components',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              IconButton(
                                icon: Icon(showAddFoodItemForm ? Icons.remove : Icons.add), // Use state variable
                                onPressed: toggleAddFoodItemForm, // Use callback
                                tooltip: showAddFoodItemForm ? 'Close Form' : 'Add Item',
                              ),
                            ],
                          ),
                          
                          if (showAddFoodItemForm) ...[ // Use state variable
                            const SizedBox(height: 12),
                            const Text('Add Food Item:'),
                            const SizedBox(height: 8),
                            TextField(
                              controller: newItemNameController, // Use controller
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Item Name',
                                hintText: 'example: Fried Chicken',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: newItemWeightController, // Use controller
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Weight (grams)',
                                hintText: 'example: 150',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: addNewFoodItem, // Use callback
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('Add Item'),
                              ),
                            ),
                            const Divider(height: 24),
                          ],
                          
                          if (foodItems.isEmpty) // Use state variable
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  'No food item components detected',
                                  style: TextStyle(fontStyle: FontStyle.italic),
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: foodItems.length, // Use state variable
                              itemBuilder: (context, index) {
                                // Tambahkan pengecekan null dan data tidak valid
                                if (index < 0 || index >= foodItems.length) {
                                  return const SizedBox.shrink(); // Return empty widget
                                }
                                
                                final item = foodItems[index]; // Use state variable
                                if (item == null) {
                                  return const SizedBox.shrink(); // Return empty widget
                                }
                                
                                // Nilai default jika properti item null
                                final itemName = item.itemName.isNotEmpty ? item.itemName : 'Unnamed Food';
                                final itemWeight = item.weight > 0 ? item.weight : 1.0;
                                
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              itemName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${itemWeight.toStringAsFixed(0)} g',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, size: 18),
                                            onPressed: () => removeFoodItem(index), // Use callback
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      // Slider for adjusting weight
                                      Row(
                                        children: [
                                          const Text('0 g'),
                                          Expanded(
                                            child: Slider(
                                              value: itemWeight,
                                              min: 0,
                                              max: 500, // Consider making max dynamic or passed
                                              divisions: 50,
                                              label: itemWeight.round().toString(),
                                              onChanged: (double value) {
                                                updateFoodItemWeight(index, value); // Use callback
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
                    
                    const SizedBox(height: 16),
                    
                    // Potential Food Waste Items
                    const Text(
                      'Potential Food Waste',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Potential Food Waste Items',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              IconButton(
                                icon: Icon(showAddItemForm ? Icons.remove : Icons.add), // Use state variable
                                onPressed: toggleAddItemForm, // Use callback
                                tooltip: showAddItemForm ? 'Close Form' : 'Add Item',
                              ),
                            ],
                          ),
                          
                          if (showAddItemForm) ...[ // Use state variable
                            const SizedBox(height: 12),
                            const Text('Add New Food Waste Item:'),
                            const SizedBox(height: 8),
                            TextField(
                              controller: newItemNameController, // Use controller (shared, might need separate)
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Item Name',
                                hintText: 'example: Chicken Bone',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: newItemWeightController, // Use controller (shared, might need separate)
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Weight (grams)',
                                hintText: 'example: 25',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: addNewWasteItem, // Use callback
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('Add Item'),
                              ),
                            ),
                            const Divider(height: 24),
                          ],
                          
                          if (potentialFoodWasteItems.isEmpty) // Use state variable
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  'No food waste items detected',
                                  style: TextStyle(fontStyle: FontStyle.italic),
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: potentialFoodWasteItems.length, // Use state variable
                              itemBuilder: (context, index) {
                                // Tambahkan pengecekan null dan data tidak valid
                                if (index < 0 || index >= potentialFoodWasteItems.length) {
                                  return const SizedBox.shrink(); // Return empty widget
                                }
                                
                                final item = potentialFoodWasteItems[index]; // Use state variable
                                if (item == null) {
                                  return const SizedBox.shrink(); // Return empty widget
                                }
                                
                                // Nilai default jika properti item null
                                final itemName = item.itemName.isNotEmpty ? item.itemName : 'Unnamed Waste';
                                final emission = item.estimatedCarbonEmission > 0 ? item.estimatedCarbonEmission : 0.1;
                                
                                return Dismissible(
                                  key: Key('waste_item_${index}_${itemName}'),
                                  background: Container(
                                    color: Colors.red,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 16),
                                    child: const Icon(Icons.delete, color: Colors.white),
                                  ),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (direction) {
                                    removeWasteItem(index); // Use callback
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${itemName}: ${emission.toStringAsFixed(2)} kg CO₂e', 
                                            style: const TextStyle(fontSize: 15),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 18),
                                          onPressed: () => removeWasteItem(index), // Use callback
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
                          if (potentialFoodWasteItems.isNotEmpty) // Use state variable
                            const Text(
                              'Swipe item to the left to delete',
                              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                            ),
                          const SizedBox(height: 8),
                          const Text(
                            'Avoid throwing away leftover food to reduce carbon footprint.',
                            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Total Food Weight
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Food Weight',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: weightController, // Use controller
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Total Food Weight (grams)',
                              hintText: 'Example: 250',
                            ),
                            onChanged: onWeightChanged, // Use callback
                          ),
                          const SizedBox(height: 16),
                          
                          // Switch to mark food as completely eaten
                          if (isRemainingFoodScan) // Use state variable
                            SwitchListTile(
                              title: Text(
                                'Food eaten completely',
                                style: TextStyle(
                                  color: isEaten ? Colors.green : Colors.black, // Use state variable
                                ),
                              ),
                              value: isEaten, // Use state variable
                              onChanged: onIsEatenChanged, // Use callback
                              activeColor: Colors.black,
                            ),
                        ],
                      ),
                    ),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: resetScan, // Use callback
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.black),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Retake Photo',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSaving ? null : saveFoodScan, // Use state variable and callback
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              isRemainingFoodScan ? 'Save Leftover Data' : 'Save Data', // Use state variable
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        // Loading overlay
        if (isSaving) // Use state variable
          Container(
            color: Colors.black.withOpacity(0.5),
            width: double.infinity,
            height: double.infinity,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 20),
                  Text(
                    'Saving food data...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // Helper methods moved from ScanScreen
  Widget _buildAnalysisInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPercentageIndicator(BuildContext context) {
    final percentage = calculatePercentageRemaining(); // Use callback
    
    final availableWidth = MediaQuery.of(context).size.width - 40 - 40; // Assuming 20 padding on each side and inside

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
              width: availableWidth * (percentage / 100).clamp(0.0, 1.0), 
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

// Placeholder models (if not imported correctly)
// class FoodScanModel { final String foodName; final DateTime scanTime; final DateTime? finishTime; final List<FoodItem> foodItems; const FoodScanModel({required this.foodName, required this.scanTime, this.finishTime, required this.foodItems}); FoodScanModel copyWith({bool? isDone, bool? isEaten, List<FoodItem>? foodItems, double? aiRemainingPercentage, String? afterImageUrl, DateTime? finishTime}) => this; }
// class FoodItem { final String itemName; final double weight; final double? remainingWeight; const FoodItem({required this.itemName, required this.weight, this.remainingWeight}); }
// class PotentialFoodWasteItem { final String itemName; final double estimatedCarbonEmission; const PotentialFoodWasteItem({required this.itemName, required this.estimatedCarbonEmission}); } 