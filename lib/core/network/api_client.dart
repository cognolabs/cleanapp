import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:cognoapp/core/error/exceptions.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:cognoapp/config/constants.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class ApiClient {
  final http.Client httpClient;
  final Dio dio;
  final FlutterSecureStorage secureStorage;
  final Logger logger;

  ApiClient({
    required this.httpClient,
    required this.dio,
    required this.secureStorage,
    required this.logger,
  }) {
    // Configure Dio with increased timeout
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token to all requests except login
          if (!options.path.contains('login')) {
            final token = await secureStorage.read(key: AppConstants.TOKEN_KEY);
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          logger.e('Dio error: ${e.message}', error: e, stackTrace: e.stackTrace);
          return handler.next(e);
        },
      ),
    );
  }

  // Login with username/password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final formData = {
        'username': email,
        'password': password,
      };

      logger.d('Attempting login for: $email');
      logger.d('Using server: ${AppConstants.LOGIN_URL}');
      
      // Convert form data to properly URL encoded format
      String formBody = 'username=${Uri.encodeComponent(email)}&password=${Uri.encodeComponent(password)}';
      
      final response = await httpClient.post(
        Uri.parse(AppConstants.LOGIN_URL),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: formBody,
      ).timeout(const Duration(seconds: 30)); // Increased timeout to 30 seconds

      logger.d('Login response status: ${response.statusCode}');
      logger.d('Login response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        Map<String, dynamic> errorBody;
        try {
          errorBody = json.decode(response.body);
        } catch (e) {
          errorBody = {'detail': 'Unable to parse error response'};
        }
        throw ServerException(
          message: errorBody['detail'] ?? 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } on SocketException catch (e) {
      logger.e('Socket error during login: ${e.toString()}');
      throw ServerException(message: 'Network connection error: ${e.message}. Please check if the server is running.');
    } on TimeoutException catch (e) {
      logger.e('Timeout error during login: ${e.toString()}');
      throw ServerException(message: 'Connection timed out. Please check your internet connection or the server might be unreachable.');
    } catch (e) {
      logger.e('Login error: $e');
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  // Logout and invalidate token
  Future<bool> logout() async {
    try {
      logger.d('Attempting logout');
      
      final token = await secureStorage.read(key: AppConstants.TOKEN_KEY);
      if (token == null) {
        logger.d('No token found, considering already logged out');
        return true;
      }
      
      try {
        // Try to call backend logout endpoint to invalidate token
        final response = await httpClient.post(
          Uri.parse(AppConstants.LOGOUT_URL),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 5));
        
        logger.d('Logout response status: ${response.statusCode}');
      } catch (e) {
        // Even if server logout fails, we'll still clear local tokens
        logger.e('Server logout failed, but continuing with local logout: $e');
      }
      
      // Clear tokens from secure storage regardless of server response
      await secureStorage.delete(key: AppConstants.TOKEN_KEY);
      await secureStorage.delete(key: AppConstants.USER_ROLE_KEY);
      
      logger.d('Logout completed successfully');
      return true;
    } catch (e) {
      logger.e('Logout error: $e');
      // Even if there's an exception, attempt to delete the tokens
      try {
        await secureStorage.delete(key: AppConstants.TOKEN_KEY);
        await secureStorage.delete(key: AppConstants.USER_ROLE_KEY);
      } catch (e) {
        logger.e('Failed to delete tokens during error recovery: $e');
      }
      return false;
    }
  }

  // Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = await secureStorage.read(key: AppConstants.TOKEN_KEY);
      
      final response = await httpClient.get(
        Uri.parse(AppConstants.PROFILE_URL),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw ServerException(
          message: errorBody['detail'] ?? 'Failed to get profile',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw ServerException(message: AppConstants.NETWORK_ERROR);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  // Get nearby issues
  Future<List<dynamic>> getNearbyIssues(
    double latitude,
    double longitude, {
    double radiusKm = AppConstants.DEFAULT_SEARCH_RADIUS_KM,
    String? status,
  }) async {
    try {
      String url = '${AppConstants.NEARBY_ISSUES_URL}?latitude=$latitude&longitude=$longitude&radius_km=$radiusKm';
      
      if (status != null) {
        url += '&status=$status';
      }

      final token = await secureStorage.read(key: AppConstants.TOKEN_KEY);
      
      final response = await httpClient.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw ServerException(
          message: errorBody['detail'] ?? 'Failed to get nearby issues',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw ServerException(message: AppConstants.NETWORK_ERROR);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  // Get issue details
  Future<Map<String, dynamic>> getIssueDetails(int issueId) async {
    try {
      final token = await secureStorage.read(key: AppConstants.TOKEN_KEY);
      
      final response = await httpClient.get(
        Uri.parse('${AppConstants.ISSUE_DETAIL_URL}/$issueId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw ServerException(
          message: errorBody['detail'] ?? 'Failed to get issue details',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw ServerException(message: AppConstants.NETWORK_ERROR);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  // Resolve issue with photo
  Future<Map<String, dynamic>> resolveIssue({
    required int issueId,
    required File photo,
    required double latitude,
    required double longitude,
    required String status,
  }) async {
    try {
      final token = await secureStorage.read(key: AppConstants.TOKEN_KEY);
      
      // Using Dio for multipart form data (easier than http package)
      final formData = FormData.fromMap({
        'resolution_photo': await MultipartFile.fromFile(photo.path),
        'latitude': latitude,
        'longitude': longitude,
        'status': status,
      });

      final response = await dio.post(
        '${AppConstants.RESOLVE_ISSUE_URL}/$issueId/resolve',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      return response.data;
    } on DioException catch (e) {
      logger.e('Dio error: ${e.message}', error: e, stackTrace: e.stackTrace);
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw ServerException(message: AppConstants.NETWORK_ERROR);
      }
      
      final errorMsg = e.response?.data?['detail'] ?? 'Failed to resolve issue';
      throw ServerException(
        message: errorMsg,
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
}
