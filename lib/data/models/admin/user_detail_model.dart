import 'package:cognoapp/data/models/user_model.dart';

class UserDetailModel extends UserModel {
  final int? zoneId;
  final int? wardId;
  final String? zoneName;
  final String? wardName;
  final String? status;
  final DateTime? lastLogin;

  UserDetailModel({
    required String id,
    required String name,
    required String email,
    required String role,
    DateTime? createdAt,
    this.zoneId,
    this.wardId,
    this.zoneName,
    this.wardName,
    this.status,
    this.lastLogin,
  }) : super(
          id: id,
          name: name,
          email: email,
          role: role,
          createdAt: createdAt,
        );

  factory UserDetailModel.fromJson(Map<String, dynamic> json) {
    return UserDetailModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      zoneId: json['zone_id'],
      wardId: json['ward_id'],
      zoneName: json['zone_name'] ?? 'Zone ${json['zone_id'] ?? 'Unknown'}',
      wardName: json['ward_name'],
      status: json['status'] ?? 'active',
      lastLogin: json['last_login'] != null 
          ? DateTime.parse(json['last_login']) 
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'zone_id': zoneId,
      'ward_id': wardId,
      'zone_name': zoneName,
      'ward_name': wardName,
      'status': status,
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  UserDetailModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    DateTime? createdAt,
    String? department,
    String? phoneNumber,
    bool? isActive,
    DateTime? lastLoginAt,
    int? zoneId,
    int? wardId,
    String? zoneName,
    String? wardName,
    String? status,
    DateTime? lastLogin,
  }) {
    return UserDetailModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      zoneId: zoneId ?? this.zoneId,
      wardId: wardId ?? this.wardId,
      zoneName: zoneName ?? this.zoneName,
      wardName: wardName ?? this.wardName,
      status: status ?? this.status,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
