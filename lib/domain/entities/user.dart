import 'package:cognoapp/core/auth/roles.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime? createdAt;
  final String? department;
  final String? phoneNumber;
  final bool isActive;
  final DateTime? lastLoginAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
    this.department,
    this.phoneNumber,
    this.isActive = true,
    this.lastLoginAt,
  });

  UserRole get userRole => UserRole.fromString(role);
  
  bool get isAdmin => userRole == UserRole.admin;
  bool get isManager => userRole == UserRole.manager;
  bool get isOperator => userRole == UserRole.operator;
  bool get isViewer => userRole == UserRole.viewer;

  bool hasPermission(Permission permission) {
    return RolePermissions.hasPermission(userRole, permission);
  }

  bool canAccessFeature(String feature) {
    return RolePermissions.canAccessFeature(userRole, feature);
  }

  RoleConfig? get roleConfig => RolePermissions.getRoleConfig(userRole);

  User copyWith({
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
    return User(
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
