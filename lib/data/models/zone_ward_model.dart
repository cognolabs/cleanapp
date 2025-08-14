import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

class WardModel {
  final int wardId;
  final String name;

  WardModel({
    required this.wardId,
    required this.name,
  });

  factory WardModel.fromJson(Map<String, dynamic> json) {
    return WardModel(
      wardId: json['ward_id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ward_id': wardId,
      'name': name,
    };
  }
}

class WardBoundaryModel {
  final int wardId;
  final String name;
  final List<LatLng> coordinates;

  WardBoundaryModel({
    required this.wardId,
    required this.name,
    required this.coordinates,
  });

  factory WardBoundaryModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> coordinatesList = json['coordinates'];
    
    return WardBoundaryModel(
      wardId: json['ward_id'],
      name: json['name'],
      coordinates: coordinatesList.map((coord) {
        return LatLng(coord[1], coord[0]); // Convert [lng, lat] to LatLng(lat, lng)
      }).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ward_id': wardId,
      'name': name,
      'coordinates': coordinates.map((coord) => [coord.longitude, coord.latitude]).toList(),
    };
  }

  // Helper method to create a polygon from the boundary coordinates
  Polygon toPolygon({Color fillColor = const Color(0x294CAF50), Color strokeColor = const Color(0xFF4CAF50)}) {
    return Polygon(
      polygonId: PolygonId('ward_$wardId'),
      points: coordinates,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: 2,
    );
  }
}
