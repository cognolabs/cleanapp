enum AlertType {
  overdue('overdue'),
  critical('critical'),
  pending('pending'),
  reminder('reminder');

  const AlertType(this.value);
  final String value;

  static AlertType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'overdue':
        return AlertType.overdue;
      case 'critical':
        return AlertType.critical;
      case 'pending':
        return AlertType.pending;
      case 'reminder':
        return AlertType.reminder;
      default:
        return AlertType.pending;
    }
  }
}

enum AlertPriority {
  low('low'),
  medium('medium'),
  high('high'),
  critical('critical');

  const AlertPriority(this.value);
  final String value;

  static AlertPriority fromString(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return AlertPriority.low;
      case 'medium':
        return AlertPriority.medium;
      case 'high':
        return AlertPriority.high;
      case 'critical':
        return AlertPriority.critical;
      default:
        return AlertPriority.medium;
    }
  }
}

class Alert {
  final String id;
  final String title;
  final String message;
  final AlertType type;
  final AlertPriority priority;
  final String? detectionId;
  final String? relatedUserId;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final bool isRead;
  final bool isResolved;
  final Map<String, dynamic>? metadata;

  Alert({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    this.detectionId,
    this.relatedUserId,
    required this.createdAt,
    this.resolvedAt,
    this.isRead = false,
    this.isResolved = false,
    this.metadata,
  });

  Alert copyWith({
    String? id,
    String? title,
    String? message,
    AlertType? type,
    AlertPriority? priority,
    String? detectionId,
    String? relatedUserId,
    DateTime? createdAt,
    DateTime? resolvedAt,
    bool? isRead,
    bool? isResolved,
    Map<String, dynamic>? metadata,
  }) {
    return Alert(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      detectionId: detectionId ?? this.detectionId,
      relatedUserId: relatedUserId ?? this.relatedUserId,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      isRead: isRead ?? this.isRead,
      isResolved: isResolved ?? this.isResolved,
      metadata: metadata ?? this.metadata,
    );
  }

  Duration get age => DateTime.now().difference(createdAt);
  bool get isOverdue => age.inHours >= 24 && !isResolved;
  bool get isCritical => priority == AlertPriority.critical || type == AlertType.critical;
}

class AlertRule {
  final String id;
  final String name;
  final String description;
  final Duration triggerAfter;
  final AlertType alertType;
  final AlertPriority priority;
  final List<String> targetRoles;
  final bool isActive;
  final Map<String, dynamic>? conditions;

  AlertRule({
    required this.id,
    required this.name,
    required this.description,
    required this.triggerAfter,
    required this.alertType,
    required this.priority,
    required this.targetRoles,
    this.isActive = true,
    this.conditions,
  });

  bool shouldTrigger(DateTime issueCreatedAt, String status) {
    if (!isActive || status == 'resolved' || status == 'closed') {
      return false;
    }

    final timeSinceCreation = DateTime.now().difference(issueCreatedAt);
    return timeSinceCreation >= triggerAfter;
  }
}

class NotificationChannel {
  final String id;
  final String name;
  final String type; // 'email', 'push', 'sms', 'in_app'
  final bool isEnabled;
  final Map<String, dynamic> settings;

  NotificationChannel({
    required this.id,
    required this.name,
    required this.type,
    this.isEnabled = true,
    this.settings = const {},
  });
}