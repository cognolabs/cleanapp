import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cognoapp/core/alerts/alert_models.dart';
import 'package:cognoapp/domain/entities/user.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<NotificationChannel> _channels = [];
  final Map<String, List<String>> _userPreferences = {};
  
  void initialize() {
    _setupDefaultChannels();
  }

  void _setupDefaultChannels() {
    _channels.addAll([
      NotificationChannel(
        id: 'push',
        name: 'Push Notifications',
        type: 'push',
        isEnabled: true,
        settings: {
          'sound': true,
          'vibration': true,
          'badge': true,
        },
      ),
      NotificationChannel(
        id: 'email',
        name: 'Email Notifications',
        type: 'email',
        isEnabled: true,
        settings: {
          'daily_summary': true,
          'immediate_alerts': true,
        },
      ),
      NotificationChannel(
        id: 'in_app',
        name: 'In-App Notifications',
        type: 'in_app',
        isEnabled: true,
        settings: {
          'show_banner': true,
          'persist_duration': 5000,
        },
      ),
      NotificationChannel(
        id: 'sms',
        name: 'SMS Notifications',
        type: 'sms',
        isEnabled: false, // Disabled by default
        settings: {
          'critical_only': true,
        },
      ),
    ]);
  }

  Future<void> sendNotification({
    required Alert alert,
    required List<User> recipients,
    List<String>? channels,
  }) async {
    final targetChannels = channels ?? ['push', 'in_app'];
    
    for (final recipient in recipients) {
      final userChannels = _getUserEnabledChannels(recipient.id, targetChannels);
      
      for (final channelId in userChannels) {
        await _sendToChannel(channelId, alert, recipient);
      }
    }
  }

  List<String> _getUserEnabledChannels(String userId, List<String> requestedChannels) {
    final userPrefs = _userPreferences[userId] ?? [];
    
    return requestedChannels.where((channelId) {
      final channel = _channels.firstWhere(
        (ch) => ch.id == channelId,
        orElse: () => NotificationChannel(id: '', name: '', type: ''),
      );
      
      if (channel.id.isEmpty) return false;
      if (!channel.isEnabled) return false;
      
      // Check user preferences
      if (userPrefs.isNotEmpty && !userPrefs.contains(channelId)) return false;
      
      return true;
    }).toList();
  }

  Future<void> _sendToChannel(String channelId, Alert alert, User recipient) async {
    final channel = _channels.firstWhere((ch) => ch.id == channelId);
    
    switch (channel.type) {
      case 'push':
        await _sendPushNotification(alert, recipient, channel);
        break;
      case 'email':
        await _sendEmailNotification(alert, recipient, channel);
        break;
      case 'in_app':
        await _sendInAppNotification(alert, recipient, channel);
        break;
      case 'sms':
        await _sendSMSNotification(alert, recipient, channel);
        break;
      default:
        debugPrint('Unknown notification channel: ${channel.type}');
    }
  }

  Future<void> _sendPushNotification(Alert alert, User recipient, NotificationChannel channel) async {
    // In a real implementation, this would integrate with Firebase Cloud Messaging or similar
    final payload = {
      'title': alert.title,
      'body': _truncateMessage(alert.message, 100),
      'data': {
        'alertId': alert.id,
        'type': alert.type.value,
        'priority': alert.priority.value,
        'detectionId': alert.detectionId,
      },
    };

    debugPrint('📱 Push Notification to ${recipient.name}: ${jsonEncode(payload)}');
    
    // Simulate push notification delivery
    await Future.delayed(Duration(milliseconds: 100));
  }

  Future<void> _sendEmailNotification(Alert alert, User recipient, NotificationChannel channel) async {
    // In a real implementation, this would integrate with an email service like SendGrid or AWS SES
    final emailContent = _generateEmailContent(alert, recipient);
    
    debugPrint('📧 Email to ${recipient.email}:');
    debugPrint('Subject: ${emailContent['subject']}');
    debugPrint('Body: ${emailContent['body']}');
    
    // Simulate email sending
    await Future.delayed(Duration(milliseconds: 500));
  }

  Future<void> _sendInAppNotification(Alert alert, User recipient, NotificationChannel channel) async {
    // This would typically add to an in-app notification queue
    debugPrint('🔔 In-App Notification for ${recipient.name}: ${alert.title}');
    
    // In a real app, this might trigger a state update in a notification provider
    // or add to a local notification queue
    await Future.delayed(Duration(milliseconds: 50));
  }

  Future<void> _sendSMSNotification(Alert alert, User recipient, NotificationChannel channel) async {
    // Only send SMS for critical alerts if enabled
    final isCriticalOnly = channel.settings['critical_only'] as bool? ?? true;
    
    if (isCriticalOnly && !alert.isCritical) {
      return;
    }

    final smsContent = _generateSMSContent(alert);
    
    debugPrint('📱 SMS to ${recipient.phoneNumber}: $smsContent');
    
    // Simulate SMS sending
    await Future.delayed(Duration(milliseconds: 200));
  }

  String _truncateMessage(String message, int maxLength) {
    if (message.length <= maxLength) return message;
    return '${message.substring(0, maxLength - 3)}...';
  }

  Map<String, String> _generateEmailContent(Alert alert, User recipient) {
    final subject = '[${alert.priority.value.toUpperCase()}] ${alert.title}';
    
    final body = '''
Dear ${recipient.name},

${alert.message}

Alert Details:
- Priority: ${alert.priority.value.toUpperCase()}
- Type: ${alert.type.value}
- Created: ${alert.createdAt.toLocal().toString()}
- Detection ID: ${alert.detectionId ?? 'N/A'}

Please log into the CognoApp mobile application to view and resolve this issue.

Best regards,
CognoApp Alert System
    ''';

    return {
      'subject': subject,
      'body': body,
    };
  }

  String _generateSMSContent(Alert alert) {
    return 'CognoApp Alert: ${alert.title}. Location: ${alert.metadata?['zone'] ?? 'Unknown'}. Check app for details.';
  }

  Future<void> sendBulkNotification({
    required Alert alert,
    required List<String> userIds,
    List<String>? channels,
  }) async {
    // In a real implementation, you would fetch users by IDs
    debugPrint('📢 Bulk notification for alert: ${alert.title}');
    debugPrint('👥 Recipients: ${userIds.length} users');
    debugPrint('📱 Channels: ${channels?.join(", ") ?? "default"}');
  }

  Future<void> sendDailySummary(User recipient, List<Alert> alerts) async {
    if (alerts.isEmpty) return;

    final summary = _generateDailySummary(alerts);
    
    await _sendEmailNotification(
      Alert(
        id: 'daily_summary_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Daily Alert Summary',
        message: summary,
        type: AlertType.reminder,
        priority: AlertPriority.low,
        createdAt: DateTime.now(),
      ),
      recipient,
      _channels.firstWhere((ch) => ch.id == 'email'),
    );
  }

  String _generateDailySummary(List<Alert> alerts) {
    final critical = alerts.where((a) => a.isCritical).length;
    final overdue = alerts.where((a) => a.isOverdue).length;
    final total = alerts.length;

    return '''
Daily Alert Summary - ${DateTime.now().toLocal().toString().split(' ')[0]}

Total Alerts: $total
Critical Alerts: $critical
Overdue Alerts: $overdue

Please review and address these alerts in the CognoApp.
    ''';
  }

  void updateUserPreferences(String userId, List<String> enabledChannels) {
    _userPreferences[userId] = enabledChannels;
  }

  List<NotificationChannel> getAvailableChannels() {
    return List.unmodifiable(_channels);
  }

  NotificationChannel? getChannel(String channelId) {
    try {
      return _channels.firstWhere((ch) => ch.id == channelId);
    } catch (e) {
      return null;
    }
  }

  void updateChannelSettings(String channelId, Map<String, dynamic> settings) {
    final index = _channels.indexWhere((ch) => ch.id == channelId);
    if (index != -1) {
      _channels[index] = NotificationChannel(
        id: _channels[index].id,
        name: _channels[index].name,
        type: _channels[index].type,
        isEnabled: _channels[index].isEnabled,
        settings: {..._channels[index].settings, ...settings},
      );
    }
  }

  Map<String, dynamic> getNotificationStats() {
    return {
      'channels': _channels.length,
      'enabled_channels': _channels.where((ch) => ch.isEnabled).length,
      'user_preferences': _userPreferences.length,
    };
  }
}