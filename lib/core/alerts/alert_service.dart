import 'package:cognoapp/core/alerts/alert_models.dart';
import 'package:cognoapp/domain/entities/detection.dart';
import 'package:cognoapp/domain/entities/user.dart';
import 'package:cognoapp/core/auth/roles.dart';

class AlertService {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();

  final List<Alert> _alerts = [];
  final List<AlertRule> _alertRules = [];

  List<Alert> get alerts => List.unmodifiable(_alerts);
  List<AlertRule> get alertRules => List.unmodifiable(_alertRules);

  void initialize() {
    _setupDefaultAlertRules();
    _startPeriodicCheck();
  }

  void _setupDefaultAlertRules() {
    _alertRules.addAll([
      AlertRule(
        id: 'overdue_24h',
        name: 'Issue Overdue 24 Hours',
        description: 'Alert managers when an issue remains uncleared for 24 hours',
        triggerAfter: Duration(hours: 24),
        alertType: AlertType.overdue,
        priority: AlertPriority.high,
        targetRoles: ['admin', 'manager'],
      ),
      AlertRule(
        id: 'critical_12h',
        name: 'Critical Issue 12 Hours',
        description: 'Alert for critical issues not resolved within 12 hours',
        triggerAfter: Duration(hours: 12),
        alertType: AlertType.critical,
        priority: AlertPriority.critical,
        targetRoles: ['admin', 'manager'],
        conditions: {'priority': 'critical', 'type': 'critical'},
      ),
      AlertRule(
        id: 'pending_48h',
        name: 'Pending Issue 48 Hours',
        description: 'Reminder for issues pending for 48 hours',
        triggerAfter: Duration(hours: 48),
        alertType: AlertType.reminder,
        priority: AlertPriority.medium,
        targetRoles: ['admin', 'manager', 'operator'],
      ),
    ]);
  }

  void _startPeriodicCheck() {
    // In a real app, this would be a background service or timer
    // For now, we'll check when called explicitly
  }

  Future<void> checkOverdueIssues(List<Detection> openDetections) async {
    for (final detection in openDetections) {
      if (_shouldSkipDetection(detection)) continue;

      for (final rule in _alertRules) {
        if (rule.shouldTrigger(detection.timestamp, detection.status)) {
          await _createAlert(detection, rule);
        }
      }
    }
  }

  bool _shouldSkipDetection(Detection detection) {
    // Skip if already resolved or closed
    if (['resolved', 'closed', 'completed'].contains(detection.status.toLowerCase())) {
      return true;
    }

    // Skip if alert already exists for this detection and rule combination
    final existingAlert = _alerts.any((alert) => 
      alert.detectionId == detection.id.toString() && 
      !alert.isResolved
    );
    
    return existingAlert;
  }

  Future<void> _createAlert(Detection detection, AlertRule rule) async {
    final alert = Alert(
      id: '${detection.id}_${rule.id}_${DateTime.now().millisecondsSinceEpoch}',
      title: _generateAlertTitle(detection, rule),
      message: _generateAlertMessage(detection, rule),
      type: rule.alertType,
      priority: rule.priority,
      detectionId: detection.id.toString(),
      createdAt: DateTime.now(),
      metadata: {
        'ruleId': rule.id,
        'detectionLocation': '${detection.latitude},${detection.longitude}',
        'detectionClass': detection.className,
        'zone': detection.zone,
        'wardName': detection.wardName,
        'originalTimestamp': detection.timestamp.toIso8601String(),
        'targetRoles': rule.targetRoles,
      },
    );

    _alerts.add(alert);
    
    // Send notifications to target roles
    await _sendNotifications(alert, rule.targetRoles);
  }

  String _generateAlertTitle(Detection detection, AlertRule rule) {
    switch (rule.alertType) {
      case AlertType.overdue:
        return 'Overdue Issue: ${detection.className}';
      case AlertType.critical:
        return 'Critical Issue Alert: ${detection.className}';
      case AlertType.reminder:
        return 'Reminder: Pending ${detection.className}';
      default:
        return 'Issue Alert: ${detection.className}';
    }
  }

  String _generateAlertMessage(Detection detection, AlertRule rule) {
    final duration = DateTime.now().difference(detection.timestamp);
    final durationText = _formatDuration(duration);

    return '''
${rule.description}

Issue Details:
- Type: ${detection.className}
- Location: ${detection.zone ?? 'Unknown'}, ${detection.wardName ?? 'Unknown'}
- Status: ${detection.status}
- Duration: $durationText
- Confidence: ${(detection.confidence * 100).toStringAsFixed(1)}%

This issue requires immediate attention from management.
    '''.trim();
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? "s" : ""}, ${duration.inHours % 24} hour${(duration.inHours % 24) != 1 ? "s" : ""}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? "s" : ""}, ${duration.inMinutes % 60} minute${(duration.inMinutes % 60) != 1 ? "s" : ""}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? "s" : ""}';
    }
  }

  Future<void> _sendNotifications(Alert alert, List<String> targetRoles) async {
    // In a real implementation, this would integrate with:
    // - Push notification service
    // - Email service
    // - SMS service
    // - In-app notification system
    
    print('🚨 ALERT: ${alert.title}');
    print('📱 Target Roles: ${targetRoles.join(", ")}');
    print('📝 Message: ${alert.message}');
    print('⏰ Created: ${alert.createdAt}');
    print('─' * 50);
  }

  List<Alert> getAlertsForUser(User user) {
    final userRole = user.userRole;
    
    return _alerts.where((alert) {
      if (alert.isResolved) return false;
      
      final targetRoles = alert.metadata?['targetRoles'] as List<String>? ?? [];
      return targetRoles.contains(userRole.value) || 
             RolePermissions.hasPermission(userRole, Permission.canReceiveAlerts);
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Alert> getUnreadAlertsForUser(User user) {
    return getAlertsForUser(user).where((alert) => !alert.isRead).toList();
  }

  int getUnreadAlertCount(User user) {
    return getUnreadAlertsForUser(user).length;
  }

  Future<void> markAlertAsRead(String alertId) async {
    final alertIndex = _alerts.indexWhere((alert) => alert.id == alertId);
    if (alertIndex != -1) {
      _alerts[alertIndex] = _alerts[alertIndex].copyWith(isRead: true);
    }
  }

  Future<void> resolveAlert(String alertId, String resolvedBy) async {
    final alertIndex = _alerts.indexWhere((alert) => alert.id == alertId);
    if (alertIndex != -1) {
      _alerts[alertIndex] = _alerts[alertIndex].copyWith(
        isResolved: true,
        resolvedAt: DateTime.now(),
        metadata: {
          ..._alerts[alertIndex].metadata ?? {},
          'resolvedBy': resolvedBy,
        },
      );
    }
  }

  void addCustomRule(AlertRule rule) {
    _alertRules.add(rule);
  }

  void removeRule(String ruleId) {
    _alertRules.removeWhere((rule) => rule.id == ruleId);
  }

  void updateRule(AlertRule updatedRule) {
    final index = _alertRules.indexWhere((rule) => rule.id == updatedRule.id);
    if (index != -1) {
      _alertRules[index] = updatedRule;
    }
  }

  List<Alert> getCriticalAlerts() {
    return _alerts.where((alert) => 
      !alert.isResolved && alert.isCritical
    ).toList();
  }

  List<Alert> getOverdueAlerts() {
    return _alerts.where((alert) => 
      !alert.isResolved && alert.isOverdue
    ).toList();
  }

  void clearResolvedAlerts() {
    _alerts.removeWhere((alert) => 
      alert.isResolved && 
      alert.resolvedAt != null && 
      DateTime.now().difference(alert.resolvedAt!).inDays > 7
    );
  }

  Map<String, int> getAlertStatistics() {
    return {
      'total': _alerts.length,
      'unresolved': _alerts.where((alert) => !alert.isResolved).length,
      'critical': getCriticalAlerts().length,
      'overdue': getOverdueAlerts().length,
      'today': _alerts.where((alert) => 
        alert.createdAt.isAfter(DateTime.now().subtract(Duration(days: 1)))
      ).length,
    };
  }
}