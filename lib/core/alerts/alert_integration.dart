import 'package:flutter/foundation.dart';
import 'package:cognoapp/core/alerts/alert_service.dart';
import 'package:cognoapp/core/alerts/alert_monitor.dart';
import 'package:cognoapp/core/alerts/notification_service.dart';
import 'package:cognoapp/domain/entities/user.dart';
import 'package:cognoapp/domain/entities/detection.dart';
import 'package:cognoapp/core/auth/roles.dart';

class AlertIntegration {
  static final AlertIntegration _instance = AlertIntegration._internal();
  factory AlertIntegration() => _instance;
  AlertIntegration._internal();

  final AlertService _alertService = AlertService();
  final AlertMonitor _alertMonitor = AlertMonitor();
  final NotificationService _notificationService = NotificationService();

  bool _isInitialized = false;

  Future<void> initialize({
    Duration? checkInterval,
    List<User>? initialUsers,
  }) async {
    if (_isInitialized) {
      debugPrint('⚠️ Alert system already initialized');
      return;
    }

    try {
      debugPrint('🚀 Initializing Alert System...');

      // Initialize services
      _alertService.initialize();
      _notificationService.initialize();

      // Get manager users from provided list or use empty list
      final managerUsers = initialUsers?.where((user) => 
        user.hasPermission(Permission.canReceiveAlerts)
      ).toList() ?? [];

      // Initialize monitor
      _alertMonitor.initialize(
        checkInterval: checkInterval ?? Duration(minutes: 30),
        managerUsers: managerUsers,
      );

      // Start monitoring
      _alertMonitor.startMonitoring();

      _isInitialized = true;
      debugPrint('✅ Alert System initialized successfully');
      debugPrint('👥 Manager users: ${managerUsers.length}');
      debugPrint('⏰ Check interval: ${checkInterval?.inMinutes ?? 30} minutes');

    } catch (e, stackTrace) {
      debugPrint('❌ Failed to initialize Alert System: $e');
      if (kDebugMode) {
        debugPrint('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  Future<void> updateDetections(List<Detection> detections) async {
    if (!_isInitialized) {
      debugPrint('⚠️ Alert system not initialized, skipping detection update');
      return;
    }

    try {
      _alertMonitor.updateDetections(detections);
      debugPrint('🔄 Updated ${detections.length} detections in alert system');
    } catch (e) {
      debugPrint('❌ Error updating detections: $e');
    }
  }

  Future<void> updateUsers(List<User> users) async {
    if (!_isInitialized) {
      debugPrint('⚠️ Alert system not initialized, skipping user update');
      return;
    }

    try {
      _alertMonitor.updateManagerUsers(users);
      debugPrint('👥 Updated users in alert system');
    } catch (e) {
      debugPrint('❌ Error updating users: $e');
    }
  }

  Future<void> triggerImmediateCheck() async {
    if (!_isInitialized) {
      debugPrint('⚠️ Alert system not initialized');
      return;
    }

    try {
      await _alertMonitor.runImmediateCheck();
      debugPrint('⚡ Triggered immediate alert check');
    } catch (e) {
      debugPrint('❌ Error during immediate check: $e');
    }
  }

  Future<void> scheduleDailySummary() async {
    if (!_isInitialized) {
      debugPrint('⚠️ Alert system not initialized');
      return;
    }

    try {
      await _alertMonitor.sendDailySummary();
      debugPrint('📊 Sent daily summary');
    } catch (e) {
      debugPrint('❌ Error sending daily summary: $e');
    }
  }

  void updateConfiguration({
    Duration? checkInterval,
    bool? enablePushNotifications,
    bool? enableEmailNotifications,
    bool? enableSMSNotifications,
  }) {
    if (!_isInitialized) {
      debugPrint('⚠️ Alert system not initialized');
      return;
    }

    try {
      if (checkInterval != null) {
        _alertMonitor.updateCheckInterval(checkInterval);
      }

      if (enablePushNotifications != null) {
        _notificationService.updateChannelSettings('push', {
          'enabled': enablePushNotifications,
        });
      }

      if (enableEmailNotifications != null) {
        _notificationService.updateChannelSettings('email', {
          'enabled': enableEmailNotifications,
        });
      }

      if (enableSMSNotifications != null) {
        _notificationService.updateChannelSettings('sms', {
          'enabled': enableSMSNotifications,
        });
      }

      debugPrint('⚙️ Updated alert system configuration');
    } catch (e) {
      debugPrint('❌ Error updating configuration: $e');
    }
  }

  void addCustomAlertRule({
    required String name,
    required Duration triggerAfter,
    required List<String> targetRoles,
  }) {
    if (!_isInitialized) {
      debugPrint('⚠️ Alert system not initialized');
      return;
    }

    try {
      _alertMonitor.addCustomAlertRule(name, triggerAfter, targetRoles);
      debugPrint('➕ Added custom alert rule: $name');
    } catch (e) {
      debugPrint('❌ Error adding custom rule: $e');
    }
  }

  Map<String, dynamic> getSystemStatus() {
    if (!_isInitialized) {
      return {'initialized': false};
    }

    return {
      'initialized': true,
      'monitor': _alertMonitor.getStatus(),
      'notifications': _notificationService.getNotificationStats(),
      'alerts': _alertService.getAlertStatistics(),
    };
  }

  bool get isInitialized => _isInitialized;
  AlertService get alertService => _alertService;
  AlertMonitor get alertMonitor => _alertMonitor;
  NotificationService get notificationService => _notificationService;

  void dispose() {
    if (_isInitialized) {
      _alertMonitor.dispose();
      _isInitialized = false;
      debugPrint('🗑️ Alert system disposed');
    }
  }

  // Helper method to create mock data for testing
  void createMockData() {
    if (!_isInitialized) {
      debugPrint('⚠️ Alert system not initialized');
      return;
    }

    try {
      // Create mock detections
      final mockDetections = [
        Detection(
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
        ),
        Detection(
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
        ),
      ];

      // Create mock manager users
      final mockUsers = [
        User(
          id: 'user1',
          name: 'John Manager',
          email: 'john.manager@cogno.com',
          role: 'manager',
          department: 'Operations',
          phoneNumber: '+1234567890',
          createdAt: DateTime.now().subtract(Duration(days: 30)),
        ),
        User(
          id: 'user2',
          name: 'Jane Admin',
          email: 'jane.admin@cogno.com',
          role: 'admin',
          department: 'Administration',
          phoneNumber: '+1234567891',
          createdAt: DateTime.now().subtract(Duration(days: 60)),
        ),
      ];

      updateDetections(mockDetections);
      updateUsers(mockUsers);

      debugPrint('🎭 Created mock data for testing');
    } catch (e) {
      debugPrint('❌ Error creating mock data: $e');
    }
  }
}