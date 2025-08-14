import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:cognoapp/core/widgets/custom_snackbar.dart';
import 'package:cognoapp/core/utils/location_helper.dart';
import 'package:cognoapp/core/utils/permission_helper.dart';
import 'package:cognoapp/presentation/authentication/auth_provider.dart';
import 'package:cognoapp/presentation/camera/camera_provider.dart';
import 'package:cognoapp/config/theme.dart';
import 'package:cognoapp/presentation/common_widgets/app_bar.dart';
import 'dart:async';

class CameraDetectionScreen extends StatefulWidget {
  const CameraDetectionScreen({Key? key}) : super(key: key);

  @override
  _CameraDetectionScreenState createState() => _CameraDetectionScreenState();
}

class _CameraDetectionScreenState extends State<CameraDetectionScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription> cameras = [];
  bool _isInitialized = false;
  bool _isCapturing = false;
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  // Continuous capture variables
  bool _isContinuousCapture = false;
  Timer? _captureTimer;
  int _captureInterval = 5; // seconds
  int _captureCount = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializeCamera();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
    _cameraController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      // Check camera permission
      final hasPermission = await PermissionHelper.requestCameraPermission();
      if (!hasPermission) {
        if (mounted) {
          CustomSnackbar.showError(
            context: context,
            message: 'Camera permission is required to capture images',
          );
        }
        return;
      }

      // Get available cameras
      cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          CustomSnackbar.showError(
            context: context,
            message: 'No camera found on this device',
          );
        }
        return;
      }

      // Initialize camera controller with back camera
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(
          context: context,
          message: 'Failed to initialize camera: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final position = await LocationHelper.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      if (mounted) {
        CustomSnackbar.showError(
          context: context,
          message: 'Failed to get current location: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _captureImage() async {
    if (!_isInitialized || _cameraController == null || _isCapturing) {
      return;
    }

    if (_currentPosition == null) {
      CustomSnackbar.showError(
        context: context,
        message: 'GPS location is required. Please wait for location to be obtained.',
      );
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    // Animate button press
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    try {
      // Capture image
      final XFile image = await _cameraController!.takePicture();

      // Process image with camera provider
      final cameraProvider = Provider.of<CameraProvider>(context, listen: false);
      
      await cameraProvider.processImage(
        imagePath: image.path,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );

      if (mounted) {
        // Show success message
        CustomSnackbar.show(
          context: context,
          message: 'Image captured and sent for processing!',
        );

        // Navigate to results screen
        Navigator.pushNamed(
          context,
          '/camera/results',
          arguments: cameraProvider.lastProcessingResult,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(
          context: context,
          message: 'Failed to capture image: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  // Continuous capture methods
  void _startContinuousCapture() {
    if (_currentPosition == null) {
      CustomSnackbar.showError(
        context: context,
        message: 'GPS location is required. Please wait for location to be obtained.',
      );
      return;
    }

    setState(() {
      _isContinuousCapture = true;
      _captureCount = 0;
    });

    _captureTimer = Timer.periodic(Duration(seconds: _captureInterval), (timer) {
      if (mounted && _isContinuousCapture) {
        _captureImageContinuous();
      }
    });

    CustomSnackbar.show(
      context: context,
      message: 'Started continuous capture every ${_captureInterval}s',
    );
  }

  void _stopContinuousCapture() {
    setState(() {
      _isContinuousCapture = false;
    });

    _captureTimer?.cancel();
    _captureTimer = null;

    CustomSnackbar.show(
      context: context,
      message: 'Stopped continuous capture. Total images: $_captureCount',
    );

    // Navigate to results screen if images were captured
    if (_captureCount > 0) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pushNamed(context, '/camera/results');
        }
      });
    }
  }

  Future<void> _captureImageContinuous() async {
    if (!_isInitialized || _cameraController == null || _isCapturing) {
      return;
    }

    if (_currentPosition == null) {
      _stopContinuousCapture();
      CustomSnackbar.showError(
        context: context,
        message: 'GPS location lost. Stopping continuous capture.',
      );
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      // Capture image
      final XFile image = await _cameraController!.takePicture();

      // Process image with camera provider
      final cameraProvider = Provider.of<CameraProvider>(context, listen: false);
      
      await cameraProvider.processImage(
        imagePath: image.path,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );

      setState(() {
        _captureCount++;
      });

      if (mounted) {
        // Show brief success indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image $_captureCount captured'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(
          context: context,
          message: 'Failed to capture image: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (!_isInitialized || cameras.length < 2) return;

    final currentCameraIndex = cameras.indexOf(_cameraController!.description);
    final newCameraIndex = (currentCameraIndex + 1) % cameras.length;

    try {
      await _cameraController!.dispose();
      _cameraController = CameraController(
        cameras[newCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      setState(() {});
    } catch (e) {
      CustomSnackbar.showError(
        context: context,
        message: 'Failed to switch camera: ${e.toString()}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final cameraProvider = Provider.of<CameraProvider>(context);

    // Camera is now available to all authenticated users

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: ModernAppBar(
        title: 'Detection Camera',
        showBackButton: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (cameras.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
              onPressed: _switchCamera,
            ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          if (_isInitialized && _cameraController != null)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),

          // Loading overlay
          if (_isCapturing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Processing image...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Location status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isLoadingLocation
                          ? Colors.orange.withOpacity(0.2)
                          : _currentPosition != null
                              ? Colors.green.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isLoadingLocation
                            ? Colors.orange
                            : _currentPosition != null
                                ? Colors.green
                                : Colors.red,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isLoadingLocation
                              ? Icons.location_searching
                              : _currentPosition != null
                                  ? Icons.location_on
                                  : Icons.location_off,
                          size: 16,
                          color: _isLoadingLocation
                              ? Colors.orange
                              : _currentPosition != null
                                  ? Colors.green
                                  : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isLoadingLocation
                              ? 'Getting location...'
                              : _currentPosition != null
                                  ? 'Location: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}'
                                  : 'Location unavailable',
                          style: TextStyle(
                            color: _isLoadingLocation
                                ? Colors.orange
                                : _currentPosition != null
                                    ? Colors.green
                                    : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Continuous capture status
                  if (_isContinuousCapture) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fiber_smart_record,
                            color: Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Capturing: $_captureCount images',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Capture interval selector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Interval: ${_captureInterval}s',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            if (!_isContinuousCapture && _captureInterval > 2) {
                              setState(() {
                                _captureInterval--;
                              });
                            }
                          },
                          child: Icon(
                            Icons.remove_circle_outline,
                            color: _isContinuousCapture ? Colors.grey : Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            if (!_isContinuousCapture && _captureInterval < 30) {
                              setState(() {
                                _captureInterval++;
                              });
                            }
                          },
                          child: Icon(
                            Icons.add_circle_outline,
                            color: _isContinuousCapture ? Colors.grey : Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Control buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Refresh location button
                      GestureDetector(
                        onTap: _getCurrentLocation,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),

                      // Start/Stop continuous capture button
                      AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: GestureDetector(
                              onTap: _isContinuousCapture ? _stopContinuousCapture : _startContinuousCapture,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: _isContinuousCapture
                                      ? Colors.red
                                      : (_currentPosition != null
                                          ? Colors.green
                                          : Colors.grey),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isContinuousCapture ? Icons.stop : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Single capture button
                      GestureDetector(
                        onTap: _isContinuousCapture ? null : _captureImage,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: _isContinuousCapture 
                                ? Colors.grey
                                : Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: _isContinuousCapture ? Colors.grey[400] : Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (cameraProvider.isProcessing) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(
                      color: AppTheme.primaryColor,
                      backgroundColor: Colors.white24,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Top info overlay
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manager Detection Mode',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Capture images to detect issues using all 5 AI models:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _ModelChip(label: 'Garbage'),
                      _ModelChip(label: 'Pothole'),
                      _ModelChip(label: 'Stray Animal'),
                      _ModelChip(label: 'Hoarding'),
                      _ModelChip(label: 'Encroachment'),
                    ],
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

class _ModelChip extends StatelessWidget {
  final String label;

  const _ModelChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}