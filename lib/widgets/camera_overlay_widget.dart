import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraOverlayWidget extends StatelessWidget {
  final String? previousImagePath;
  final double opacity;

  const CameraOverlayWidget({
    Key? key,
    required this.previousImagePath,
    this.opacity = 0.5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (previousImagePath == null || previousImagePath!.isEmpty) {
      return Container();
    }

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

class CameraWithOverlayScreen extends StatefulWidget {
  final String? previousImagePath;
  final Function(File) onImageCaptured;

  const CameraWithOverlayScreen({
    Key? key,
    required this.previousImagePath,
    required this.onImageCaptured,
  }) : super(key: key);

  @override
  State<CameraWithOverlayScreen> createState() => _CameraWithOverlayScreenState();
}

class _CameraWithOverlayScreenState extends State<CameraWithOverlayScreen> with WidgetsBindingObserver {
  double _overlayOpacity = 0.5;
  bool _showOverlay = true;
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  
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
    // Menangani perubahan lifecycle aplikasi
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
      // Dapatkan daftar kamera yang tersedia
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
  
  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isCapturing) {
      return;
    }
    
    try {
      setState(() {
        _isCapturing = true;
      });
      
      // Tangkap gambar
      final XFile imageFile = await _cameraController!.takePicture();
      
      if (mounted) {
        // Konversi XFile ke File
        final capturedFile = File(imageFile.path);
        
        // Kirim gambar yang ditangkap ke callback
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
      appBar: AppBar(
        title: const Text('Ambil Foto Makanan Tersisa'),
        actions: [
          IconButton(
            icon: Icon(_showOverlay ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              if (mounted) {
                setState(() {
                  _showOverlay = !_showOverlay;
                });
              }
            },
            tooltip: 'Tampilkan/Sembunyikan Overlay',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Tampilan kamera
          _isCameraInitialized
              ? SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: CameraPreview(_cameraController!),
                )
              : Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
          
          // Overlay gambar sebelumnya
          if (_showOverlay && widget.previousImagePath != null)
            CameraOverlayWidget(
              previousImagePath: widget.previousImagePath,
              opacity: _overlayOpacity,
            ),
            
          // Kontrol untuk overlay
          Positioned(
            bottom: 80,
            left: 20,
            right: 20,
            child: Column(
              children: [
                const Text(
                  'Transparansi Overlay',
                  style: TextStyle(color: Colors.white),
                ),
                Slider(
                  value: _overlayOpacity,
                  min: 0.1,
                  max: 0.9,
                  divisions: 8,
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
          
          // Indikator loading saat mengambil gambar
          if (_isCapturing)
            Positioned.fill(
              child: Container(
                color: Colors.black38,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          
          // Tombol ambil foto
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: _isCapturing ? null : _captureImage,
                child: Icon(_isCapturing ? Icons.hourglass_empty : Icons.camera),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 