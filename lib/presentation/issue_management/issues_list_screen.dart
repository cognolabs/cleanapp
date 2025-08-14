import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cognoapp/core/widgets/custom_snackbar.dart';
import 'package:cognoapp/presentation/issue_management/detection_provider.dart';
import 'package:cognoapp/config/theme.dart';
import 'package:cognoapp/data/models/detection_model.dart';
import 'package:cognoapp/core/utils/location_helper.dart';
import 'package:intl/intl.dart';

class IssuesListScreen extends StatefulWidget {
  const IssuesListScreen({Key? key}) : super(key: key);

  @override
  _IssuesListScreenState createState() => _IssuesListScreenState();
}

class _IssuesListScreenState extends State<IssuesListScreen> {
  String _selectedFilter = 'All';
  bool _isLoading = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _refreshIssues();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshIssues() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final detectionProvider = Provider.of<DetectionProvider>(context, listen: false);
      
      // Get current location
      final position = await LocationHelper.getCurrentPosition();
      
      // Fetch nearby issues
      await detectionProvider.fetchNearbyIssues(
        position.latitude,
        position.longitude,
        status: _selectedFilter != 'All' ? _selectedFilter.toLowerCase() : null,
      );
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(
          context: context,
          message: 'Failed to fetch issues: ${e.toString()}',
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return AppTheme.openStatusColor;
      case 'investigating':
        return AppTheme.investigatingStatusColor;
      case 'closed':
        return AppTheme.closedStatusColor;
      default:
        return Colors.blue;
    }
  }

  List<DetectionModel> _getFilteredIssues(List<DetectionModel> issues) {
    // First apply status filter
    var filteredIssues = _selectedFilter == 'All'
        ? issues
        : issues.where((issue) => issue.status.toLowerCase() == _selectedFilter.toLowerCase()).toList();
    
    // Then apply search filter if any
    if (_searchQuery.isNotEmpty) {
      filteredIssues = filteredIssues.where((issue) {
        final searchLower = _searchQuery.toLowerCase();
        return issue.id.toString().contains(searchLower) ||
            issue.className.toLowerCase().contains(searchLower) ||
            (issue.wardName != null && issue.wardName!.toLowerCase().contains(searchLower)) ||
            (issue.zone != null && issue.zone!.toLowerCase().contains(searchLower));
      }).toList();
    }
    
    return filteredIssues;
  }

  @override
  Widget build(BuildContext context) {
    final detectionProvider = Provider.of<DetectionProvider>(context);
    final allIssues = detectionProvider.issues;
    final filteredIssues = _getFilteredIssues(allIssues);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issues List'),
        actions: [
          // Get directions button
          IconButton(
            icon: const Icon(Icons.route),
            tooltip: 'Get directions',
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/issues/routes',
                arguments: _selectedFilter,
              );
            },
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshIssues,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search issues',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Filter chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Open'),
                const SizedBox(width: 8),
                _buildFilterChip('Investigating'),
                const SizedBox(width: 8),
                _buildFilterChip('Closed'),
              ],
            ),
          ),
          
          // Status count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Showing ${_selectedFilter.toLowerCase() == 'all' ? 'all' : _selectedFilter.toLowerCase()} issues',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${filteredIssues.length} ${filteredIssues.length == 1 ? 'issue' : 'issues'}',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Issues list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredIssues.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No issues found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_searchQuery.isNotEmpty || _selectedFilter != 'All')
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextButton.icon(
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Clear filters'),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                      _selectedFilter = 'All';
                                    });
                                  },
                                ),
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshIssues,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: filteredIssues.length,
                          itemBuilder: (context, index) {
                            final issue = filteredIssues[index];
                            return _buildIssueCard(issue);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      avatar: isSelected ? Icon(
        Icons.check,
        size: 16,
        color: AppTheme.primaryColor,
      ) : null,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      selectedColor: AppTheme.primaryColor.withOpacity(0.1),
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
    );
  }

  Widget _buildIssueCard(DetectionModel issue) {
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');
    final formattedDate = dateFormat.format(issue.timestamp);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/issues/details',
            arguments: issue.id,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Status indicator and ID
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getStatusColor(issue.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '#${issue.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(issue.status),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          issue.status.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Right: Issue details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            issue.className,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(issue.status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            issue.status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (issue.wardName != null || issue.zone != null)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              [
                                if (issue.wardName != null) 'Ward: ${issue.wardName}',
                                if (issue.zone != null) 'Zone: ${issue.zone}',
                              ].join(' • '),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Resolution button (conditional)
                        if (issue.status.toLowerCase() != 'closed')
                          OutlinedButton.icon(
                            icon: const Icon(Icons.check_circle_outline, size: 16),
                            label: const Text('Resolve'),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/issues/resolution',
                                arguments: issue.id,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              minimumSize: const Size(0, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        const SizedBox(width: 8),
                        // View details button
                        OutlinedButton.icon(
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: const Text('Details'),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/issues/details',
                              arguments: issue.id,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
