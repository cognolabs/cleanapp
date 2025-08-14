enum UserRole {
  admin('admin'),
  manager('manager'),
  operator('operator'),
  viewer('viewer');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String roleString) {
    switch (roleString.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      case 'operator':
        return UserRole.operator;
      case 'viewer':
        return UserRole.viewer;
      default:
        return UserRole.viewer;
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.manager:
        return 'Manager';
      case UserRole.operator:
        return 'Operator';
      case UserRole.viewer:
        return 'Viewer';
    }
  }

  String get description {
    switch (this) {
      case UserRole.admin:
        return 'Full system access with all administrative privileges';
      case UserRole.manager:
        return 'Management access with operational oversight capabilities';
      case UserRole.operator:
        return 'Operational access to core detection and monitoring features';
      case UserRole.viewer:
        return 'Read-only access to view detection data and analytics';
    }
  }
}

class RoleConfig {
  final String name;
  final String displayName;
  final String description;
  final Map<Permission, bool> permissions;
  final RoleRestrictions restrictions;

  const RoleConfig({
    required this.name,
    required this.displayName,
    required this.description,
    required this.permissions,
    required this.restrictions,
  });
}

class RoleRestrictions {
  final bool isReadOnly;
  final bool requiresApproval;
  final List<String> limitedFeatures;

  const RoleRestrictions({
    required this.isReadOnly,
    required this.requiresApproval,
    required this.limitedFeatures,
  });
}

class RolePermissions {
  static const Map<UserRole, RoleConfig> _roleConfigs = {
    UserRole.admin: RoleConfig(
      name: 'admin',
      displayName: 'Administrator',
      description: 'Full system access with all administrative privileges',
      permissions: {
        // Navigation permissions
        Permission.canAccessDashboard: true,
        Permission.canAccessMap: true,
        Permission.canAccessAnalytics: true,
        Permission.canAccessSearch: true,
        Permission.canAccessReports: true,
        Permission.canAccessUploads: true,
        Permission.canAccessUploadStatus: true,
        Permission.canAccessQueue: true,
        Permission.canAccessLiveView: true,
        Permission.canAccessUserManagement: true,
        Permission.canAccessSystemSettings: true,
        
        // Action permissions
        Permission.canCreate: true,
        Permission.canEdit: true,
        Permission.canDelete: true,
        Permission.canApprove: true,
        Permission.canExport: true,
        
        // Data permissions
        Permission.canViewAllData: true,
        Permission.canViewOwnData: true,
        Permission.canModifySettings: true,
        Permission.canManageUsers: true,
        Permission.canReceiveAlerts: true,
        Permission.canResolveIssues: true,
        Permission.canAssignTasks: true,
      },
      restrictions: RoleRestrictions(
        isReadOnly: false,
        requiresApproval: false,
        limitedFeatures: [],
      ),
    ),
    
    UserRole.manager: RoleConfig(
      name: 'manager',
      displayName: 'Manager',
      description: 'Management access with operational oversight capabilities',
      permissions: {
        // Navigation permissions
        Permission.canAccessDashboard: true,
        Permission.canAccessMap: true,
        Permission.canAccessAnalytics: true,
        Permission.canAccessSearch: true,
        Permission.canAccessReports: true,
        Permission.canAccessUploads: true,
        Permission.canAccessUploadStatus: true,
        Permission.canAccessQueue: true,
        Permission.canAccessLiveView: true,
        Permission.canAccessUserManagement: false,
        Permission.canAccessSystemSettings: false,
        
        // Action permissions
        Permission.canCreate: true,
        Permission.canEdit: true,
        Permission.canDelete: true,
        Permission.canApprove: true,
        Permission.canExport: true,
        
        // Data permissions
        Permission.canViewAllData: true,
        Permission.canViewOwnData: true,
        Permission.canModifySettings: false,
        Permission.canManageUsers: false,
        Permission.canReceiveAlerts: true,
        Permission.canResolveIssues: true,
        Permission.canAssignTasks: true,
      },
      restrictions: RoleRestrictions(
        isReadOnly: false,
        requiresApproval: false,
        limitedFeatures: ['user-management', 'system-settings'],
      ),
    ),
    
    UserRole.operator: RoleConfig(
      name: 'operator',
      displayName: 'Operator',
      description: 'Operational access to core detection and monitoring features',
      permissions: {
        // Navigation permissions
        Permission.canAccessDashboard: true,
        Permission.canAccessMap: true,
        Permission.canAccessAnalytics: true,
        Permission.canAccessSearch: true,
        Permission.canAccessReports: false,
        Permission.canAccessUploads: false,
        Permission.canAccessUploadStatus: false,
        Permission.canAccessQueue: false,
        Permission.canAccessLiveView: true,
        Permission.canAccessUserManagement: false,
        Permission.canAccessSystemSettings: false,
        
        // Action permissions
        Permission.canCreate: true,
        Permission.canEdit: true,
        Permission.canDelete: false,
        Permission.canApprove: false,
        Permission.canExport: true,
        
        // Data permissions
        Permission.canViewAllData: true,
        Permission.canViewOwnData: true,
        Permission.canModifySettings: false,
        Permission.canManageUsers: false,
        Permission.canReceiveAlerts: false,
        Permission.canResolveIssues: true,
        Permission.canAssignTasks: false,
      },
      restrictions: RoleRestrictions(
        isReadOnly: false,
        requiresApproval: true,
        limitedFeatures: ['uploads', 'reports', 'user-management', 'queue'],
      ),
    ),
    
    UserRole.viewer: RoleConfig(
      name: 'viewer',
      displayName: 'Viewer',
      description: 'Read-only access to view detection data and analytics',
      permissions: {
        // Navigation permissions
        Permission.canAccessDashboard: true,
        Permission.canAccessMap: true,
        Permission.canAccessAnalytics: true,
        Permission.canAccessSearch: true,
        Permission.canAccessReports: false,
        Permission.canAccessUploads: false,
        Permission.canAccessUploadStatus: false,
        Permission.canAccessQueue: false,
        Permission.canAccessLiveView: true,
        Permission.canAccessUserManagement: false,
        Permission.canAccessSystemSettings: false,
        
        // Action permissions
        Permission.canCreate: false,
        Permission.canEdit: false,
        Permission.canDelete: false,
        Permission.canApprove: false,
        Permission.canExport: true,
        
        // Data permissions
        Permission.canViewAllData: true,
        Permission.canViewOwnData: true,
        Permission.canModifySettings: false,
        Permission.canManageUsers: false,
        Permission.canReceiveAlerts: false,
        Permission.canResolveIssues: false,
        Permission.canAssignTasks: false,
      },
      restrictions: RoleRestrictions(
        isReadOnly: true,
        requiresApproval: true,
        limitedFeatures: ['uploads', 'reports', 'user-management', 'queue', 'editing'],
      ),
    ),
  };

  static RoleConfig? getRoleConfig(UserRole role) {
    return _roleConfigs[role];
  }

  static bool hasPermission(UserRole role, Permission permission) {
    final config = _roleConfigs[role];
    return config?.permissions[permission] ?? false;
  }

  static bool canAccessFeature(UserRole role, String feature) {
    final config = _roleConfigs[role];
    if (config == null) return false;
    return !config.restrictions.limitedFeatures.contains(feature);
  }

  static List<UserRole> getAllRoles() {
    return UserRole.values;
  }

  static const List<UserRole> _roleHierarchy = [
    UserRole.viewer,
    UserRole.operator,
    UserRole.manager,
    UserRole.admin,
  ];

  static bool hasHigherOrEqualRole(UserRole role1, UserRole role2) {
    final index1 = _roleHierarchy.indexOf(role1);
    final index2 = _roleHierarchy.indexOf(role2);
    return index1 >= index2;
  }
}

enum Permission {
  // Navigation permissions
  canAccessDashboard,
  canAccessMap,
  canAccessAnalytics,
  canAccessSearch,
  canAccessReports,
  canAccessUploads,
  canAccessUploadStatus,
  canAccessQueue,
  canAccessLiveView,
  canAccessUserManagement,
  canAccessSystemSettings,
  
  // Action permissions
  canCreate,
  canEdit,
  canDelete,
  canApprove,
  canExport,
  
  // Data permissions
  canViewAllData,
  canViewOwnData,
  canModifySettings,
  canManageUsers,
  canReceiveAlerts,
  canResolveIssues,
  canAssignTasks,
}