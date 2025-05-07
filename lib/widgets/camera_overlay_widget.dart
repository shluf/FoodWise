import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CameraOverlayWidget extends StatelessWidget {
  final String? previousImagePath;
  final String? previousImageUrl;
  final double opacity;

  const CameraOverlayWidget({
    Key? key,
    this.previousImagePath,
    this.previousImageUrl,
    this.opacity = 0.5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Jika tidak ada path maupun URL, tidak tampilkan apa-apa
    if ((previousImagePath == null || previousImagePath!.isEmpty) && 
        (previousImageUrl == null || previousImageUrl!.isEmpty)) {
      return Container();
    }

    // Prioritaskan URL jika tersedia
    if (previousImageUrl != null && previousImageUrl!.isNotEmpty) {
      return Positioned.fill(
        child: Opacity(
          opacity: opacity,
          child: CachedNetworkImage(
            imageUrl: previousImageUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorWidget: (context, url, error) => const Center(
              child: Icon(Icons.error, color: Colors.red, size: 40),
            ),
          ),
        ),
      );
    }

    // Gunakan gambar lokal jika URL tidak tersedia
    return Positioned.fill(
      child: Opacity(
        opacity: opacity,
        child: Image.file(
          File(previousImagePath!),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// Widget untuk membuat sudut kotak scan
class CornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;

  CornerPainter({
    required this.color,
    this.strokeWidth = 4.0,
    this.cornerLength = 30.0,
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
    canvas.drawLine(
      Offset(0, cornerLength),
      const Offset(0, 0),
      paint,
    );
    canvas.drawLine(
      Offset(0, 0),
      Offset(cornerLength, 0),
      paint,
    );

    // Top right corner
    canvas.drawLine(
      Offset(width - cornerLength, 0),
      Offset(width, 0),
      paint,
    );
    canvas.drawLine(
      Offset(width, 0),
      Offset(width, cornerLength),
      paint,
    );

    // Bottom right corner
    canvas.drawLine(
      Offset(width, height - cornerLength),
      Offset(width, height),
      paint,
    );
    canvas.drawLine(
      Offset(width, height),
      Offset(width - cornerLength, height),
      paint,
    );

    // Bottom left corner
    canvas.drawLine(
      Offset(cornerLength, height),
      Offset(0, height),
      paint,
    );
    canvas.drawLine(
      Offset(0, height),
      Offset(0, height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(CornerPainter oldDelegate) => false;
}

class CameraWithOverlayScreen extends StatefulWidget {
  final String? previousImagePath;
  final String? previousImageUrl;
  final Function(File) onImageCaptured;

  const CameraWithOverlayScreen({
    Key? key,
    this.previousImagePath,
    this.previousImageUrl,
    required this.onImageCaptured,
  }) : super(key: key);

  @override
  State<CameraWithOverlayScreen> createState() => _CameraWithOverlayScreenState();
}

class _CameraWithOverlayScreenState extends State<CameraWithOverlayScreen> with WidgetsBindingObserver {
  double _overlayOpacity = 0.5;
  bool _showOverlay = true;
  bool _flashlightOn = false;
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
    // Handle application lifecycle state changes
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
      // Get available cameras
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        return;
      }
      
      _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first
      );
      
      _cameraController = CameraController(
        _cameras![_selectedCameraIndex],
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

  void _switchCamera() async {
    if (_cameras == null || _cameras!.isEmpty || _cameras!.length <= 1) return;
    
    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
      _isCameraInitialized = false;
    });
    
    // Dispose current controller
    await _cameraController?.dispose();
    
    // Reinitialize with new camera
    _initializeCamera();
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
  
  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isCapturing) {
      return;
    }
    
    try {
      setState(() {
        _isCapturing = true;
      });
      
      // Capture image
      final XFile imageFile = await _cameraController!.takePicture();
      
      if (mounted) {
        // Convert XFile to File
        final capturedFile = File(imageFile.path);
        
        // Send captured image to callback
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Camera view
          _isCameraInitialized
              ? SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: CameraPreview(_cameraController!),
                )
              : Container(
                  color: Colors.black,
                  child: const Center(
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
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 24),
                        CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
          
          // Previous image overlay
          if (_showOverlay)
            CameraOverlayWidget(
              previousImagePath: widget.previousImagePath,
              previousImageUrl: widget.previousImageUrl,
              opacity: _overlayOpacity,
            ),
            
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
                      margin: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: const EdgeInsets.all(8.0),
                      ),
                    ),
                    if (widget.previousImagePath != null || widget.previousImageUrl != null)
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
          if (_showOverlay && (widget.previousImagePath != null || widget.previousImageUrl != null))
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
          
          // Bottom camera button area
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
                  // Switch camera button
                  CircleAvatar(
                    backgroundColor: Colors.white54,
                    radius: 25,
                    child: IconButton(
                      icon: const Icon(Icons.flip_camera_ios, color: Colors.black, size: 25),
                      onPressed: _switchCamera,
                    ),
                  ),
                  
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
      ),
    );
  }
} 