import 'package:flutter/foundation.dart';
import 'package:cognoapp/core/alerts/alert_service.dart';
import 'package:cognoapp/core/alerts/alert_monitor.dart';
import 'package:cognoapp/core/alerts/alert_models.dart';
import 'package:cognoapp/domain/entities/user.dart';
import 'package:cognoapp/presentation/alerts/alerts_screen.dart';

class AlertsProvider extends ChangeNotifier {
  final AlertService _alertService = AlertService();
  final AlertMonitor _alertMonitor = AlertMonitor();

  List<Alert> _alerts = [];
  bool _isLoading = false;
  String _error = '';
  AlertFilter _currentFilter = AlertFilter.all;
  User? _currentUser;

  List<Alert> get alerts => _alerts;
  bool get isLoading => _isLoading;
  String get error => _error;
  AlertFilter get currentFilter => _currentFilter;

  int get totalAlertsCount => _alerts.length;
  int get unreadAlertsCount => _alerts.where((a) => !a.isRead && !a.isResolved).length;
  int get criticalAlertsCount => _alerts.where((a) => a.isCritical && !a.isResolved).length;
  int get overdueAlertsCount => _alerts.where((a) => a.isOverdue && !a.isResolved).length;
  int get todayAlertsCount => _alerts.where((a) => 
    a.createdAt.isAfter(DateTime.now().subtract(Duration(days: 1))) && !a.isResolved
  ).length;

  void setCurrentUser(User user) {
    _currentUser = user;
    loadAlerts();
  }

  Future<void> loadAlerts() async {
    if (_currentUser == null) return;

    _setLoading(true);
    _error = '';

    try {
      // Simulate API call delay
      await Future.delayed(Duration(milliseconds: 500));

      _alerts = _alertService.getAlertsForUser(_currentUser!);
      
      debugPrint('📋 Loaded ${_alerts.length} alerts for user: ${_currentUser!.name}');
      
    } catch (e) {
      _error = 'Failed to load alerts: $e';
      debugPrint('❌ Error loading alerts: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshAlerts() async {
    debugPrint('🔄 Refreshing alerts...');
    
    // Trigger immediate check in alert monitor
    await _alertMonitor.runImmediateCheck();
    
    // Reload alerts
    await loadAlerts();
  }

  List<Alert> getFilteredAlerts(AlertFilter filter) {
    switch (filter) {
      case AlertFilter.all:
        return _alerts.where((a) => !a.isResolved).toList();
      case AlertFilter.critical:
        return _alerts.where((a) => a.isCritical && !a.isResolved).toList();
      case AlertFilter.overdue:
        return _alerts.where((a) => a.isOverdue && !a.isResolved).toList();
      case AlertFilter.resolved:
        return _alerts.where((a) => a.isResolved).toList();
    }
  }

  void setFilter(AlertFilter filter) {
    if (_currentFilter != filter) {
      _currentFilter = filter;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String alertId) async {
    try {
      await _alertService.markAlertAsRead(alertId);
      
      final index = _alerts.indexWhere((a) => a.id == alertId);
      if (index != -1) {
        _alerts[index] = _alerts[index].copyWith(isRead: true);
        notifyListeners();
      }
      
      debugPrint('✅ Marked alert as read: $alertId');
      
    } catch (e) {
      _error = 'Failed to mark alert as read: $e';
      debugPrint('❌ Error marking alert as read: $e');
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final unreadAlerts = _alerts.where((a) => !a.isRead).toList();
      
      for (final alert in unreadAlerts) {
        await _alertService.markAlertAsRead(alert.id);
      }
      
      // Update local state
      for (int i = 0; i < _alerts.length; i++) {
        if (!_alerts[i].isRead) {
          _alerts[i] = _alerts[i].copyWith(isRead: true);
        }
      }
      
      notifyListeners();
      debugPrint('✅ Marked ${unreadAlerts.length} alerts as read');
      
    } catch (e) {
      _error = 'Failed to mark all alerts as read: $e';
      debugPrint('❌ Error marking all alerts as read: $e');
      notifyListeners();
    }
  }

  Future<void> resolveAlert(String alertId) async {
    if (_currentUser == null) return;

    try {
      await _alertService.resolveAlert(alertId, _currentUser!.id);
      
      final index = _alerts.indexWhere((a) => a.id == alertId);
      if (index != -1) {
        _alerts[index] = _alerts[index].copyWith(
          isResolved: true,
          resolvedAt: DateTime.now(),
        );
        notifyListeners();
      }
      
      debugPrint('✅ Resolved alert: $alertId');
      
    } catch (e) {
      _error = 'Failed to resolve alert: $e';
      debugPrint('❌ Error resolving alert: $e');
      notifyListeners();
    }
  }

  Alert? getAlertById(String alertId) {
    try {
      return _alerts.firstWhere((a) => a.id == alertId);
    } catch (e) {
      return null;
    }
  }

  List<Alert> getAlertsForDetection(String detectionId) {
    return _alerts.where((a) => a.detectionId == detectionId).toList();
  }

  Map<String, int> getAlertStatsByType() {
    final stats = <String, int>{};
    
    for (final alert in _alerts.where((a) => !a.isResolved)) {
      final type = alert.type.value;
      stats[type] = (stats[type] ?? 0) + 1;
    }
    
    return stats;
  }

  Map<String, int> getAlertStatsByPriority() {
    final stats = <String, int>{};
    
    for (final alert in _alerts.where((a) => !a.isResolved)) {
      final priority = alert.priority.value;
      stats[priority] = (stats[priority] ?? 0) + 1;
    }
    
    return stats;
  }

  List<Alert> getRecentAlerts({int limit = 10}) {
    final recent = List<Alert>.from(_alerts);
    recent.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return recent.take(limit).toList();
  }

  bool hasUnreadCriticalAlerts() {
    return _alerts.any((a) => !a.isRead && a.isCritical && !a.isResolved);
  }

  bool hasOverdueAlerts() {
    return _alerts.any((a) => a.isOverdue && !a.isResolved);
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void clearError() {
    if (_error.isNotEmpty) {
      _error = '';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // For debugging and testing
  void addMockAlert(Alert alert) {
    _alerts.add(alert);
    notifyListeners();
  }

  void clearAllAlerts() {
    _alerts.clear();
    notifyListeners();
  }
}