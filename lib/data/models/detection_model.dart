import 'package:cognoapp/domain/entities/detection.dart';

class DetectionModel extends Detection {
  DetectionModel({
    required int id,
    required DateTime timestamp,
    required double latitude,
    required double longitude,
    required String className,
    required String modelType,
    required double confidence,
    String? mapsLink,
    String? framePath,
    required String status,
    int? videoId,
    String? zone,
    String? wardName,
  }) : super(
          id: id,
          timestamp: timestamp,
          latitude: latitude,
          longitude: longitude,
          className: className,
          modelType: modelType,
          confidence: confidence,
          mapsLink: mapsLink,
          framePath: framePath,
          status: status,
          videoId: videoId,
          zone: zone,
          wardName: wardName,
        );

  factory DetectionModel.fromJson(Map<String, dynamic> json) {
    return DetectionModel(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      className: json['class_name'],
      modelType: json['model_type'],
      confidence: json['confidence'].toDouble(),
      mapsLink: json['maps_link'],
      framePath: json['frame_path'],
      status: json['status'],
      videoId: json['video_id'],
      zone: json['zone'],
      wardName: json['ward_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'class_name': className,
      'model_type': modelType,
      'confidence': confidence,
      'maps_link': mapsLink,
      'frame_path': framePath,
      'status': status,
      'video_id': videoId,
      'zone': zone,
      'ward_name': wardName,
    };
  }
}
