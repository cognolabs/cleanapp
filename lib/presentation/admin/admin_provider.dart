import 'package:flutter/material.dart';
import 'package:cognoapp/data/repositories/admin/user_management_repository.dart';
import 'package:cognoapp/data/models/admin/user_detail_model.dart';
import 'package:cognoapp/core/error/exceptions.dart';

class AdminProvider extends ChangeNotifier {
  final UserManagementRepository repository;

  AdminProvider({
    required this.repository,
  });

  // State variables
  List<UserDetailModel> _users = [];
  UserDetailModel? _selectedUser;
  bool _isLoading = false;
  String _errorMessage = '';
  String _searchQuery = '';
  
  // Filtered users based on search query
  List<UserDetailModel> get filteredUsers {
    if (_searchQuery.isEmpty) {
      return _users;
    }
    return _users.where((user) {
      final query = _searchQuery.toLowerCase();
      return user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          (user.zoneName != null && user.zoneName!.toLowerCase().contains(query)) ||
          (user.wardName != null && user.wardName!.toLowerCase().contains(query));
    }).toList();
  }
  
  // Getters
  List<UserDetailModel> get users => _users;
  UserDetailModel? get selectedUser => _selectedUser;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;
  String get searchQuery => _searchQuery;

  // Fetch all users
  Future<void> fetchUsers() async {
    _setLoading(true);
    _clearError();

    try {
      final users = await repository.getUsers();
      _users = users;
      
      // If empty list, set default empty array instead of null
      if (_users.isEmpty) {
        _users = [];
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load users: ${e.toString()}');
      // Ensure we have a defined value even on error
      _users = [];
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Get details for a specific user
  Future<void> getUserDetails(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await repository.getUserDetails(userId);
      _selectedUser = user;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load user details: ${e.toString()}');
      // Clear selected user on error to avoid null references
      _selectedUser = null;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Update user zone and ward
  Future<bool> updateUserZoneWard(String userId, int zoneId, int wardId) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedUser = await repository.updateUserZoneWard(userId, zoneId, wardId);
      
      // Update user in the list
      final index = _users.indexWhere((user) => user.id == userId);
      if (index != -1) {
        _users[index] = updatedUser;
      }
      
      // Update selected user if it's the same one
      if (_selectedUser?.id == userId) {
        _selectedUser = updatedUser;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update user zone/ward: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update user status
  Future<bool> updateUserStatus(String userId, String status) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedUser = await repository.updateUserStatus(userId, status);
      
      // Update user in the list
      final index = _users.indexWhere((user) => user.id == userId);
      if (index != -1) {
        _users[index] = updatedUser;
      }
      
      // Update selected user if it's the same one
      if (_selectedUser?.id == userId) {
        _selectedUser = updatedUser;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update user status: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update user role
  Future<bool> updateUserRole(String userId, String role) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedUser = await repository.updateUserRole(userId, role);
      
      // Update user in the list
      final index = _users.indexWhere((user) => user.id == userId);
      if (index != -1) {
        _users[index] = updatedUser;
      }
      
      // Update selected user if it's the same one
      if (_selectedUser?.id == userId) {
        _selectedUser = updatedUser;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update user role: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Set selected user
  void setSelectedUser(UserDetailModel user) {
    _selectedUser = user;
    notifyListeners();
  }

  // Clear selected user
  void clearSelectedUser() {
    _selectedUser = null;
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}
