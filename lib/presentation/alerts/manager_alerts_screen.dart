import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cognoapp/presentation/alerts/alerts_provider.dart';
import 'package:cognoapp/presentation/alerts/widgets/alert_card.dart';
import 'package:cognoapp/presentation/alerts/widgets/alert_filter_chips.dart';
import 'package:cognoapp/presentation/alerts/alerts_screen.dart';
import 'package:cognoapp/core/alerts/alert_models.dart';
import 'package:cognoapp/presentation/authentication/auth_provider.dart';
import 'package:cognoapp/core/auth/roles.dart';
import 'package:cognoapp/config/routes.dart';

class ManagerAlertsScreen extends StatefulWidget {
  const ManagerAlertsScreen({Key? key}) : super(key: key);

  @override
  State<ManagerAlertsScreen> createState() => _ManagerAlertsScreenState();
}

class _ManagerAlertsScreenState extends State<ManagerAlertsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTimeRange = 'Today';
  String _selectedZone = 'All Zones';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlertsProvider>().loadAlerts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manager Dashboard - Alerts'),
        actions: [
          Consumer<AlertsProvider>(
            builder: (context, provider, child) {
              final unreadCount = provider.unreadAlertsCount;
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications_active),
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
          IconButton(
            icon: Icon(Icons.dashboard),
            onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.dashboard),
            tooltip: 'Go to Map Dashboard',
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'export', child: Text('Export Report')),
              PopupMenuItem(value: 'settings', child: Text('Alert Settings')),
              PopupMenuItem(value: 'rules', child: Text('Alert Rules')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildManagerControls(),
          Consumer<AlertsProvider>(
            builder: (context, provider, child) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    _buildManagerStatsRow(provider),
                    SizedBox(height: 12),
                    AlertFilterChips(
                      selectedFilter: provider.currentFilter,
                      onFilterChanged: provider.setFilter,
                    ),
                  ],
                ),
              );
            },
          ),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: [
              Tab(text: 'All Alerts'),
              Tab(text: 'Critical'),
              Tab(text: 'Overdue'),
              Tab(text: 'Assignments'),
              Tab(text: 'Resolved'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAlertsList(AlertFilter.all),
                _buildAlertsList(AlertFilter.critical),
                _buildAlertsList(AlertFilter.overdue),
                _buildAssignmentsList(),
                _buildAlertsList(AlertFilter.resolved),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "create_alert",
            onPressed: () => _showCreateAlertModal(context),
            child: Icon(Icons.add_alert),
            tooltip: 'Create Alert',
            mini: true,
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "refresh",
            onPressed: () => context.read<AlertsProvider>().refreshAlerts(),
            child: Icon(Icons.refresh),
            tooltip: 'Refresh Alerts',
          ),
        ],
      ),
    );
  }

  Widget _buildManagerControls() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedTimeRange,
              decoration: InputDecoration(
                labelText: 'Time Range',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: ['Today', 'This Week', 'This Month', 'All Time']
                  .map((range) => DropdownMenuItem(value: range, child: Text(range)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTimeRange = value!;
                });
                _applyFilters();
              },
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedZone,
              decoration: InputDecoration(
                labelText: 'Zone Filter',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: ['All Zones', 'Zone 1', 'Zone 2', 'Zone 3', 'Zone 4', 'Zone 5']
                  .map((zone) => DropdownMenuItem(value: zone, child: Text(zone)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedZone = value!;
                });
                _applyFilters();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagerStatsRow(AlertsProvider provider) {
    return SizedBox(
      height: 70,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildStatCard(
            'Total',
            provider.totalAlertsCount,
            Colors.blue,
            Icons.notifications,
          ),
          SizedBox(width: 8),
          _buildStatCard(
            'Critical',
            provider.criticalAlertsCount,
            Colors.red,
            Icons.priority_high,
          ),
          SizedBox(width: 8),
          _buildStatCard(
            'Overdue',
            provider.overdueAlertsCount,
            Colors.orange,
            Icons.schedule_send,
          ),
          SizedBox(width: 8),
          _buildStatCard(
            'Assignments',
            _getAssignmentsCount(provider),
            Colors.purple,
            Icons.assignment,
          ),
          SizedBox(width: 8),
          _buildStatCard(
            'Resolved',
            _getResolvedCount(provider),
            Colors.green,
            Icons.check_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          SizedBox(height: 2),
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
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
              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: AlertCard(
                  alert: alert,
                  onTap: () => _showManagerAlertDetails(context, alert),
                  onResolve: () => provider.resolveAlert(alert.id),
                  onMarkAsRead: () => provider.markAsRead(alert.id),
                  // Manager-specific actions
                  additionalActions: [
                    IconButton(
                      icon: Icon(Icons.assignment_ind),
                      onPressed: () => _showAssignTaskDialog(context, alert),
                      tooltip: 'Assign Task',
                    ),
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _showEditAlertDialog(context, alert),
                      tooltip: 'Edit Alert',
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAssignmentsList() {
    return Consumer<AlertsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        // Filter alerts that need assignment or are assigned
        final assignments = provider.alerts.where((alert) => 
          alert.metadata?['assignedTo'] != null || 
          alert.metadata?['needsAssignment'] == true
        ).toList();

        if (assignments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_turned_in,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No task assignments',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Assigned tasks will appear here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final alert = assignments[index];
            return Card(
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getPriorityColor(alert.priority),
                  child: Icon(Icons.assignment, color: Colors.white),
                ),
                title: Text(alert.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alert.message),
                    if (alert.metadata?['assignedTo'] != null)
                      Text(
                        'Assigned to: ${alert.metadata!['assignedTo']}',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) => _handleAssignmentAction(value, alert),
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'reassign', child: Text('Reassign')),
                    PopupMenuItem(value: 'status', child: Text('Update Status')),
                    PopupMenuItem(value: 'deadline', child: Text('Set Deadline')),
                  ],
                ),
                onTap: () => _showManagerAlertDetails(context, alert),
              ),
            );
          },
        );
      },
    );
  }

  void _showManagerAlertDetails(BuildContext context, Alert alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildManagerAlertDetailsModal(alert),
    );
  }

  Widget _buildManagerAlertDetailsModal(Alert alert) {
    return Container(
      padding: EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.8,
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
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(alert.priority),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  alert.priority.value.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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
          _buildDetailRow('Type', alert.type.value),
          _buildDetailRow('Created', _formatDateTime(alert.createdAt)),
          _buildDetailRow('Age', _formatDuration(alert.age)),
          if (alert.detectionId != null)
            _buildDetailRow('Detection ID', alert.detectionId!),
          if (alert.metadata?['zone'] != null)
            _buildDetailRow('Zone', alert.metadata!['zone']),
          if (alert.metadata?['assignedTo'] != null)
            _buildDetailRow('Assigned To', alert.metadata!['assignedTo']),
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
          _buildManagerActionButtons(alert),
        ],
      ),
    );
  }

  Widget _buildManagerActionButtons(Alert alert) {
    return Column(
      children: [
        Row(
          children: [
            if (!alert.isRead)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<AlertsProvider>().markAsRead(alert.id);
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.mark_email_read),
                  label: Text('Mark Read'),
                ),
              ),
            if (!alert.isRead) SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showAssignTaskDialog(context, alert),
                icon: Icon(Icons.assignment_ind),
                label: Text('Assign Task'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showEditAlertDialog(context, alert),
                icon: Icon(Icons.edit),
                label: Text('Edit Alert'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
              ),
            ),
            SizedBox(width: 8),
            if (!alert.isResolved)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<AlertsProvider>().resolveAlert(alert.id);
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.check_circle),
                  label: Text('Resolve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
          ],
        ),
      ],
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

  Color _getPriorityColor(AlertPriority priority) {
    switch (priority) {
      case AlertPriority.low:
        return Colors.green;
      case AlertPriority.medium:
        return Colors.orange;
      case AlertPriority.high:
        return Colors.red;
      case AlertPriority.critical:
        return Colors.purple;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  int _getAssignmentsCount(AlertsProvider provider) {
    return provider.alerts.where((alert) => 
      alert.metadata?['assignedTo'] != null || 
      alert.metadata?['needsAssignment'] == true
    ).length;
  }

  int _getResolvedCount(AlertsProvider provider) {
    return provider.alerts.where((alert) => alert.isResolved).length;
  }

  void _applyFilters() {
    // Implementation for applying time range and zone filters
    // This would integrate with the AlertsProvider to filter alerts
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _showExportDialog();
        break;
      case 'settings':
        _showAlertSettings();
        break;
      case 'rules':
        _showAlertRules();
        break;
    }
  }

  void _handleAssignmentAction(String action, Alert alert) {
    switch (action) {
      case 'reassign':
        _showAssignTaskDialog(context, alert);
        break;
      case 'status':
        _showUpdateStatusDialog(context, alert);
        break;
      case 'deadline':
        _showSetDeadlineDialog(context, alert);
        break;
    }
  }

  void _showCreateAlertModal(BuildContext context) {
    // Implementation for creating new alerts
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Create alert feature coming soon')),
    );
  }

  void _showAssignTaskDialog(BuildContext context, Alert alert) {
    // Implementation for assigning tasks
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Task assignment feature coming soon')),
    );
  }

  void _showEditAlertDialog(BuildContext context, Alert alert) {
    // Implementation for editing alerts
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit alert feature coming soon')),
    );
  }

  void _showUpdateStatusDialog(BuildContext context, Alert alert) {
    // Implementation for updating assignment status
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Update status feature coming soon')),
    );
  }

  void _showSetDeadlineDialog(BuildContext context, Alert alert) {
    // Implementation for setting deadlines
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Set deadline feature coming soon')),
    );
  }

  void _showExportDialog() {
    // Implementation for exporting reports
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export report feature coming soon')),
    );
  }

  void _showAlertSettings() {
    // Implementation for alert settings
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Alert settings feature coming soon')),
    );
  }

  void _showAlertRules() {
    // Implementation for alert rules
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Alert rules feature coming soon')),
    );
  }
}