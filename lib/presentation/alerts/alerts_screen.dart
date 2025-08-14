import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cognoapp/presentation/alerts/alerts_provider.dart';
import 'package:cognoapp/presentation/alerts/widgets/alert_card.dart';
import 'package:cognoapp/presentation/alerts/widgets/alert_filter_chips.dart';
import 'package:cognoapp/core/alerts/alert_models.dart';
import 'package:cognoapp/presentation/common_widgets/bottom_navigation.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({Key? key}) : super(key: key);

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlertsProvider>().loadAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alerts'),
        actions: [
          Consumer<AlertsProvider>(
            builder: (context, provider, child) {
              final unreadCount = provider.unreadAlertsCount;
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications),
                    onPressed: () => provider.markAllAsRead(),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Consumer<AlertsProvider>(
            builder: (context, provider, child) {
              return Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatsRow(provider),
                    SizedBox(height: 16),
                    AlertFilterChips(
                      selectedFilter: provider.currentFilter,
                      onFilterChanged: provider.setFilter,
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: Consumer<AlertsProvider>(
              builder: (context, provider, child) {
                return _buildAlertsList(provider.currentFilter);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<AlertsProvider>().refreshAlerts(),
        child: Icon(Icons.refresh),
        tooltip: 'Refresh Alerts',
      ),
      bottomNavigationBar: ModernBottomNavigation(
        currentIndex: 1, // Alerts index
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else if (index == 1) {
            // Already on alerts
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/issues/list');
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/profile');
          }
        },
        items: const [
          BottomNavigationItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: 'Dashboard',
          ),
          BottomNavigationItem(
            icon: Icons.notifications_outlined,
            activeIcon: Icons.notifications,
            label: 'Alerts',
          ),
          BottomNavigationItem(
            icon: Icons.list_alt_outlined,
            activeIcon: Icons.list_alt,
            label: 'Issues',
          ),
          BottomNavigationItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(AlertsProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatCard(
          'Total',
          provider.totalAlertsCount,
          Colors.blue,
          Icons.notifications,
        ),
        _buildStatCard(
          'Critical',
          provider.criticalAlertsCount,
          Colors.red,
          Icons.warning,
        ),
        _buildStatCard(
          'Overdue',
          provider.overdueAlertsCount,
          Colors.orange,
          Icons.schedule,
        ),
        _buildStatCard(
          'Today',
          provider.todayAlertsCount,
          Colors.green,
          Icons.today,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList(AlertFilter filter) {
    return Consumer<AlertsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        final alerts = provider.getFilteredAlerts(filter);

        if (alerts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No ${filter.name} alerts',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _getEmptyMessage(filter),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: provider.refreshAlerts,
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return AlertCard(
                alert: alert,
                onTap: () => _showAlertDetails(context, alert),
                onResolve: () => provider.resolveAlert(alert.id),
                onMarkAsRead: () => provider.markAsRead(alert.id),
              );
            },
          ),
        );
      },
    );
  }

  String _getEmptyMessage(AlertFilter filter) {
    switch (filter) {
      case AlertFilter.all:
        return 'All alerts will appear here';
      case AlertFilter.critical:
        return 'Critical alerts requiring immediate attention';
      case AlertFilter.overdue:
        return 'Issues overdue for more than 24 hours';
      case AlertFilter.resolved:
        return 'Resolved alerts from the past week';
      default:
        return 'No alerts found';
    }
  }

  void _showAlertDetails(BuildContext context, Alert alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildAlertDetailsModal(alert),
    );
  }

  Widget _buildAlertDetailsModal(Alert alert) {
    return Container(
      padding: EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  alert.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildDetailRow('Priority', alert.priority.value.toUpperCase()),
          _buildDetailRow('Type', alert.type.value),
          _buildDetailRow('Created', alert.createdAt.toString()),
          if (alert.detectionId != null)
            _buildDetailRow('Detection ID', alert.detectionId!),
          SizedBox(height: 16),
          Text(
            'Message',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Text(alert.message),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              if (!alert.isRead)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<AlertsProvider>().markAsRead(alert.id);
                      Navigator.pop(context);
                    },
                    child: Text('Mark as Read'),
                  ),
                ),
              if (!alert.isRead) SizedBox(width: 8),
              if (!alert.isResolved)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<AlertsProvider>().resolveAlert(alert.id);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: Text('Resolve'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

}

enum AlertFilter {
  all,
  critical,
  overdue,
  resolved,
}