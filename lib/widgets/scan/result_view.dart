import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/food_scan_model.dart';
import './add_ingredient_screen.dart';

class ResultView extends StatelessWidget {
  final File? image;
  final String? imageUrl;
  final bool isRemainingFoodScan;
  final FoodScanModel? originalScan;
  final String? foodName;
  final Map<String, dynamic>? scanResult;
  final double? carbonFootprint;
  final List<FoodItem> foodItems;
  final List<PotentialFoodWasteItem> potentialFoodWasteItems;
  final bool isEaten;
  final bool isSaving;
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
  final DateTime scanTime;
  final int count;
  final void Function(int) onCountChanged;

  const ResultView({
    Key? key,
    required this.image,
    required this.imageUrl,
    required this.isRemainingFoodScan,
    this.originalScan,
    this.foodName,
    this.scanResult,
    this.carbonFootprint,
    required this.foodItems,
    required this.potentialFoodWasteItems,
    required this.isEaten,
    required this.isSaving,
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
    required this.scanTime,
    required this.count,
    required this.onCountChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 100,
              child: Container(color: Colors.grey[200]),
            ),
          Positioned.fill(
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: SizedBox(height: 50),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30.0),
                        topRight: Radius.circular(30.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (foodName != null) ...[
                          Text(
                            formatTime(scanTime),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      foodName!,
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (isRemainingFoodScan && originalScan?.finishTime != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6.0),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.timer_outlined, size: 15, color: Colors.grey[700]),
                                              const SizedBox(width: 4),
                                              Text(
                                                formatDuration(originalScan!.finishTime!.difference(originalScan!.scanTime)),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _showEditCountDialog(context, count, onCountChanged),
                                icon: Icon(Icons.edit, size: 18, color: Colors.grey[700]),
                                label: Text(
                                  '$count',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  backgroundColor: Colors.grey[100],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(color: Colors.grey[300]!)
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (foodName != null) ...[
                          const Text(
                            'Scan Result',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (image != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                image!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          if (image == null && imageUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(imageUrl!, height: 200, width: double.infinity, fit: BoxFit.cover),
                            ),
                          const SizedBox(height: 16),
                          const Text(
                            'Image Description',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                           const SizedBox(height: 8),
                          _buildImageDescriptionCard(context),
                        ],
                        if (foodName != null)
                          const SizedBox(height: 24),
                        if (isRemainingFoodScan && originalScan != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
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
                                  'Original Scan Details',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                const SizedBox(height: 10),
                                Text('Food: ${originalScan!.foodName}', style: const TextStyle(fontSize: 14)),
                                const SizedBox(height: 4),
                                Text('Initial Weight: ${calculateTotalOriginalWeight().toStringAsFixed(0)} grams', style: const TextStyle(fontSize: 14)),
                                if (originalScan?.scanTime != null) ...[
                                  const SizedBox(height: 4),
                                  Text('Scanned On: ${originalScan!.scanTime.day}/${originalScan!.scanTime.month}/${originalScan!.scanTime.year} at ${formatTime(originalScan!.scanTime)}', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                                ],
                              ],
                            ),
                          ),
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
                                    _buildAnalysisInfoItem("Status", isEaten? "Eaten" : "Remaining"),
                                  ],
                                ),
                                const Divider(height: 40),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.bar_chart_rounded, color: Colors.black, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          "Percentage Remaining",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      "${calculatePercentageRemaining().toStringAsFixed(1)}%",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                _buildPercentageIndicator(context),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),
                        _buildIngredientsSection(context),
                        const SizedBox(height: 24),
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
                                      color: Colors.black,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(showAddItemForm ? Icons.remove_circle_outline : Icons.add_circle_outline),
                                    onPressed: toggleAddItemForm,
                                    tooltip: showAddItemForm ? 'Close Form' : 'Add Waste Item',
                                  ),
                                ],
                              ),
                              if (showAddItemForm) ...[
                                const SizedBox(height: 12),
                                const Text('Add New Food Waste Item:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: newItemNameController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Item Name',
                                    hintText: 'example: Chicken Bone',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: newItemWeightController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Weight (grams)',
                                    hintText: 'example: 25',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        newItemNameController.clear();
                                        newItemWeightController.clear();
                                        toggleAddItemForm();
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: addNewWasteItem,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black,
                                      ),
                                      child: const Text('Add Waste Item', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                              ],
                              if (potentialFoodWasteItems.isEmpty && !showAddItemForm)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: Text(
                                      'No food waste items detected or added.',
                                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                                    ),
                                  ),
                                )
                              else if (potentialFoodWasteItems.isNotEmpty)
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: potentialFoodWasteItems.length,
                                  itemBuilder: (context, index) {
                                    if (index < 0 || index >= potentialFoodWasteItems.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final item = potentialFoodWasteItems[index];
                                    if (item == null) {
                                      return const SizedBox.shrink();
                                    }
                                    final itemName = item.itemName.isNotEmpty ? item.itemName : 'Unnamed Waste';
                                    final emission = item.estimatedCarbonEmission > 0 ? item.estimatedCarbonEmission : 0.1;
                                    return Dismissible(
                                      key: Key('waste_item_${index}_${itemName.hashCode}'),
                                      background: Container(
                                        color: Colors.redAccent,
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 20),
                                        child: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
                                      ),
                                      direction: DismissDirection.endToStart,
                                      onDismissed: (direction) {
                                        removeWasteItem(index);
                                      },
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                                        title: Text(
                                          itemName,
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                        ),
                                        trailing: Text(
                                          '${emission.toStringAsFixed(2)} kg CO₂e',
                                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              const SizedBox(height: 8),
                              if (potentialFoodWasteItems.isNotEmpty)
                                const Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'Swipe item to the left to delete',
                                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.grey),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              const Text(
                                'Avoid throwing away leftover food to reduce carbon footprint.',
                                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
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
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: weightController,
                                keyboardType: TextInputType.number,
                                enabled: false,
                                style: const TextStyle(color: Colors.black),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Total Food Weight (grams)',
                                  hintText: 'Example: 250',
                                ),
                                onChanged: onWeightChanged,
                              ),
                              const SizedBox(height: 16),
                              if (isRemainingFoodScan)
                                SwitchListTile(
                                  title: Text(
                                    'Food eaten completely',
                                    style: TextStyle(
                                      color: isEaten ? Colors.green : Colors.black,
                                      fontWeight: isEaten ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  value: isEaten,
                                  onChanged: onIsEatenChanged,
                                  activeColor: Colors.green,
                                  inactiveThumbColor: Colors.grey,
                                ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: resetScan,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.black),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text(
                                  'Retake Photo',
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isSaving ? null : saveFoodScan,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  disabledBackgroundColor: Colors.grey[400],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: Text(
                                  isSaving ? 'Saving...' : (isRemainingFoodScan ? 'Save Leftover' : 'Save Data'),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
          ),
          if (isSaving)
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
      ),
    );
  }

  Widget _buildIngredientsSection(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = (screenWidth / 130).floor();
    if (crossAxisCount < 2) crossAxisCount = 2;
    if (crossAxisCount > 4) crossAxisCount = 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ingredients',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.2,
          ),
          itemCount: foodItems.length + 1,
          itemBuilder: (context, index) {
            if (index == foodItems.length) {
              return _buildAddIngredientButtonCard(context);
            }
            final item = foodItems[index];
            return _buildIngredientItemCard(context, item, index);
          },
        ),
        if (foodItems.isEmpty)
           Padding(
             padding: const EdgeInsets.symmetric(vertical: 20.0),
             child: Center(
               child: Text(
                 'No ingredients added yet. Tap "+" to add.',
                 style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
               ),
             ),
           ),
      ],
    );
  }

  Widget _buildIngredientItemCard(BuildContext context, FoodItem item, int index) {
    String displayWeight = "${item.weight.toStringAsFixed(0)} g";

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          final FoodItem? updatedItem = await Navigator.push<FoodItem>(
            context,
            MaterialPageRoute(
              builder: (context) => AddIngredientScreen(foodItemToEdit: item),
            ),
          );
          if (updatedItem != null) {
            if (item.itemName != updatedItem.itemName) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item name updated. Weight updated. (Full item update needs callback change)')),
              );
            }
            updateFoodItemWeight(index, updatedItem.weight);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(right: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.itemName.isNotEmpty ? item.itemName : 'Unnamed Food',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayWeight,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: IconButton(
                  icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Options',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              border: Border(
                                bottom: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            child: Text(
                              'Options for ${item.itemName.isNotEmpty ? item.itemName : 'Food Item'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Wrap(
                            children: <Widget>[
                              ListTile(
                                leading: const Icon(Icons.edit),
                                title: const Text('Edit'),
                                onTap: () async {
                                  Navigator.pop(ctx);
                                  final FoodItem? updatedItem = await Navigator.push<FoodItem>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddIngredientScreen(foodItemToEdit: item),
                                    ),
                                  );
                                  if (updatedItem != null) {
                                    if (item.itemName != updatedItem.itemName) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Ingredient name changed to "${updatedItem.itemName}". Weight to ${updatedItem.weight}g. (Persisting name change requires ScanScreen update)'))
                                      );
                                    }
                                    updateFoodItemWeight(index, updatedItem.weight);
                                  }
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.delete_outline, color: Colors.red),
                                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  removeFoodItem(index);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddIngredientButtonCard(BuildContext context) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.grey[50],
      child: InkWell(
        onTap: () async {
          final FoodItem? newItem = await Navigator.push<FoodItem>(
            context,
            MaterialPageRoute(builder: (context) => const AddIngredientScreen()),
          );
          if (newItem != null) {
            newItemNameController.text = newItem.itemName;
            newItemWeightController.text = newItem.weight.toString();
            addNewFoodItem();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 30, color: Colors.grey[700]),
              const SizedBox(height: 6),
              Text(
                'Add',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageDescriptionCard(BuildContext context) {
    final double progressValue;
    final String progressLabel;
    IconData iconData = Icons.auto_awesome_outlined;

    if (isRemainingFoodScan) {
      progressValue = calculatePercentageRemaining() / 100;
      progressLabel = 'Food Remaining';
    } else {
      progressValue = (scanResult?['confidence'] is num)
          ? (scanResult!['confidence'] as num).toDouble()
          : 0.3;
      progressLabel = 'AI Confidence';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isRemainingFoodScan)
             Text(
              foodName ?? "Image Description",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          if (!isRemainingFoodScan) const SizedBox(height: 16),
          Row(
            children: [
              Image.asset('assets/icons/footprint_icon.png', width: 20, height: 20),
              const SizedBox(width: 8),
              Text(
                'Carbon Footprint: ${carbonFootprint?.toStringAsFixed(2) ?? "N/A"} kg CO₂e',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(iconData, color: Colors.black, size: 20),
              const SizedBox(width: 8),
              Text(
                progressLabel,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
               const Spacer(),
              Text(
                isRemainingFoodScan
                  ? '${(progressValue * 100).toStringAsFixed(0)}%'
                  : '${(progressValue * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
            ),
          ),
        ],
      ),
    );
  }

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
    final percentage = calculatePercentageRemaining();
    final availableWidth = MediaQuery.of(context).size.width - 40 - 40;

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
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showEditCountDialog(BuildContext context, int currentCount, Function(int) onCountChangedCallback) {
    final TextEditingController countController = TextEditingController(text: currentCount.toString());
    int tempCount = currentCount;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (stfContext, stfSetState) {
            return AlertDialog(
              title: const Text('Edit Quantity'),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      if (tempCount > 1) {
                        stfSetState(() {
                          tempCount--;
                          countController.text = tempCount.toString();
                        });
                      }
                    },
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: countController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(8),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        final newCount = int.tryParse(value);
                        if (newCount != null && newCount > 0) {
                          tempCount = newCount;
                        } else if (value.isEmpty) {
                        } else {
                          countController.text = tempCount.toString();
                          countController.selection = TextSelection.fromPosition(TextPosition(offset: countController.text.length));
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                       stfSetState(() {
                        tempCount++;
                        countController.text = tempCount.toString();
                      });
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                TextButton(
                  child: const Text('Save'),
                  onPressed: () {
                    final finalCount = int.tryParse(countController.text);
                    if (finalCount != null && finalCount > 0) {
                      onCountChangedCallback(finalCount);
                      Navigator.of(dialogContext).pop();
                    } else {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid quantity greater than 0.')),
                      );
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }
}