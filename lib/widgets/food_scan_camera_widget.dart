import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

// Widget untuk membuat sudut kotak scan dengan sudut rounded
class CornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;
  final double cornerRadius;

  CornerPainter({
    required this.color,
    this.strokeWidth = 4.0,
    this.cornerLength = 30.0,
    this.cornerRadius = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final width = size.width;
    final height = size.height;

    // Top left corner
    final topLeftPath = Path()
      ..moveTo(cornerRadius, 0)
      ..lineTo(cornerLength, 0)
      ..moveTo(0, cornerRadius)
      ..lineTo(0, cornerLength)
      ..addArc(
        Rect.fromLTWH(0, 0, cornerRadius * 2, cornerRadius * 2),
        -pi/2,
        pi/2,
      );
    canvas.drawPath(topLeftPath, paint);

    // Top right corner
    final topRightPath = Path()
      ..moveTo(width - cornerLength, 0)
      ..lineTo(width - cornerRadius, 0)
      ..moveTo(width, cornerRadius)
      ..lineTo(width, cornerLength)
      ..addArc(
        Rect.fromLTWH(width - cornerRadius * 2, 0, cornerRadius * 2, cornerRadius * 2),
        0,
        pi/2,
      );
    canvas.drawPath(topRightPath, paint);

    // Bottom right corner
    final bottomRightPath = Path()
      ..moveTo(width, height - cornerLength)
      ..lineTo(width, height - cornerRadius)
      ..moveTo(width - cornerRadius, height)
      ..lineTo(width - cornerLength, height)
      ..addArc(
        Rect.fromLTWH(width - cornerRadius * 2, height - cornerRadius * 2, cornerRadius * 2, cornerRadius * 2),
        pi/2,
        pi/2,
      );
    canvas.drawPath(bottomRightPath, paint);

    // Bottom left corner
    final bottomLeftPath = Path()
      ..moveTo(cornerLength, height)
      ..lineTo(cornerRadius, height)
      ..moveTo(0, height - cornerRadius)
      ..lineTo(0, height - cornerLength)
      ..addArc(
        Rect.fromLTWH(0, height - cornerRadius * 2, cornerRadius * 2, cornerRadius * 2),
        pi,
        pi/2,
      );
    canvas.drawPath(bottomLeftPath, paint);
  }

  @override
  bool shouldRepaint(CornerPainter oldDelegate) => false;
}

// Widget for camera preview with scan frame
class FoodScanCameraWidget extends StatefulWidget {
  final Function(File) onImageCaptured;
  final String? previousImagePath;
  final bool showSwitchCameraButton;
  
  const FoodScanCameraWidget({
    Key? key,
    required this.onImageCaptured,
    this.previousImagePath,
    this.showSwitchCameraButton = true,
  }) : super(key: key);

  @override
  State<FoodScanCameraWidget> createState() => _FoodScanCameraWidgetState();
}

class _FoodScanCameraWidgetState extends State<FoodScanCameraWidget> with WidgetsBindingObserver {
  bool _flashlightOn = false;
  bool _showOverlay = true;
  double _overlayOpacity = 0.5;
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  int _selectedCameraIndex = 0;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }
  
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        return;
      }
      
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first
      );
      
      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  void _toggleFlashlight() async {
    if (!_isCameraInitialized || _cameraController == null) return;
    
    try {
      final newValue = !_flashlightOn;
      await _cameraController!.setFlashMode(
        newValue ? FlashMode.torch : FlashMode.off
      );
      
      setState(() {
        _flashlightOn = newValue;
      });
    } catch (e) {
      print('Error toggling flashlight: $e');
    }
  }
  
  void _switchCamera() async {
    if (_cameras == null || _cameras!.isEmpty || _cameras!.length <= 1) return;
    
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    
    // Dispose current controller
    await _cameraController?.dispose();
    
    // Reinitialize with new camera
    if (mounted) {
      setState(() {
        _isCameraInitialized = false;
      });
      
      _initializeCamera();
    }
  }
  
  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isCapturing) {
      return;
    }
    
    try {
      setState(() {
        _isCapturing = true;
      });
      
      final XFile imageFile = await _cameraController!.takePicture();
      
      if (mounted) {
        final capturedFile = File(imageFile.path);
        widget.onImageCaptured(capturedFile);
      }
    } catch (e) {
      print('Error capturing image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  // Widget to overlay previous image with adjustable transparency
  Widget _buildPreviousImageOverlay() {
    if (widget.previousImagePath == null || widget.previousImagePath!.isEmpty) {
      return Container();
    }

    return Positioned.fill(
      child: Opacity(
        opacity: _overlayOpacity,
        child: Image.file(
          File(widget.previousImagePath!),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              size: 60,
              color: Colors.black,
            ),
            SizedBox(height: 16),
            Text(
              'Initializing camera...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Camera preview
        SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: CameraPreview(_cameraController!),
        ),
        
        // Previous image overlay if available
        if (_showOverlay && widget.previousImagePath != null)
          _buildPreviousImageOverlay(),
        
        // Scan frame corners
        Center(
          child: SizedBox(
            width: 250,
            height: 250,
            child: CustomPaint(
              painter: CornerPainter(
                color: Colors.white,
                strokeWidth: 3.0,
                cornerLength: 30.0,
                cornerRadius: 8.0,
              ),
            ),
          ),
        ),
        
        // Header with back button
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    margin: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  if (widget.previousImagePath != null)
                    IconButton(
                      icon: Icon(
                        _showOverlay ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        if (mounted) {
                          setState(() {
                            _showOverlay = !_showOverlay;
                          });
                        }
                      },
                      tooltip: 'Show/Hide Overlay',
                    ),
                ],
              ),
            ),
          ),
        ),
        
        // Overlay transparency controls
        if (_showOverlay && widget.previousImagePath != null)
          Positioned(
            bottom: 150,
            left: 20,
            right: 20,
            child: Column(
              children: [
                const Text(
                  'Overlay Transparency',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 3,
                        color: Colors.black45,
                      ),
                    ],
                  ),
                ),
                Slider(
                  value: _overlayOpacity,
                  min: 0.1,
                  max: 0.9,
                  divisions: 8,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white54,
                  label: '${(_overlayOpacity * 100).round()}%',
                  onChanged: (value) {
                    if (mounted) {
                      setState(() {
                        _overlayOpacity = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        
        // Loading indicator when capturing
        if (_isCapturing)
          Positioned.fill(
            child: Container(
              color: Colors.black38,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        
        // Bottom camera controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 120,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Switch camera button (conditional)
                if (widget.showSwitchCameraButton)
                  CircleAvatar(
                    backgroundColor: Colors.white54,
                    radius: 25,
                    child: IconButton(
                      icon: const Icon(Icons.flip_camera_ios, color: Colors.black, size: 25),
                      onPressed: _switchCamera,
                    ),
                  ),
                
                if (widget.showSwitchCameraButton)
                  const SizedBox(width: 40),
                
                // Capture button
                GestureDetector(
                  onTap: _isCapturing ? null : _captureImage,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                    child: _isCapturing
                        ? const CircularProgressIndicator(
                            color: Colors.black,
                          )
                        : Container(
                            margin: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                  ),
                ),
                
                // Flashlight button
                const SizedBox(width: 40),
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.7),
                  radius: 25,
                  child: IconButton(
                    icon: Icon(
                      _flashlightOn ? Icons.flash_on : Icons.flash_off,
                      color: _flashlightOn ? Colors.amber : Colors.black,
                      size: 24,
                    ),
                    onPressed: _toggleFlashlight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Widget to show "AI still analyzing your food" screen
class AnalyzingFoodWidget extends StatelessWidget {
  const AnalyzingFoodWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              size: 80,
              color: Colors.black,
            ),
            SizedBox(height: 20),
            Text(
              'AI still analyzing your food',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget to show success screen
class AnalysisCompleteWidget extends StatelessWidget {
  final VoidCallback onDonePressed;
  
  const AnalysisCompleteWidget({
    Key? key,
    required this.onDonePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Great!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your food has been analyzed',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              child: TextButton(
                onPressed: onDonePressed,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 