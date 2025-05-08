import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/food_scan_model.dart';
import '../screens/scan/food_waste_scan_screen.dart';

class FoodComparisonResultWidget extends StatelessWidget {
  final FoodScanModel foodScan;
  final double remainingPercentage;
  final double confidence;
  final File? beforeImageFile;
  final File? afterImageFile;
  final String? beforeImageUrl;
  final String? afterImageUrl;
  
  const FoodComparisonResultWidget({
    Key? key,
    required this.foodScan,
    required this.remainingPercentage,
    required this.confidence,
    this.beforeImageFile,
    this.afterImageFile,
    this.beforeImageUrl,
    this.afterImageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar yang akan tersembunyi saat scroll
          SliverAppBar(
            expandedHeight: screenWidth * 0.8,
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
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildBeforeImage(),
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
                  // Time stamp from food scan
                  Text(
                    _formatTime(foodScan.scanTime),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),
                  
                  // Food name and counter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              foodScan.foodName,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            // Duration Badge
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
                                    _formatDuration(foodScan.finishTime?.difference(foodScan.scanTime) ?? Duration.zero),
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
                            Text('1 ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Icon(Icons.colorize, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Food weight
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department, color: Colors.black),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Food Weight',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${(_calculateTotalWeight()/1000).toStringAsFixed(1).replaceAll('.', ',')} Kg',
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
                  
                  // Image comparison
                  const Text(
                    'Image Comparison',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'Before',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            AspectRatio(
                              aspectRatio: 1.0,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _buildBeforeImage(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'After',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            AspectRatio(
                              aspectRatio: 1.0,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _buildAfterImage(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // AI Analysis Result
                  const Text(
                    'AI Analysis Result',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // AI Analysis Result detail
                  _buildAIAnalysisResult(),
                  
                  const SizedBox(height: 24),
                  
                  // Ingredients from food items
                  _buildIngredients(context),
                  
                  const SizedBox(height: 70), // Space for bottom buttons
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FoodWasteScanScreen(
                      foodScanId: foodScan.id,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Fix Result'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.black),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAIAnalysisResult() {
    // Calculate initial and residual weights
    final initialWeight = _calculateTotalWeight();
    final residualWeight = _calculateTotalRemainingWeight();
    final remainingPercent = residualWeight > 0 ? (residualWeight / initialWeight) * 100 : 0;
    final roundedPercent = remainingPercent.round();
    
    // Calculate environmental impact
    final carbonEmission = residualWeight * 0.0048; // kg CO2 per gram of food waste
    final waterWasted = residualWeight * 0.9; // 0.9 liter of water per gram of food
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
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
          // Initial Weight, Residual Weight, Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAnalysisInfoItem("Initial Weight", "${initialWeight.round()} gram"),
              _buildAnalysisInfoItem("Residual Weight", "${residualWeight.round()} gram"),
              _buildAnalysisInfoItem("Status", "Remaining"),
            ],
          ),
          
          const Divider(height: 40),
          
          // AI Analysis with progress bar
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
                "Food Remaining: $roundedPercent%",
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 10),
          
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: remainingPercent / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Environmental Impact
          const Text(
            "Environmental Impact",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Carbon emissions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.eco, color: Colors.black, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Carbon emissions from food waste: ${carbonEmission.toStringAsFixed(2)} kg CO2",
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Water wasted
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.water_drop, color: Colors.black, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Water wasted in the manufacturing process: ${waterWasted.toStringAsFixed(1)} liter",
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Tip text
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: Colors.grey, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "By reducing food waste, you help reduce the environmental impact of food production and disposal.",
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
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
  
  Widget _buildIngredients(BuildContext context) {
    List<Widget> ingredientWidgets = [];
    
    // Add all food items
    for (var item in foodScan.foodItems) {
      ingredientWidgets.add(
        _ingredientItem(context, item.itemName, '${item.weight.toStringAsFixed(1)} g')
      );
    }
    
    // Add the "Add" button
    ingredientWidgets.add(_buildAddItemButton(context));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ingredients',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        // Grid dengan 3 kolom
        GridView.count(
          crossAxisCount: 3,
          childAspectRatio: 0.8,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: ingredientWidgets,
        ),
      ],
    );
  }
  
  Widget _ingredientItem(BuildContext context, String name, String weight) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name, 
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        weight,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Tombol hapus di bagian bawah
                Align(
                  alignment: Alignment.bottomRight,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _confirmDeleteItem(context, name),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAddItemButton(BuildContext context) {
    return InkWell(
      onTap: () => _showAddItemDialog(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, size: 32),
              SizedBox(height: 8),
              Text(
                'Add',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _confirmDeleteItem(BuildContext context, String itemName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete "$itemName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Implementasi penghapusan item di sini
                Navigator.of(context).pop();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
  
  void _showAddItemDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddItemScreen(),
      ),
    );
  }
  
  Widget _buildBeforeImage() {
    // Prioritaskan URL jika tersedia
    if (beforeImageUrl != null && beforeImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: beforeImageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.error, color: Colors.red, size: 40),
        ),
      );
    }
    
    // Gunakan URL dari food scan jika tersedia
    if (foodScan.imageUrl != null && foodScan.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: foodScan.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.error, color: Colors.red, size: 40),
        ),
      );
    }
    
    // Gunakan file lokal jika tersedia
    if (beforeImageFile != null) {
      return Image.file(
        beforeImageFile!,
        fit: BoxFit.cover,
      );
    }
    
    // Fallback
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.image_not_supported,
          size: 50,
          color: Colors.grey,
        ),
      ),
    );
  }
  
  Widget _buildAfterImage() {
    // Prioritaskan URL jika tersedia
    if (afterImageUrl != null && afterImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: afterImageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.error, color: Colors.red, size: 40),
        ),
      );
    }
    
    // Gunakan URL dari food scan jika tersedia
    if (foodScan.afterImageUrl != null && foodScan.afterImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: foodScan.afterImageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.error, color: Colors.red, size: 40),
        ),
      );
    }
    
    // Gunakan file lokal jika tersedia
    if (afterImageFile != null) {
      return Image.file(
        afterImageFile!,
        fit: BoxFit.cover,
      );
    }
    
    // Fallback
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.image_not_supported,
          size: 50,
          color: Colors.grey,
        ),
      ),
    );
  }
  
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$hour.$minute';
  }
  
  String _formatDuration(Duration duration) {
    if (duration.inHours < 1) {
      return '${duration.inMinutes} min';
    } else if (duration.inHours == 1) {
      return '1 hour';
    } else {
      return '${duration.inHours} hours';
    }
  }
  
  String _formatDate(DateTime dateTime) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    final day = dateTime.day;
    final month = months[dateTime.month - 1];
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$day $month $year, $hour:$minute';
  }

  double _calculateTotalWeight() {
    if (foodScan.foodItems.isEmpty) {
      return 0.0;
    }
    return foodScan.foodItems.fold(0.0, (sum, item) => sum + item.weight);
  }

  double _calculateTotalRemainingWeight() {
    if (foodScan.foodItems.isEmpty) {
      return 0.0;
    }
    return foodScan.foodItems.fold(0.0, (sum, item) => sum + (item.remainingWeight ?? 0.0));
  }
}

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({Key? key}) : super(key: key);

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.grey[300],
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Adding an Item',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Describe what needs to be added',
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Weight of food added',
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Validasi dan simpan item baru
                  if (_nameController.text.isNotEmpty && _weightController.text.isNotEmpty) {
                    // Implementasi penyimpanan item
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Add Item'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 