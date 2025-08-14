import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:cognoapp/core/widgets/custom_snackbar.dart';
import 'package:cognoapp/core/widgets/primary_button.dart';
import 'package:cognoapp/core/utils/location_helper.dart';
import 'package:cognoapp/core/utils/permission_helper.dart';
import 'package:cognoapp/presentation/issue_management/detection_provider.dart';
import 'package:cognoapp/config/theme.dart';
import 'package:cognoapp/data/models/detection_model.dart';
import 'dart:io';

class IssueResolutionScreen extends StatefulWidget {
  final int issueId;

  const IssueResolutionScreen({Key? key, required this.issueId}) : super(key: key);

  @override
  _IssueResolutionScreenState createState() => _IssueResolutionScreenState();
}

class _IssueResolutionScreenState extends State<IssueResolutionScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isLoading = true;
  DetectionModel? _issue;
  File? _capturedImage;
  Position? _currentPosition;
  String _selectedStatus = 'closed';
  bool _isSubmitting = false;
  bool _isWithinRange = false;

  @override
  void initState() {
    super.initState();
    _loadIssueAndInitCamera();
  }

  Future<void> _loadIssueAndInitCamera() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load issue details
      final detectionProvider = Provider.of<DetectionProvider>(context, listen: false);
      final issue = await detectionProvider.fetchIssueById(widget.issueId);
      
      setState(() {
        _issue = issue;
      });

      // Get current location
      await _getCurrentLocation();
      
      // Initialize camera
      await _initializeCamera();
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(
          context: context,
          message: 'Error: ${e.toString()}',
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Get current position
      final position = await LocationHelper.getCurrentPosition();
          
      setState(() {
        _currentPosition = position;
      });
      
      // Check if within allowed distance
      if (_issue != null && _currentPosition != null) {
        // Check if within allowed distance
        final isWithin = LocationHelper.isWithinAllowedDistance(
                _issue!.latitude,
                _issue!.longitude,
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              );
        
        setState(() {
          _isWithinRange = isWithin;
        });
        
        if (!isWithin && mounted) {
          CustomSnackbar.showError(
            context: context,
            message: 'You are not within 500m of the issue location. You must be closer to resolve this issue.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(
          context: context,
          message: 'Failed to get current location: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permission
      await PermissionHelper.requestCameraPermission();
      
      // Get available cameras
      _cameras = await availableCameras();
      
      if (_cameras!.isEmpty) {
        throw Exception('No cameras available');
      }
      
      // Initialize camera controller with the first camera
      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      // Initialize camera
      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
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

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      CustomSnackbar.showError(
        context: context,
        message: 'Camera is not initialized',
      );
      return;
    }

    try {
      // Take picture
      final XFile photo = await _cameraController!.takePicture();
      
      // Update state with captured image
      setState(() {
        _capturedImage = File(photo.path);
      });
    } catch (e) {
      CustomSnackbar.showError(
        context: context,
        message: 'Failed to take picture: ${e.toString()}',
      );
    }
  }

  Future<void> _submitResolution() async {
    if (_capturedImage == null) {
      CustomSnackbar.showError(
        context: context,
        message: 'Please take a picture first',
      );
      return;
    }

    if (_currentPosition == null) {
      CustomSnackbar.showError(
        context: context,
        message: 'Location is not available',
      );
      return;
    }

    if (!_isWithinRange) {
      CustomSnackbar.showError(
        context: context,
        message: 'You are not within range of the issue location',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final detectionProvider = Provider.of<DetectionProvider>(context, listen: false);
      
      final success = await detectionProvider.resolveIssue(
        widget.issueId,
        _capturedImage!,
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _selectedStatus,
      );
      
      if (success && mounted) {
        CustomSnackbar.showSuccess(
          context: context,
          message: 'Issue resolved successfully',
        );
        
        // Go back to details screen with refresh flag
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(
          context: context,
          message: 'Failed to resolve issue: ${e.toString()}',
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // Wrapper function for onPressed callback
  void _handleTakePicture() {
    if (_isWithinRange) {
      _takePicture();
    }
  }

  // Wrapper function for submit onPressed callback
  void _handleSubmitResolution() {
    if (_isWithinRange) {
      _submitResolution();
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolve Issue'),
      ),
      body: Consumer<DetectionProvider>(
        builder: (context, detectionProvider, _) {
          return _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _issue == null
                ? const Center(child: Text('Issue not found'))
                : Column(
                  children: [
                    // Issue info header
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Issue #${_issue!.id}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _issue!.className,
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(_issue!.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _issue!.status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Location status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: _isWithinRange ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      child: Row(
                        children: [
                          Icon(
                            _isWithinRange ? Icons.check_circle : Icons.error,
                            color: _isWithinRange ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
_isWithinRange
                                    ? 'You are within range of the issue location'
                                    : 'You must be within 500m of the issue location to resolve it',
                              style: TextStyle(
                                fontSize: 13,
                                color: _isWithinRange ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                          if (!_isWithinRange)
                            TextButton(
                              onPressed: _getCurrentLocation,
                              child: const Text('Refresh'),
                            ),
                        ],
                      ),
                    ),
                    
                    // Camera preview or captured image
                    Expanded(
                      child: _capturedImage != null
                          ? Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.black87,
                              ),
                              child: Image.file(
                                _capturedImage!,
                                fit: BoxFit.contain,
                              ),
                            )
                          : _isCameraInitialized
                              ? CameraPreview(_cameraController!)
                              : const Center(
                                  child: Text('Camera initializing...'),
                                ),
                    ),
                    
                    // Controls
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_capturedImage == null) ...[
                            // Capture button
                            PrimaryButton(
                              text: 'Capture Photo',
                              icon: Icons.camera_alt,
                              onPressed: _isWithinRange ? _handleTakePicture : null,
                            ),
                          ] else ...[
                            // Status selection
                            const Text(
                              'Select New Status:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatusOption('closed', 'Closed'),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildStatusOption('investigating', 'Investigating'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Action buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Retake'),
                                    onPressed: () {
                                      setState(() {
                                        _capturedImage = null;
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: PrimaryButton(
                                    text: 'Submit',
                                    icon: Icons.check_circle,
                                    isLoading: _isSubmitting,
                                    onPressed: _isWithinRange ? _handleSubmitResolution : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildStatusOption(String value, String label) {
    final isSelected = _selectedStatus == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _selectedStatus,
              onChanged: (newValue) {
                setState(() {
                  _selectedStatus = newValue!;
                });
              },
              activeColor: AppTheme.primaryColor,
            ),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return AppTheme.openStatusColor;
      case 'investigating':
        return AppTheme.investigatingStatusColor;
      case 'closed':
        return AppTheme.closedStatusColor;
      default:
        return Colors.blue;
    }
  }
}
