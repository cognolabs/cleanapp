import 'package:flutter/material.dart';
import 'package:cognoapp/presentation/alerts/alerts_screen.dart';

class AlertFilterChips extends StatelessWidget {
  final AlertFilter selectedFilter;
  final Function(AlertFilter) onFilterChanged;

  const AlertFilterChips({
    Key? key,
    required this.selectedFilter,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AlertFilter.values.map((filter) {
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_getFilterLabel(filter)),
              selected: selectedFilter == filter,
              onSelected: (selected) {
                if (selected) {
                  onFilterChanged(filter);
                }
              },
              selectedColor: _getFilterColor(filter).withOpacity(0.2),
              checkmarkColor: _getFilterColor(filter),
              side: BorderSide(
                color: selectedFilter == filter 
                    ? _getFilterColor(filter)
                    : Colors.grey[300]!,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getFilterLabel(AlertFilter filter) {
    switch (filter) {
      case AlertFilter.all:
        return 'All Alerts';
      case AlertFilter.critical:
        return 'Critical';
      case AlertFilter.overdue:
        return 'Overdue';
      case AlertFilter.resolved:
        return 'Resolved';
    }
  }

  Color _getFilterColor(AlertFilter filter) {
    switch (filter) {
      case AlertFilter.all:
        return Colors.blue;
      case AlertFilter.critical:
        return Colors.red;
      case AlertFilter.overdue:
        return Colors.orange;
      case AlertFilter.resolved:
        return Colors.green;
    }
  }
}