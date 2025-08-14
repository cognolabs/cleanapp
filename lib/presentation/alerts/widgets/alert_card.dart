import 'package:flutter/material.dart';
import 'package:cognoapp/core/alerts/alert_models.dart';

class AlertCard extends StatelessWidget {
  final Alert alert;
  final VoidCallback? onTap;
  final VoidCallback? onResolve;
  final VoidCallback? onMarkAsRead;
  final List<Widget>? additionalActions;

  const AlertCard({
    Key? key,
    required this.alert,
    this.onTap,
    this.onResolve,
    this.onMarkAsRead,
    this.additionalActions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: alert.isCritical ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getBorderColor(),
          width: alert.isCritical ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 8),
              _buildMessage(),
              SizedBox(height: 12),
              _buildFooter(),
              if (!alert.isResolved) _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _buildPriorityIcon(),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alert.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: alert.isRead ? Colors.grey[700] : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2),
              Row(
                children: [
                  _buildTypeChip(),
                  SizedBox(width: 8),
                  _buildPriorityChip(),
                ],
              ),
            ],
          ),
        ),
        if (!alert.isRead)
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }

  Widget _buildPriorityIcon() {
    IconData icon;
    Color color;

    switch (alert.priority) {
      case AlertPriority.critical:
        icon = Icons.error;
        color = Colors.red;
        break;
      case AlertPriority.high:
        icon = Icons.warning;
        color = Colors.orange;
        break;
      case AlertPriority.medium:
        icon = Icons.info;
        color = Colors.blue;
        break;
      case AlertPriority.low:
        icon = Icons.info_outline;
        color = Colors.grey;
        break;
    }

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildTypeChip() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getTypeColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getTypeColor().withOpacity(0.3)),
      ),
      child: Text(
        alert.type.value.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: _getTypeColor(),
        ),
      ),
    );
  }

  Widget _buildPriorityChip() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getPriorityColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getPriorityColor().withOpacity(0.3)),
      ),
      child: Text(
        alert.priority.value.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: _getPriorityColor(),
        ),
      ),
    );
  }

  Widget _buildMessage() {
    // Extract first line of message for preview
    final lines = alert.message.split('\n');
    final preview = lines.first;

    return Text(
      preview,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[700],
        height: 1.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
        SizedBox(width: 4),
        Text(
          _formatTimestamp(),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
        if (alert.isOverdue) ...[
          SizedBox(width: 12),
          Icon(Icons.schedule, size: 14, color: Colors.red),
          SizedBox(width: 4),
          Text(
            'OVERDUE',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
        Spacer(),
        if (alert.detectionId != null) ...[
          Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
          SizedBox(width: 4),
          Text(
            'ID: ${alert.detectionId}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin: EdgeInsets.only(top: 12),
      child: Row(
        children: [
          if (!alert.isRead && onMarkAsRead != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onMarkAsRead,
                icon: Icon(Icons.mark_email_read, size: 16),
                label: Text('Mark Read'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          if (!alert.isRead && onResolve != null) SizedBox(width: 8),
          if (onResolve != null)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onResolve,
                icon: Icon(Icons.check, size: 16),
                label: Text('Resolve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          if (additionalActions != null && additionalActions!.isNotEmpty) ...[
            SizedBox(width: 8),
            ...additionalActions!,
          ],
        ],
      ),
    );
  }

  Color _getBorderColor() {
    if (alert.isCritical) return Colors.red;
    if (alert.isOverdue) return Colors.orange;
    return Colors.grey[300]!;
  }

  Color _getTypeColor() {
    switch (alert.type) {
      case AlertType.critical:
        return Colors.red;
      case AlertType.overdue:
        return Colors.orange;
      case AlertType.pending:
        return Colors.blue;
      case AlertType.reminder:
        return Colors.green;
    }
  }

  Color _getPriorityColor() {
    switch (alert.priority) {
      case AlertPriority.critical:
        return Colors.red;
      case AlertPriority.high:
        return Colors.orange;
      case AlertPriority.medium:
        return Colors.blue;
      case AlertPriority.low:
        return Colors.grey;
    }
  }

  String _formatTimestamp() {
    final now = DateTime.now();
    final difference = now.difference(alert.createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${alert.createdAt.day}/${alert.createdAt.month}/${alert.createdAt.year}';
    }
  }
}