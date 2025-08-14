import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart';

class ZoneWardInfo {
  final String id;
  final String name;
  final String zoneId;
  final List<List<double>> coordinates;

  ZoneWardInfo({
    required this.id,
    required this.name,
    required this.zoneId,
    required this.coordinates,
  });
}

class KmlService {
  static final KmlService _instance = KmlService._internal();
  List<ZoneWardInfo> _zoneWards = [];
  List<String> _zones = [];
  Map<String, List<String>> _wardsByZone = {};
  bool _isInitialized = false;

  factory KmlService() {
    return _instance;
  }

  KmlService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load KML file
      final String kmlContent = await rootBundle.loadString('assets/Final_New_Parisiman2022_Ward_Boundary_PMC_27-05-2024.kml');
      final document = XmlDocument.parse(kmlContent);

      // Find all placemarks
      final placemarks = document.findAllElements('Placemark');
      
      // Process each placemark
      for (var placemark in placemarks) {
        final nameElement = placemark.findElements('n').first;
        final name = nameElement.text;
        
        final descriptionElement = placemark.findElements('description').firstOrNull;
        String description = descriptionElement?.text ?? '';
        
        String zoneId = '';
        String wardId = '';
        
        // Extract ZoneID and Ward Number from description
        final zoneRegex = RegExp(r'ZoneID\s+(\d+)');
        final wardRegex = RegExp(r'Fin_Wrd_No\s+(\d+)');
        
        final zoneMatch = zoneRegex.firstMatch(description);
        final wardMatch = wardRegex.firstMatch(description);
        
        if (zoneMatch != null) {
          zoneId = zoneMatch.group(1) ?? '';
        }
        
        if (wardMatch != null) {
          wardId = wardMatch.group(1) ?? '';
        }
        
        if (zoneId.isNotEmpty && wardId.isNotEmpty) {
          // Extract coordinates
          final coordinatesElement = placemark.findAllElements('coordinates').firstOrNull;
          if (coordinatesElement != null) {
            final coordinatesText = coordinatesElement.text.trim();
            List<List<double>> coordinates = [];
            
            // Parse coordinates
            final points = coordinatesText.split(' ');
            for (var point in points) {
              if (point.trim().isNotEmpty) {
                final values = point.split(',');
                if (values.length >= 2) {
                  try {
                    final lng = double.parse(values[0]);
                    final lat = double.parse(values[1]);
                    coordinates.add([lat, lng]);
                  } catch (e) {
                    print('Error parsing coordinate: $point');
                  }
                }
              }
            }
            
            // Add to list
            if (coordinates.isNotEmpty) {
              _zoneWards.add(ZoneWardInfo(
                id: wardId,
                name: name,
                zoneId: zoneId,
                coordinates: coordinates,
              ));
              
              // Track unique zones
              if (!_zones.contains(zoneId)) {
                _zones.add(zoneId);
                _wardsByZone[zoneId] = [];
              }
              
              // Track wards by zone
              if (!_wardsByZone[zoneId]!.contains(name)) {
                _wardsByZone[zoneId]!.add(name);
              }
            }
          }
        }
      }
      
      // Sort zones
      _zones.sort();
      
      // Sort wards in each zone
      _wardsByZone.forEach((key, value) {
        value.sort();
      });
      
      _isInitialized = true;
    } catch (e) {
      print('Error initializing KML service: $e');
      rethrow;
    }
  }

  List<String> getZones() {
    return _zones;
  }

  List<String> getWardsByZone(String zoneId) {
    return _wardsByZone[zoneId] ?? [];
  }

  ZoneWardInfo? getWardInfo(String zoneName, String wardName) {
    return _zoneWards.firstWhere(
      (ward) => ward.zoneId == zoneName && ward.name == wardName,
      orElse: () => ZoneWardInfo(id: '', name: '', zoneId: '', coordinates: []),
    );
  }
}
