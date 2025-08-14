import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cognoapp/core/alerts/alert_service.dart';
import 'package:cognoapp/core/alerts/notification_service.dart';
import 'package:cognoapp/domain/entities/detection.dart';
import 'package:cognoapp/domain/entities/user.dart';
import 'package:cognoapp/core/auth/roles.dart';
import 'package:cognoapp/core/alerts/alert_models.dart';

class AlertMonitor {
  static final AlertMonitor _instance = AlertMonitor._internal();
  factory AlertMonitor() => _instance;
  AlertMonitor._internal();

  final AlertService _alertService = AlertService();
  final NotificationService _notificationService = NotificationService();

  Timer? _monitorTimer;
  bool _isRunning = false;
  Duration _checkInterval = Duration(minutes: 30); // Check every 30 minutes

  // Mock data - in real app, this would come from repositories
  List<Detection> _openDetections = [];
  List<User> _managerUsers = [];

  void initialize({
    Duration? checkInterval,
    required List<User> managerUsers,
  }) {
    _checkInterval = checkInterval ?? Duration(minutes: 30);
    _managerUsers = managerUsers.where((user) => 
      user.hasPermission(Permission.canReceiveAlerts)
    ).toList();

    _alertService.initialize();
    _notificationService.initialize();
    
    debugPrint('🔍 Alert Monitor initialized');
    debugPrint('⏰ Check interval: ${_checkInterval.inMinutes} minutes');
    debugPrint('👥 Manager users: ${_managerUsers.length}');
  }

  void startMonitoring() {
    if (_isRunning) {
      debugPrint('⚠️ Alert monitor is already running');
      return;
    }

    _isRunning = true;
    debugPrint('🚀 Starting alert monitor...');

    // Run initial check
    _performCheck();

    // Schedule periodic checks
    _monitorTimer = Timer.periodic(_checkInterval, (timer) {
      _performCheck();
    });

    debugPrint('✅ Alert monitor started successfully');
  }

  void stopMonitoring() {
    if (!_isRunning) {
      debugPrint('⚠️ Alert monitor is not running');
      return;
    }

    _isRunning = false;
    _monitorTimer?.cancel();
    _monitorTimer = null;

    debugPrint('🛑 Alert monitor stopped');
  }

  Future<void> _performCheck() async {
    if (!_isRunning) return;

    try {
      debugPrint('🔍 Performing alert check at ${DateTime.now()}');

      // In a real app, this would fetch from a repository or API
      await _fetchOpenDetections();
      
      // Check for overdue issues
      await _alertService.checkOverdueIssues(_openDetections);

      // Send notifications for new alerts
      await _processNewAlerts();

      // Clean up old resolved alerts
      _alertService.clearResolvedAlerts();

      final stats = _alertService.getAlertStatistics();
      debugPrint('📊 Alert stats: ${stats}');

    } catch (e, stackTrace) {
      debugPrint('❌ Error during alert check: $e');
      if (kDebugMode) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  Future<void> _fetchOpenDetections() async {
    // In a real implementation, this would fetch from your data source
    // For now, we'll simulate this with mock data
    
    // Mock detection that's been open for more than 24 hours
    final oldDetection = Detection(
      id: 1001,
      timestamp: DateTime.now().subtract(Duration(hours: 25)),
      latitude: 25.4495,
      longitude: 81.8397,
      className: 'Garbage',
      modelType: 'YOLOv8',
      confidence: 0.95,
      status: 'open',
      zone: 'Zone 1',
      wardName: 'Civil Lines',
    );

    // Mock detection that's been open for 13 hours (critical)
    final criticalDetection = Detection(
      id: 1002,
      timestamp: DateTime.now().subtract(Duration(hours: 13)),
      latitude: 25.4520,
      longitude: 81.8420,
      className: 'Pothole',
      modelType: 'YOLOv8',
      confidence: 0.88,
      status: 'open',
      zone: 'Zone 2',
      wardName: 'Mall Road',
    );

    _openDetections = [oldDetection, criticalDetection];
  }

  Future<void> _processNewAlerts() async {
    final allAlerts = _alertService.alerts;
    final newAlerts = allAlerts.where((alert) => 
      !alert.isResolved && 
      DateTime.now().difference(alert.createdAt).inMinutes < _checkInterval.inMinutes
    ).toList();

    if (newAlerts.isEmpty) {
      debugPrint('📬 No new alerts to process');
      return;
    }

    debugPrint('🚨 Processing ${newAlerts.length} new alerts');

    for (final alert in newAlerts) {
      await _sendAlertNotifications(alert);
    }
  }

  Future<void> _sendAlertNotifications(alert) async {
    // Determine which users should receive this alert
    final targetRoles = alert.metadata?['targetRoles'] as List<String>? ?? [];
    final recipientUsers = _managerUsers.where((user) => 
      targetRoles.contains(user.role) || user.hasPermission(Permission.canReceiveAlerts)
    ).toList();

    if (recipientUsers.isEmpty) {
      debugPrint('⚠️ No recipient users found for alert: ${alert.id}');
      return;
    }

    // Send notifications based on alert priority
    List<String> channels = ['in_app'];
    
    if (alert.isCritical) {
      channels.addAll(['push', 'email']);
      // For critical alerts, also send SMS if user has phone number
      if (recipientUsers.any((user) => user.phoneNumber?.isNotEmpty == true)) {
        channels.add('sms');
      }
    } else if (alert.priority.value == 'high') {
      channels.add('push');
    }

    await _notificationService.sendNotification(
      alert: alert,
      recipients: recipientUsers,
      channels: channels,
    );

    debugPrint('📤 Sent notifications for alert: ${alert.id} to ${recipientUsers.length} users');
  }

  // Manual trigger for immediate check
  Future<void> runImmediateCheck() async {
    debugPrint('⚡ Running immediate alert check...');
    await _performCheck();
  }

  // Update detection data (called when detections are updated)
  void updateDetections(List<Detection> detections) {
    _openDetections = detections.where((d) => 
      !['resolved', 'closed', 'completed'].contains(d.status.toLowerCase())
    ).toList();
    
    debugPrint('🔄 Updated ${_openDetections.length} open detections');
  }

  // Update manager users (called when user roles change)
  void updateManagerUsers(List<User> users) {
    _managerUsers = users.where((user) => 
      user.hasPermission(Permission.canReceiveAlerts)
    ).toList();
    
    debugPrint('👥 Updated ${_managerUsers.length} manager users');
  }

  // Schedule daily summary
  Future<void> sendDailySummary() async {
    final alerts = _alertService.alerts.where((alert) => 
      alert.createdAt.isAfter(DateTime.now().subtract(Duration(days: 1)))
    ).toList();

    if (alerts.isEmpty) {
      debugPrint('📝 No alerts for daily summary');
      return;
    }

    for (final user in _managerUsers) {
      await _notificationService.sendDailySummary(user, alerts);
    }

    debugPrint('📊 Sent daily summary to ${_managerUsers.length} managers');
  }

  // Configuration methods
  void updateCheckInterval(Duration interval) {
    _checkInterval = interval;
    
    if (_isRunning) {
      stopMonitoring();
      startMonitoring();
    }
    
    debugPrint('⏰ Updated check interval to ${interval.inMinutes} minutes');
  }

  void addCustomAlertRule(String name, Duration triggerAfter, List<String> targetRoles) {
    final rule = AlertRule(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: 'Custom alert rule: $name',
      triggerAfter: triggerAfter,
      alertType: AlertType.reminder,
      priority: AlertPriority.medium,
      targetRoles: targetRoles,
    );

    _alertService.addCustomRule(rule);
    debugPrint('➕ Added custom alert rule: $name');
  }

  // Status and diagnostics
  bool get isRunning => _isRunning;
  Duration get checkInterval => _checkInterval;
  int get openDetectionsCount => _openDetections.length;
  int get managerUsersCount => _managerUsers.length;

  Map<String, dynamic> getStatus() {
    return {
      'isRunning': _isRunning,
      'checkIntervalMinutes': _checkInterval.inMinutes,
      'openDetections': _openDetections.length,
      'managerUsers': _managerUsers.length,
      'totalAlerts': _alertService.alerts.length,
      'unresolvedAlerts': _alertService.alerts.where((a) => !a.isResolved).length,
      'criticalAlerts': _alertService.getCriticalAlerts().length,
      'overdueAlerts': _alertService.getOverdueAlerts().length,
      'lastCheckTime': DateTime.now().toIso8601String(),
    };
  }

  void dispose() {
    stopMonitoring();
    debugPrint('🗑️ Alert monitor disposed');
  }
}