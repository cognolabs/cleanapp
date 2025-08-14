import 'package:cognoapp/domain/entities/user.dart';

class UserModel extends User {
  UserModel({
    required String id,
    required String name,
    required String email,
    required String role,
    DateTime? createdAt,
    String? department,
    String? phoneNumber,
    bool isActive = true,
    DateTime? lastLoginAt,
  }) : super(
          id: id,
          name: name,
          email: email,
          role: role,
          createdAt: createdAt,
          department: department,
          phoneNumber: phoneNumber,
          isActive: isActive,
          lastLoginAt: lastLoginAt,
        );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'viewer',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      department: json['department'],
      phoneNumber: json['phone_number'],
      isActive: json['is_active'] ?? true,
      lastLoginAt: json['last_login_at'] != null 
          ? DateTime.parse(json['last_login_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'created_at': createdAt?.toIso8601String(),
      'department': department,
      'phone_number': phoneNumber,
      'is_active': isActive,
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }

  @override
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    DateTime? createdAt,
    String? department,
    String? phoneNumber,
    bool? isActive,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      department: department ?? this.department,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isActive: isActive ?? this.isActive,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
