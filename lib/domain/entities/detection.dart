class Detection {
  final int id;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String className;
  final String modelType;
  final double confidence;
  final String? mapsLink;
  final String? framePath;
  final String status;
  final int? videoId;
  final String? zone;
  final String? wardName;

  Detection({
    required this.id,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.className,
    required this.modelType,
    required this.confidence,
    this.mapsLink,
    this.framePath,
    required this.status,
    this.videoId,
    this.zone,
    this.wardName,
  });
}
