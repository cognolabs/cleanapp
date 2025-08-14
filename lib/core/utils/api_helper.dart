import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cognoapp/core/error/exceptions.dart';

/// Helper class to interact with API endpoints
class ApiHelper {
  final http.Client httpClient;
  final FlutterSecureStorage secureStorage;
  
  ApiHelper({
    required this.httpClient,
    required this.secureStorage,
  });
  
  /// Get authentication header with access token
  Future<Map<String, String>> getAuthHeader() async {
    final token = await secureStorage.read(key: 'token');
    
    if (token == null) {
      throw AuthException(message: 'Authentication token not found');
    }
    
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
  
  /// Handle HTTP response and throw appropriate exceptions
  void handleResponse(http.Response response) {
    if (response.statusCode >= 400) {
      Map<String, dynamic> errorData = {};
      
      try {
        errorData = json.decode(response.body);
      } catch (_) {
        // If body is not JSON, use empty error data
      }
      
      final errorMessage = errorData['detail'] ?? 
                           errorData['message'] ?? 
                           'Server error: ${response.statusCode}';
      
      switch (response.statusCode) {
        case 401:
          throw AuthException(message: errorMessage);
        case 403:
          throw PermissionException(message: errorMessage);
        case 404:
          throw NotFoundException(message: errorMessage);
        default:
          throw ServerException(message: errorMessage);
      }
    }
  }
}
