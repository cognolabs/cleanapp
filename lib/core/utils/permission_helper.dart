import 'package:permission_handler/permission_handler.dart';
import 'package:cognoapp/core/error/exceptions.dart';
import 'package:cognoapp/config/constants.dart';

class PermissionHelper {
  // Request camera permission
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    
    if (status.isPermanentlyDenied) {
      throw PermissionException(
        message: 'Camera permission is permanently denied. Please enable it in app settings.',
      );
    }
    
    if (status.isDenied) {
      throw PermissionException(
        message: AppConstants.CAMERA_PERMISSION_DENIED,
      );
    }
    
    return status.isGranted;
  }

  // Check camera permission status
  static Future<bool> hasCameraPermission() async {
    return await Permission.camera.isGranted;
  }

  // Request location permission
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    
    if (status.isPermanentlyDenied) {
      throw PermissionException(
        message: 'Location permission is permanently denied. Please enable it in app settings.',
      );
    }
    
    if (status.isDenied) {
      throw PermissionException(
        message: AppConstants.LOCATION_PERMISSION_DENIED,
      );
    }
    
    return status.isGranted;
  }

  // Check location permission status
  static Future<bool> hasLocationPermission() async {
    return await Permission.location.isGranted;
  }

  // Open app settings
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
