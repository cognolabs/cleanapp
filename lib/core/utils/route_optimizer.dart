import 'package:cognoapp/data/models/detection_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';

class RouteOptimizer {
  /// Calculates the distance between two points in kilometers using the Haversine formula
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
                     cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) * 
                     sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// Converts degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
  
  /// Find the nearest issue to the given point
  static DetectionModel? _findNearestIssue(
    Position currentPosition, 
    List<DetectionModel> unvisitedIssues
  ) {
    if (unvisitedIssues.isEmpty) return null;
    
    double minDistance = double.infinity;
    DetectionModel? nearestIssue;
    
    for (var issue in unvisitedIssues) {
      final distance = _calculateDistance(
        currentPosition.latitude, 
        currentPosition.longitude,
        issue.latitude, 
        issue.longitude
      );
      
      if (distance < minDistance) {
        minDistance = distance;
        nearestIssue = issue;
      }
    }
    
    return nearestIssue;
  }
  
  /// Optimize route through all issues in the ward/zone using a nearest neighbor algorithm
  /// Returns an ordered list of issues for the optimized route starting from the current position
  static List<DetectionModel> optimizeRoute(
    Position currentPosition, 
    List<DetectionModel> issues, 
    {
      String? statusFilter,
      int? wardId, 
      int? zoneId
    }
  ) {
    // Filter issues by status, ward, and zone if specified
    List<DetectionModel> filteredIssues = issues.where((issue) {
      // Filter by status if provided
      if (statusFilter != null && statusFilter.toLowerCase() != 'all') {
        if (issue.status.toLowerCase() != statusFilter.toLowerCase()) {
          return false;
        }
      }
      
      // Filter by ward if provided
      if (wardId != null) {
        bool wardMatches = false;
        if (issue.wardName != null) {
          // Try to extract ward number from various formats
          // - "Ward X"
          // - "Ward Name (Ward X)"
          // - "Ward X - Name"
          // - "X" (just the number)
          
          // First try to find explicit ward numbers
          final wardRegex = RegExp(r'Ward\s*(?:No\.?|Number)?:?\s*(\d+)|Ward\s*(\d+)|\(Ward\s*(\d+)\)');
          final match = wardRegex.firstMatch(issue.wardName!);
          
          if (match != null) {
            // Get the first non-null capturing group
            String? matchNumber;
            for (int i = 1; i <= match.groupCount; i++) {
              if (match.group(i) != null) {
                matchNumber = match.group(i);
                break;
              }
            }
            
            final extractedWardId = int.tryParse(matchNumber ?? '');
            wardMatches = extractedWardId == wardId;
          } else {
            // If no explicit ward number format found, try parsing the entire string
            final directWardId = int.tryParse(issue.wardName!.trim());
            wardMatches = directWardId == wardId;
          }
        }
        
        if (!wardMatches) return false;
      }
      
      // Filter by zone if provided
      if (zoneId != null) {
        bool zoneMatches = false;
        if (issue.zone != null) {
          // Try to extract zone number from various formats
          // - "Zone X"
          // - "Zone X - Name"
          // - "X" (just the number)
          
          // First try to find explicit zone numbers with various formats
          final zoneRegex = RegExp(r'Zone\s*(?:No\.?|Number)?:?\s*(\d+)|Zone\s*(\d+)');
          final match = zoneRegex.firstMatch(issue.zone!);
          
          if (match != null) {
            // Get the first non-null capturing group
            String? matchNumber;
            for (int i = 1; i <= match.groupCount; i++) {
              if (match.group(i) != null) {
                matchNumber = match.group(i);
                break;
              }
            }
            
            final extractedZoneId = int.tryParse(matchNumber ?? '');
            zoneMatches = extractedZoneId == zoneId;
          } else {
            // If no explicit zone number format found, try parsing the entire string
            final directZoneId = int.tryParse(issue.zone!.trim());
            zoneMatches = directZoneId == zoneId;
          }
        }
        
        if (!zoneMatches) return false;
      }
      
      return true;
    }).toList();
    
    // If no issues match the criteria, return empty list
    if (filteredIssues.isEmpty) return [];
    
    // Create a copy to track unvisited issues
    List<DetectionModel> unvisitedIssues = List.from(filteredIssues);
    
    // Result list with ordered issues
    List<DetectionModel> optimizedRoute = [];
    
    // Start with the current position and find the nearest issue
    Position currentPoint = currentPosition;
    
    // Continue until all issues are visited
    while (unvisitedIssues.isNotEmpty) {
      // Find the nearest unvisited issue
      final nearestIssue = _findNearestIssue(currentPoint, unvisitedIssues);
      
      if (nearestIssue != null) {
        // Add to the optimized route
        optimizedRoute.add(nearestIssue);
        
        // Remove from unvisited issues
        unvisitedIssues.removeWhere((issue) => issue.id == nearestIssue.id);
        
        // Update current position to this issue
        currentPoint = Position(
          latitude: nearestIssue.latitude,
          longitude: nearestIssue.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
    }
    
    return optimizedRoute;
  }
  
  /// Calculate total distance of a route in kilometers
  static double calculateTotalRouteDistance(
    Position startPosition,
    List<DetectionModel> route
  ) {
    if (route.isEmpty) return 0;
    
    double totalDistance = 0;
    
    // Distance from start position to first issue
    totalDistance += _calculateDistance(
      startPosition.latitude,
      startPosition.longitude,
      route[0].latitude,
      route[0].longitude
    );
    
    // Distance between consecutive issues
    for (int i = 0; i < route.length - 1; i++) {
      totalDistance += _calculateDistance(
        route[i].latitude,
        route[i].longitude,
        route[i + 1].latitude,
        route[i + 1].longitude
      );
    }
    
    return totalDistance;
  }
  
  /// Generate a Google Maps URL with waypoints for the optimized route
  static String generateGoogleMapsUrl(
    Position startPosition,
    List<DetectionModel> route
  ) {
    if (route.isEmpty) return '';
    
    // Start with the current location
    final start = '${startPosition.latitude},${startPosition.longitude}';
    
    // End with the last issue in the route
    final end = '${route.last.latitude},${route.last.longitude}';
    
    // Handle route with too many waypoints by breaking it into segments if needed
    if (route.length <= 10) {
      // Simple case: few enough waypoints for a single Google Maps URL
      return _generateSingleMapUrl(start, end, route);
    } else {
      // Complex case: too many waypoints, need to create a URL for the entire route
      // Google Maps supports max 10 waypoints in the URL (including start and end)
      // We'll select strategic waypoints along the route
      return _generateOptimizedMapUrl(start, end, route);
    }
  }
  
  /// Generate a Google Maps URL for routes with 10 or fewer total points
  static String _generateSingleMapUrl(String start, String end, List<DetectionModel> route) {
    final List<String> waypoints = [];
    
    // Add all waypoints (except start and end)
    for (int i = 0; i < route.length - 1; i++) {
      final waypoint = '${route[i].latitude},${route[i].longitude}';
      waypoints.add(waypoint);
    }
    
    // Construct the URL
    final waypointsParam = waypoints.isNotEmpty ? '&waypoints=${waypoints.join('|')}' : '';
    
    return 'https://www.google.com/maps/dir/?api=1&origin=$start&destination=$end$waypointsParam&travelmode=driving';
  }
  
  /// Generate an optimized Google Maps URL for routes with more than 10 total points
  static String _generateOptimizedMapUrl(String start, String end, List<DetectionModel> route) {
    final List<String> waypoints = [];
    
    // Select up to 8 strategic waypoints (plus start and end = 10 total)
    // The max waypoints supported in a Google Maps URL
    final waypointCount = min(8, route.length - 1);
    
    if (route.length > 2) {
      // If many waypoints, distribute them evenly along the route
      final step = (route.length - 1) / waypointCount;
      
      for (int i = 0; i < waypointCount; i++) {
        final index = (i * step).round();
        final limitedIndex = min(index, route.length - 2);
        final waypoint = '${route[limitedIndex].latitude},${route[limitedIndex].longitude}';
        waypoints.add(waypoint);
      }
    }
    
    // Construct the URL
    final waypointsParam = waypoints.isNotEmpty ? '&waypoints=${waypoints.join('|')}' : '';
    
    return 'https://www.google.com/maps/dir/?api=1&origin=$start&destination=$end$waypointsParam&travelmode=driving';
  }
}
