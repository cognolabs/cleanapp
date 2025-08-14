import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cognoapp/core/network/api_client.dart';
import 'package:cognoapp/data/models/user_model.dart';
import 'package:cognoapp/config/constants.dart';
import 'package:cognoapp/core/error/exceptions.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient apiClient;
  final FlutterSecureStorage secureStorage;
  final SharedPreferences sharedPreferences;

  UserModel? _currentUser;
  bool _isLoading = true; // Start as loading
  bool _isAuthenticated = false;
  bool _requireZoneWardSelection = false; // Changed to false by default

  AuthProvider({
    required this.apiClient,
    required this.secureStorage,
    required this.sharedPreferences,
  }) {
    // Check authentication status when provider is initialized
    checkAuthStatus();
  }

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isManager => _currentUser?.isManager ?? false;
  bool get requireZoneWardSelection => _requireZoneWardSelection;

  // Check if user is already authenticated
  Future<bool> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await secureStorage.read(key: AppConstants.TOKEN_KEY);
      
      if (token == null) {
        _isAuthenticated = false;
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      try {
        final userProfileResult = await apiClient.getUserProfile();
        _currentUser = UserModel.fromJson(userProfileResult);
        _isAuthenticated = true;
        
        // Check if zone/ward has been selected
        final hasSelectedZoneWard = sharedPreferences.containsKey('selected_zone_id') && 
                                  sharedPreferences.containsKey('selected_ward_id');
        
        // Only require zone/ward selection if it hasn't been done before
        _requireZoneWardSelection = !hasSelectedZoneWard;
        
        // Pre-cache the auth state to prevent flashing
        _isLoading = false;
        notifyListeners();
        
        // Add a small delay to ensure UI has time to update
        await Future.delayed(const Duration(milliseconds: 100));
        return true;
      } catch (e) {
        // Token might be invalid, clear it
        await secureStorage.delete(key: AppConstants.TOKEN_KEY);
        _isAuthenticated = false;
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isAuthenticated = false;
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login with email and password
  Future<bool> login(
    String email, 
    String password, 
    bool rememberMe,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final loginResult = await apiClient.login(email, password);
      
      // Save token to secure storage
      await secureStorage.write(
        key: AppConstants.TOKEN_KEY, 
        value: loginResult['access_token'],
      );
      
      // Save user role
      await secureStorage.write(
        key: AppConstants.USER_ROLE_KEY, 
        value: loginResult['role'],
      );
      
      // Save remember me preference
      await sharedPreferences.setBool(AppConstants.REMEMBER_ME_KEY, rememberMe);
      
      // If remember me is checked, save email
      if (rememberMe) {
        await sharedPreferences.setString(AppConstants.SAVED_EMAIL_KEY, email);
      } else {
        await sharedPreferences.remove(AppConstants.SAVED_EMAIL_KEY);
      }
      
      // Check if zone/ward have been selected before
      final hasSelectedZoneWard = sharedPreferences.containsKey('selected_zone_id') && 
                                sharedPreferences.containsKey('selected_ward_id');
      
      // Only require selection if not previously done
      _requireZoneWardSelection = !hasSelectedZoneWard;
      
      // Get user profile to complete login
      final userProfileResult = await apiClient.getUserProfile();
      _currentUser = UserModel.fromJson(userProfileResult);
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _isAuthenticated = false;
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
      
      if (e is ServerException) {
        rethrow;
      } else {
        throw ServerException(message: e.toString());
      }
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Try to call the logout API endpoint
      await apiClient.logout();
    } catch (e) {
      // Ignore errors during logout API call
    } finally {
      // Always clear local storage
      await secureStorage.delete(key: AppConstants.TOKEN_KEY);
      
      // Keep email for convenience if remember me was enabled
      final rememberMe = sharedPreferences.getBool(AppConstants.REMEMBER_ME_KEY) ?? false;
      if (!rememberMe) {
        await sharedPreferences.remove(AppConstants.SAVED_EMAIL_KEY);
      }
      
      // Don't clear zone/ward selections on logout
      
      _currentUser = null;
      _isAuthenticated = false;
      _requireZoneWardSelection = false; // Reset for next login
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark that zone/ward selection is complete
  void completeZoneWardSelection() {
    _requireZoneWardSelection = false;
    notifyListeners();
  }
  
  // Trigger zone/ward selection for admin
  void requestZoneWardSelection() {
    _requireZoneWardSelection = true;
    notifyListeners();
  }

  // Get saved email if remember me was checked
  String? getSavedEmail() {
    return sharedPreferences.getString(AppConstants.SAVED_EMAIL_KEY);
  }

  // Check if remember me is enabled
  bool isRememberMeEnabled() {
    return sharedPreferences.getBool(AppConstants.REMEMBER_ME_KEY) ?? false;
  }
}
