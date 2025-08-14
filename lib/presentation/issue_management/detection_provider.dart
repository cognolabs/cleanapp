import 'package:flutter/material.dart';
import 'package:cognoapp/core/network/api_client.dart';
import 'package:cognoapp/data/models/detection_model.dart';
import 'package:cognoapp/core/error/exceptions.dart';
import 'dart:io';

class DetectionProvider extends ChangeNotifier {
  final ApiClient apiClient;

  List<DetectionModel> _issues = [];
  DetectionModel? _selectedIssue;
  bool _isLoading = false;

  DetectionProvider({required this.apiClient});
  
  List<DetectionModel> get issues => _issues;
  DetectionModel? get selectedIssue => _selectedIssue;
  bool get isLoading => _isLoading;

  // Fetch nearby issues based on location
  Future<void> fetchNearbyIssues(
    double latitude,
    double longitude, {
    double radiusKm = 5.0,
    String? status,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final resultsJson = await apiClient.getNearbyIssues(
        latitude,
        longitude,
        radiusKm: radiusKm,
        status: status,
      );
      
      _issues = resultsJson.map((json) => DetectionModel.fromJson(json)).toList();
    } catch (e) {
      _issues = [];
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch issue details by ID
  Future<DetectionModel> fetchIssueById(int issueId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final resultJson = await apiClient.getIssueDetails(issueId);
      final issue = DetectionModel.fromJson(resultJson);
      
      _selectedIssue = issue;
      return issue;
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      } else {
        throw ServerException(message: e.toString());
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Resolve an issue with photo evidence
  Future<bool> resolveIssue(
    int issueId,
    File photo,
    double latitude,
    double longitude,
    String status,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      await apiClient.resolveIssue(
        issueId: issueId,
        photo: photo,
        latitude: latitude,
        longitude: longitude,
        status: status,
      );
      
      // If resolution was successful, update the issue in the local list
      if (_selectedIssue != null && _selectedIssue!.id == issueId) {
        _selectedIssue = DetectionModel(
          id: _selectedIssue!.id,
          timestamp: _selectedIssue!.timestamp,
          latitude: _selectedIssue!.latitude,
          longitude: _selectedIssue!.longitude,
          className: _selectedIssue!.className,
          modelType: _selectedIssue!.modelType,
          confidence: _selectedIssue!.confidence,
          mapsLink: _selectedIssue!.mapsLink,
          framePath: _selectedIssue!.framePath,
          status: status, // Update the status
          videoId: _selectedIssue!.videoId,
          zone: _selectedIssue!.zone,
          wardName: _selectedIssue!.wardName,
        );
      }
      
      // Update status in the list if the resolved issue is there
      _issues = _issues.map((issue) {
        if (issue.id == issueId) {
          return DetectionModel(
            id: issue.id,
            timestamp: issue.timestamp,
            latitude: issue.latitude,
            longitude: issue.longitude,
            className: issue.className,
            modelType: issue.modelType,
            confidence: issue.confidence,
            mapsLink: issue.mapsLink,
            framePath: issue.framePath,
            status: status, // Update the status
            videoId: issue.videoId,
            zone: issue.zone,
            wardName: issue.wardName,
          );
        }
        return issue;
      }).toList();
      
      return true;
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      } else {
        throw ServerException(message: e.toString());
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter issues by status
  List<DetectionModel> getIssuesByStatus(String status) {
    if (status.toLowerCase() == 'all') {
      return _issues;
    }
    return _issues.where((issue) => issue.status.toLowerCase() == status.toLowerCase()).toList();
  }

  // Clear selected issue
  void clearSelectedIssue() {
    _selectedIssue = null;
    notifyListeners();
  }
}
