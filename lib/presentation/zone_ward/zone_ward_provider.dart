import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cognoapp/data/models/zone_ward_model.dart';
import 'package:cognoapp/data/repositories/zone_ward_repository.dart';
import 'package:cognoapp/core/error/exceptions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ZoneWardProvider extends ChangeNotifier {
  final ZoneWardRepository repository;
  final SharedPreferences sharedPreferences;

  ZoneWardProvider({
    required this.repository,
    required this.sharedPreferences,
  }) {
    // Load saved preferences when initialized
    _loadSavedPreferences();
  }

  // State variables
  List<int> _zones = [];
  List<WardModel> _wards = [];
  int? _selectedZoneId;
  int? _selectedWardId;
  WardBoundaryModel? _selectedWardBoundary;
  Set<Polygon> _wardPolygons = {};
  bool _isLoading = false;
  String _errorMessage = '';
  bool _hasBeenSelected = false;  // Flag to track if user has made a selection

  // Getters
  List<int> get zones => _zones;
  List<WardModel> get wards => _wards;
  int? get selectedZoneId => _selectedZoneId;
  int? get selectedWardId => _selectedWardId;
  WardBoundaryModel? get selectedWardBoundary => _selectedWardBoundary;
  Set<Polygon> get wardPolygons => _wardPolygons;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;
  bool get hasBeenSelected => _hasBeenSelected;

  // Load saved zone and ward preferences
  Future<void> _loadSavedPreferences() async {
    _selectedZoneId = sharedPreferences.getInt('selected_zone_id');
    _selectedWardId = sharedPreferences.getInt('selected_ward_id');
    
    if (_selectedZoneId != null && _selectedWardId != null) {
      _hasBeenSelected = true;
    }
    
    // If we have saved selections, load the data
    if (_selectedZoneId != null) {
      await fetchZones();
      
      if (_selectedWardId != null) {
        await fetchWardsByZone(_selectedZoneId!);
        await fetchWardBoundary(_selectedWardId!);
      }
    }
  }

  // Initialize for zone/ward selection
  void initialize() async {
    // Clear current selections
    clearSelections();
    await fetchZones();
  }

  // Save zone and ward preferences
  Future<void> _savePreferences() async {
    if (_selectedZoneId != null) {
      await sharedPreferences.setInt('selected_zone_id', _selectedZoneId!);
    } else {
      await sharedPreferences.remove('selected_zone_id');
    }
    
    if (_selectedWardId != null) {
      await sharedPreferences.setInt('selected_ward_id', _selectedWardId!);
    } else {
      await sharedPreferences.remove('selected_ward_id');
    }
  }

  // Fetch all available zones
  Future<void> fetchZones() async {
    _setLoading(true);
    _clearError();

    try {
      print('Fetching zones from repository');
      final zones = await repository.getZones();
      print('Raw zones from repository: $zones');
      
      // Ensure _zones is never null, use empty list if null
      _zones = zones.isNotEmpty ? zones : [];
      print('Zones assigned to provider: $_zones (length: ${_zones.length})');
      notifyListeners();
      
      if (_zones.isEmpty) {
        print('WARNING: Zones list is empty after fetch!');
        _setError('No zones available. Please check your connection and try again.');
      }
    } catch (e) {
      print('Error fetching zones: $e');
      _setError('Failed to load zones: ${e.toString()}');
      // Set empty array on error to avoid null issues
      _zones = [];
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Fetch wards for a selected zone
  Future<void> fetchWardsByZone(int zoneId) async {
    _setLoading(true);
    _clearError();

    try {
      final wards = await repository.getWardsByZone(zoneId);
      // Ensure _wards is never null, use empty list if null
      _wards = wards.isNotEmpty ? wards : [];
      _selectedZoneId = zoneId;
      notifyListeners();
      
      // Save to preferences
      _savePreferences();
      
      if (_wards.isEmpty) {
        _setError('No wards available for this zone. Please try another zone.');
      }
    } catch (e) {
      _setError('Failed to load wards: ${e.toString()}');
      // Set empty array on error to avoid null issues
      _wards = [];
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Fetch boundary coordinates for a selected ward
  Future<void> fetchWardBoundary(int wardId) async {
    _setLoading(true);
    _clearError();

    try {
      final boundary = await repository.getWardBoundary(wardId);
      _selectedWardBoundary = boundary;
      _selectedWardId = wardId;
      
      // Create polygon from boundary
      _wardPolygons = {boundary.toPolygon()};
      
      // Mark that the user has made a selection
      _hasBeenSelected = true;
      
      notifyListeners();
      
      // Save to preferences
      _savePreferences();
    } catch (e) {
      _setError('Failed to load ward boundary: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Select a zone and fetch its wards
  Future<void> selectZone(int zoneId) async {
    if (_selectedZoneId == zoneId) return;
    
    // Clear current ward selection
    _selectedWardId = null;
    _selectedWardBoundary = null;
    _wardPolygons = {};
    
    await fetchWardsByZone(zoneId);
  }

  // Select a ward and fetch its boundary
  Future<void> selectWard(int wardId) async {
    if (_selectedWardId == wardId) return;
    
    await fetchWardBoundary(wardId);
  }

  // Clear zone and ward selections
  void clearSelections() {
    _selectedZoneId = null;
    _selectedWardId = null;
    _selectedWardBoundary = null;
    _wardPolygons = {};
    _wards = [];
    _hasBeenSelected = false;
    
    // Remove from preferences
    _savePreferences();
    
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
