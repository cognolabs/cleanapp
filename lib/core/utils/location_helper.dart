import 'package:geolocator/geolocator.dart';
import 'package:cognoapp/core/error/exceptions.dart';
import 'package:cognoapp/config/constants.dart';
import 'dart:math';
import 'package:latlong2/latlong.dart';

class LocationHelper {
  // Request location permission and check if it's enabled
  static Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException(
        message: 'Location services are disabled. Please enable them to use the app.',
      );
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw PermissionException(
          message: AppConstants.LOCATION_PERMISSION_DENIED,
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw PermissionException(
        message: 'Location permissions are permanently denied. Please enable them in app settings.',
      );
    }

    return true;
  }

  // Get current position with high accuracy
  static Future<Position> getCurrentPosition() async {
    await handleLocationPermission();

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      throw LocationException(
        message: 'Failed to get current location: ${e.toString()}',
      );
    }
  }

  // Calculate distance between two coordinates in kilometers
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    // Using Haversine formula
    var p = 0.017453292519943295; // Math.PI / 180
    var c = cos;
    var a = 0.5 -
        c((endLatitude - startLatitude) * p) / 2 +
        c(startLatitude * p) *
            c(endLatitude * p) *
            (1 - c((endLongitude - startLongitude) * p)) /
            2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  // Check if a location is within the allowed distance for issue resolution
  static bool isWithinAllowedDistance(
    double issueLatitude,
    double issueLongitude,
    double currentLatitude,
    double currentLongitude,
  ) {
    final distance = calculateDistance(
      issueLatitude,
      issueLongitude,
      currentLatitude,
      currentLongitude,
    );
    
    return distance <= AppConstants.MAX_DISTANCE_KM;
  }
  
  /// Get a human-readable distance string
  static String getReadableDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).toInt()} m';
    } else if (distanceInKm < 10) {
      return '${distanceInKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceInKm.toInt()} km';
    }
  }
  
  /// Get the center of multiple coordinates
  static LatLng getCenterOfCoordinates(List<LatLng> coordinates) {
    if (coordinates.isEmpty) {
      // Default center if no coordinates
      return const LatLng(20.5937, 78.9629); // Default to India
    }
    
    if (coordinates.length == 1) {
      return coordinates[0];
    }
    
    double x = 0;
    double y = 0;
    double z = 0;
    
    for (var point in coordinates) {
      // Convert to radians
      final lat = point.latitude * pi / 180;
      final lon = point.longitude * pi / 180;
      
      // Convert to Cartesian coordinates
      x += cos(lat) * cos(lon);
      y += cos(lat) * sin(lon);
      z += sin(lat);
    }
    
    // Calculate average
    x /= coordinates.length;
    y /= coordinates.length;
    z /= coordinates.length;
    
    // Convert back to lat/lon
    final lon = atan2(y, x);
    final hyp = sqrt(x * x + y * y);
    final lat = atan2(z, hyp);
    
    // Convert to degrees
    return LatLng(
      lat * 180 / pi,
      lon * 180 / pi
    );
  }
}
