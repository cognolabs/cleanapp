import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cognoapp/config/constants.dart';
import 'package:cognoapp/core/utils/api_helper.dart';
import 'package:cognoapp/core/error/exceptions.dart';
import 'package:cognoapp/data/models/admin/user_detail_model.dart';

class UserManagementRepository {
  final http.Client client;
  final ApiHelper apiHelper;

  UserManagementRepository({
    required this.client,
    required this.apiHelper,
  });

  /// Fetches all users with their details
  Future<List<UserDetailModel>> getUsers() async {
    try {
      final authHeader = await apiHelper.getAuthHeader();
      final url = '${AppConstants.BASE_URL}/api/admin/users';
      
      final response = await client.get(
        Uri.parse(url),
        headers: authHeader,
      );

      if (response.statusCode == 200) {
        final List<dynamic> usersJson = json.decode(response.body);
        return usersJson.map((user) => UserDetailModel.fromJson(user)).toList();
      } else {
        throw ServerException(
          message: 'Failed to fetch users', 
          statusCode: response.statusCode
        );
      }
    } catch (e) {
      throw ServerException(message: 'Failed to fetch users: $e');
    }
  }

  /// Get details for a specific user
  Future<UserDetailModel> getUserDetails(String userId) async {
    try {
      final authHeader = await apiHelper.getAuthHeader();
      final url = '${AppConstants.BASE_URL}/api/admin/users/$userId';
      
      final response = await client.get(
        Uri.parse(url),
        headers: authHeader,
      );

      if (response.statusCode == 200) {
        final userJson = json.decode(response.body);
        return UserDetailModel.fromJson(userJson);
      } else {
        throw ServerException(
          message: 'Failed to fetch user details', 
          statusCode: response.statusCode
        );
      }
    } catch (e) {
      throw ServerException(message: 'Failed to fetch user details: $e');
    }
  }

  /// Update a user's zone and ward
  Future<UserDetailModel> updateUserZoneWard(
    String userId, 
    int zoneId, 
    int wardId
  ) async {
    try {
      final authHeader = await apiHelper.getAuthHeader();
      final url = '${AppConstants.BASE_URL}/api/admin/users/$userId/zone-ward';
      
      final response = await client.put(
        Uri.parse(url),
        headers: {
          ...authHeader,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'zone_id': zoneId,
          'ward_id': wardId,
        }),
      );

      if (response.statusCode == 200) {
        final userJson = json.decode(response.body);
        return UserDetailModel.fromJson(userJson);
      } else {
        throw ServerException(
          message: 'Failed to update user zone/ward', 
          statusCode: response.statusCode
        );
      }
    } catch (e) {
      throw ServerException(message: 'Failed to update user zone/ward: $e');
    }
  }

  /// Update user status (active/inactive)
  Future<UserDetailModel> updateUserStatus(String userId, String status) async {
    try {
      final authHeader = await apiHelper.getAuthHeader();
      final url = '${AppConstants.BASE_URL}/api/admin/users/$userId/status';
      
      final response = await client.put(
        Uri.parse(url),
        headers: {
          ...authHeader,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        final userJson = json.decode(response.body);
        return UserDetailModel.fromJson(userJson);
      } else {
        throw ServerException(
          message: 'Failed to update user status', 
          statusCode: response.statusCode
        );
      }
    } catch (e) {
      throw ServerException(message: 'Failed to update user status: $e');
    }
  }

  /// Update user role (admin/user)
  Future<UserDetailModel> updateUserRole(String userId, String role) async {
    try {
      final authHeader = await apiHelper.getAuthHeader();
      final url = '${AppConstants.BASE_URL}/api/admin/users/$userId/role';
      
      final response = await client.put(
        Uri.parse(url),
        headers: {
          ...authHeader,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'role': role,
        }),
      );

      if (response.statusCode == 200) {
        final userJson = json.decode(response.body);
        return UserDetailModel.fromJson(userJson);
      } else {
        throw ServerException(
          message: 'Failed to update user role', 
          statusCode: response.statusCode
        );
      }
    } catch (e) {
      throw ServerException(message: 'Failed to update user role: $e');
    }
  }
}
