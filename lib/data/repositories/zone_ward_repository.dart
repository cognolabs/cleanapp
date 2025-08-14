import 'dart:convert';
import 'package:cognoapp/core/error/exceptions.dart';
import 'package:cognoapp/config/constants.dart';
import 'package:cognoapp/core/utils/api_helper.dart';
import 'package:cognoapp/data/models/zone_ward_model.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ZoneWardRepository {
  final http.Client client;
  final ApiHelper apiHelper;

  ZoneWardRepository({
    required this.client,
    required this.apiHelper,
  });

  /// Fetches all available zones from the API
  Future<List<int>> getZones() async {
    try {
      print('ZoneWardRepository: Getting auth header');
      final authHeader = await apiHelper.getAuthHeader();
      print('ZoneWardRepository: Auth header obtained');
      
      final url = '${AppConstants.BASE_URL}/api/zone-ward/zones';
      print('ZoneWardRepository: Sending GET request to $url');
      
      final response = await client.get(
        Uri.parse(url),
        headers: authHeader,
      );

      print('ZoneWardRepository: Received response with status ${response.statusCode}');
      print('ZoneWardRepository: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> zonesJson = json.decode(response.body);
        print('ZoneWardRepository: Parsed JSON: $zonesJson');
        
        final zones = zonesJson.map((zone) => zone as int).toList();
        print('ZoneWardRepository: Returning zones: $zones');
        return zones;
      } else {
        print('ZoneWardRepository: Error status code: ${response.statusCode}');
        throw ServerException(message: 'Failed to fetch zones', statusCode: response.statusCode);
      }
    } catch (e) {
      print('ZoneWardRepository: Exception occurred: $e');
      throw ServerException(message: 'Failed to fetch zones: $e');
    }
  }

  /// Fetches all wards for a specific zone
  Future<List<WardModel>> getWardsByZone(int zoneId) async {
    try {
      print('ZoneWardRepository: Getting auth header for wards');
      final authHeader = await apiHelper.getAuthHeader();
      print('ZoneWardRepository: Auth header obtained for wards');
      
      final url = '${AppConstants.BASE_URL}/api/zone-ward/wards/$zoneId';
      print('ZoneWardRepository: Sending GET request to $url');
      
      final response = await client.get(
        Uri.parse(url),
        headers: authHeader,
      );

      print('ZoneWardRepository: Received wards response with status ${response.statusCode}');
      print('ZoneWardRepository: Wards response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> wardsJson = json.decode(response.body);
        print('ZoneWardRepository: Parsed wards JSON: $wardsJson');
        
        final wards = wardsJson.map((ward) => WardModel.fromJson(ward)).toList();
        print('ZoneWardRepository: Returning ${wards.length} wards for zone $zoneId');
        return wards;
      } else {
        print('ZoneWardRepository: Error status code for wards: ${response.statusCode}');
        throw ServerException(message: 'Failed to fetch wards', statusCode: response.statusCode);
      }
    } catch (e) {
      print('ZoneWardRepository: Exception occurred while fetching wards: $e');
      throw ServerException(message: 'Failed to fetch wards: $e');
    }
  }

  /// Fetches boundary coordinates for a specific ward
  Future<WardBoundaryModel> getWardBoundary(int wardId) async {
    try {
      print('ZoneWardRepository: Getting auth header for boundary');
      final authHeader = await apiHelper.getAuthHeader();
      print('ZoneWardRepository: Auth header obtained for boundary');
      
      final url = '${AppConstants.BASE_URL}/api/zone-ward/boundary/$wardId';
      print('ZoneWardRepository: Sending GET request to $url');
      
      final response = await client.get(
        Uri.parse(url),
        headers: authHeader,
      );

      print('ZoneWardRepository: Received boundary response with status ${response.statusCode}');
      print('ZoneWardRepository: Boundary response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> boundaryJson = json.decode(response.body);
        print('ZoneWardRepository: Parsed boundary JSON: $boundaryJson');
        
        // Check if coordinates exist
        if (boundaryJson['coordinates'] == null || 
            (boundaryJson['coordinates'] as List).isEmpty) {
          print('ZoneWardRepository: No coordinates found in response');
          throw ServerException(message: 'No boundary coordinates found for ward ID: $wardId');
        }
        
        final boundary = WardBoundaryModel.fromJson(boundaryJson);
        print('ZoneWardRepository: Returning boundary with ${boundary.coordinates.length} points');
        return boundary;
      } else {
        print('ZoneWardRepository: Error status code for boundary: ${response.statusCode}');
        throw ServerException(message: 'Failed to fetch ward boundary', statusCode: response.statusCode);
      }
    } catch (e) {
      print('ZoneWardRepository: Exception occurred while fetching boundary: $e');
      throw ServerException(message: 'Failed to fetch ward boundary: $e');
    }
  }
}
