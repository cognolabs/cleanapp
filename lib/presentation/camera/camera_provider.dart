import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cognoapp/core/network/api_client.dart';
import 'package:cognoapp/data/models/detection_model.dart';
import 'package:cognoapp/config/constants.dart';

class CameraProvider extends ChangeNotifier {
  final ApiClient apiClient;
  
  bool _isProcessing = false;
  String? _error;
  ProcessingResult? _lastProcessingResult;
  List<ProcessingResult> _processingHistory = [];

  CameraProvider({required this.apiClient});

  bool get isProcessing => _isProcessing;
  String? get error => _error;
  ProcessingResult? get lastProcessingResult => _lastProcessingResult;
  List<ProcessingResult> get processingHistory => _processingHistory;

  Future<void> processImage({
    required String imagePath,
    required double latitude,
    required double longitude,
  }) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      // Create multipart request directly
      final uri = Uri.parse('${AppConstants.API_URL}/mobile/process-image');
      final request = http.MultipartRequest('POST', uri);
      
      // Add headers
      final token = await apiClient.secureStorage.read(key: AppConstants.TOKEN_KEY);
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      // Add image file
      final imageFile = File(imagePath);
      final multipartFile = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        filename: 'mobile_image.jpg',
      );
      request.files.add(multipartFile);
      
      // Add coordinates
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final result = ProcessingResult.fromJson(responseData);
        
        _lastProcessingResult = result;
        _processingHistory.insert(0, result);
        
        // Keep only last 10 results in memory
        if (_processingHistory.length > 10) {
          _processingHistory = _processingHistory.take(10).toList();
        }
      } else {
        final errorData = json.decode(response.body);
        _error = errorData['detail'] ?? 'Failed to process image';
        throw Exception(_error);
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearHistory() {
    _processingHistory.clear();
    _lastProcessingResult = null;
    notifyListeners();
  }
}

class ProcessingResult {
  final String processingId;
  final ImageCoordinates imageCoordinates;
  final List<MobileDetection> detections;
  final int totalDetections;
  final DateTime processedAt;
  final List<String> modelsProcessed;

  ProcessingResult({
    required this.processingId,
    required this.imageCoordinates,
    required this.detections,
    required this.totalDetections,
    required this.processedAt,
    required this.modelsProcessed,
  });

  factory ProcessingResult.fromJson(Map<String, dynamic> json) {
    return ProcessingResult(
      processingId: json['processing_id'],
      imageCoordinates: ImageCoordinates.fromJson(json['image_coordinates']),
      detections: (json['detections'] as List)
          .map((d) => MobileDetection.fromJson(d))
          .toList(),
      totalDetections: json['total_detections'],
      processedAt: DateTime.parse(json['processed_at']),
      modelsProcessed: List<String>.from(json['models_processed']),
    );
  }
}

class ImageCoordinates {
  final double latitude;
  final double longitude;

  ImageCoordinates({
    required this.latitude,
    required this.longitude,
  });

  factory ImageCoordinates.fromJson(Map<String, dynamic> json) {
    return ImageCoordinates(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
    );
  }
}

class MobileDetection {
  final String detectionId;
  final String timestamp;
  final double latitude;
  final double longitude;
  final String className;
  final double confidence;
  final String modelType;
  final String processingId;
  final String framePath;
  final String zone;
  final String wardName;
  final List<int> bbox;
  final String mapsLink;

  MobileDetection({
    required this.detectionId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.className,
    required this.confidence,
    required this.modelType,
    required this.processingId,
    required this.framePath,
    required this.zone,
    required this.wardName,
    required this.bbox,
    required this.mapsLink,
  });

  factory MobileDetection.fromJson(Map<String, dynamic> json) {
    return MobileDetection(
      detectionId: json['detection_id'],
      timestamp: json['timestamp'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      className: json['class_name'],
      confidence: json['confidence'].toDouble(),
      modelType: json['model_type'],
      processingId: json['processing_id'],
      framePath: json['frame_path'],
      zone: json['zone'],
      wardName: json['ward_name'],
      bbox: List<int>.from(json['bbox']),
      mapsLink: json['maps_link'],
    );
  }

  // Convert to DetectionModel for compatibility
  DetectionModel toDetectionModel() {
    return DetectionModel(
      id: detectionId.hashCode,
      timestamp: DateTime.parse(timestamp),
      latitude: latitude,
      longitude: longitude,
      className: className,
      confidence: confidence,
      framePath: framePath,
      status: 'open',
      modelType: modelType,
      zone: zone,
      wardName: wardName,
      mapsLink: mapsLink,
    );
  }
}