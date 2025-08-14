import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:cognoapp/core/widgets/custom_snackbar.dart';
import 'package:cognoapp/core/utils/location_helper.dart';
import 'package:cognoapp/presentation/issue_management/detection_provider.dart';
import 'package:cognoapp/presentation/authentication/auth_provider.dart';
import 'package:cognoapp/presentation/zone_ward/zone_ward_provider.dart';
import 'package:cognoapp/config/theme.dart';
import 'package:cognoapp/data/models/detection_model.dart';
import 'package:cognoapp/presentation/common_widgets/app_bar.dart';
import 'package:cognoapp/presentation/common_widgets/app_card.dart';
import 'package:cognoapp/presentation/common_widgets/app_button.dart';
import 'package:cognoapp/presentation/common_widgets/bottom_navigation.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  String _selectedFilter = 'All';
  bool _isRefreshing = false;
  int _currentNavIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _filterSlideAnimation;
  late Animation<double> _mapFadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _filterSlideAnimation = Tween<double>(begin: -50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );
    
    _mapFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });
    
    try {
      final position = await LocationHelper.getCurrentPosition();
      
      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });
      
      // Move map to current location
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        15.0,
      );
      
      // Fetch nearby issues
      await _fetchNearbyIssues();
      
      // Start animation after data is loaded
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      
      if (mounted) {
        CustomSnackbar.showError(
          context: context,
          message: 'Failed to get current location: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _fetchNearbyIssues() async {
    if (_currentPosition == null) {
      CustomSnackbar.showError(
        context: context,
        message: 'Location is unavailable. Cannot fetch nearby issues.',
      );
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    try {
      final detectionProvider = Provider.of<DetectionProvider>(context, listen: false);
      
      await detectionProvider.fetchNearbyIssues(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        status: _selectedFilter != 'All' ? _selectedFilter.toLowerCase() : null,
      );
      
      if (mounted) {
        if (detectionProvider.issues.isEmpty) {
          CustomSnackbar.show(
            context: context,
            message: 'No issues found in your area',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(
          context: context,
          message: 'Failed to fetch issues: ${e.toString()}',
        );
      }
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }
  

  // Navigate to zone/ward selection screen
  void _goToZoneWardSelection() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final zoneWardProvider = Provider.of<ZoneWardProvider>(context, listen: false);
    
    // Initialize the zone/ward provider
    zoneWardProvider.initialize();
    
    // Request zone/ward selection
    authProvider.requestZoneWardSelection();
    
    // Navigate to the selection screen
    Navigator.pushNamed(context, '/zone-ward-selection');
  }

  Color _getMarkerColor(String status) {
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

  void _showIssueBottomSheet(BuildContext context, DetectionModel issue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.only(top: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.neutral300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _getMarkerColor(issue.status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            issue.status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Title with issue type
                    Text(
                      'Issue #${issue.id}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      issue.className,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Issue details
                    Row(
                      children: [
                        _buildInfoItem(Icons.calendar_today, 
                          'Detected on', issue.timestamp.toString().substring(0, 10)),
                        const SizedBox(width: 16),
                        _buildInfoItem(Icons.access_time, 
                          'Time', issue.timestamp.toString().substring(11, 16)),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        _buildInfoItem(Icons.percent, 
                          'Confidence', '${(issue.confidence * 100).toStringAsFixed(1)}%'),
                        const SizedBox(width: 16),
                        if (issue.wardName != null)
                          _buildInfoItem(Icons.domain, 'Ward', issue.wardName!),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        _buildInfoItem(Icons.location_on, 
                          'Location', '${issue.latitude.toStringAsFixed(4)}, ${issue.longitude.toStringAsFixed(4)}'),
                      ],
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // View Details button
                    AppButton(
                      text: 'View Details',
                      icon: Icons.arrow_forward,
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          context,
                          '/issues/details',
                          arguments: issue.id,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildInfoItem(IconData icon, String title, String value) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detectionProvider = Provider.of<DetectionProvider>(context);
    final issues = detectionProvider.issues;
    final authProvider = Provider.of<AuthProvider>(context);
    final zoneWardProvider = Provider.of<ZoneWardProvider>(context);
    final displayName = authProvider.currentUser?.name ?? 'User';
    final isAdmin = authProvider.isAdmin;
    
    // Get current zone and ward info for display
    final currentZoneId = zoneWardProvider.selectedZoneId;
    final currentWardId = zoneWardProvider.selectedWardId;
    final hasZoneWard = currentZoneId != null && currentWardId != null;
    
    return Scaffold(
      appBar: ModernAppBar(
        title: 'Dashboard',
        showBackButton: false,
        backgroundColor: Colors.white,
        centerTitle: false,
        actions: [
          // Zone/Ward info button for admin users
          if (isAdmin)
            _buildZoneWardInfoButton(hasZoneWard, currentZoneId, currentWardId),
          // Camera button for all users
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/camera/detection');
            },
            icon: const Icon(Icons.camera_alt),
            tooltip: 'Detection Camera',
          ),
          // Profile button
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(displayName, authProvider, isAdmin),
      body: Column(
        children: [
          // Filter chips
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_filterSlideAnimation.value, 0),
                child: child,
              );
            },
            child: Container(
              height: 60,
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
          ),
          
          // Status count with shadow
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _mapFadeAnimation.value,
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedFilter.toLowerCase() == 'all' 
                        ? 'Showing all issues' 
                        : 'Showing ${_selectedFilter.toLowerCase()} issues',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      issues.isEmpty ? 'No issues' : '${issues.length} issues',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Map
          Expanded(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _mapFadeAnimation.value,
                  child: child,
                );
              },
              child: Stack(
                children: [
                  if (_isLoadingLocation)
                    const Center(
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                        ),
                      ),
                    )
                  else
                    FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      zoom: 15.0,
                      center: LatLng(
                        _currentPosition?.latitude ?? 20.5937,
                        _currentPosition?.longitude ?? 78.9629
                      ),
                    ),
                    children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.cognoclean.app',
                        ),
                        // Current location marker
                        if (_currentPosition != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                width: 60.0,
                                height: 60.0,
                                point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                builder: (context) => Column(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.my_location,
                                          color: AppTheme.primaryColor,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        // Issue markers
                        MarkerLayer(
                          markers: issues
                              .where((issue) => _selectedFilter == 'All' || issue.status.toLowerCase() == _selectedFilter.toLowerCase())
                              .map((issue) => Marker(
                                    width: 50.0,
                                    height: 50.0,
                                    point: LatLng(issue.latitude, issue.longitude),
                                    builder: (context) => GestureDetector(
                                      onTap: () {
                                        _showIssueBottomSheet(context, issue);
                                      },
                                      child: Column(
                                        children: [
                                          // Custom marker with shadow
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.2),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Icon(
                                                Icons.location_on,
                                                color: _getMarkerColor(issue.status),
                                                size: 22,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  
                  // Refresh indicator
                  if (_isRefreshing)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  
                  // Floating buttons
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Column(
                      children: [
                        // Refresh button
                        _buildFloatingActionButton(
                          icon: Icons.refresh,
                          onPressed: _isRefreshing ? null : _fetchNearbyIssues,
                          heroTag: 'refreshButton',
                          tooltip: 'Refresh issues',
                          mini: true,
                        ),
                        const SizedBox(height: 8),
                        
                        // My location button
                        _buildFloatingActionButton(
                          icon: Icons.my_location,
                          onPressed: () {
                            if (_currentPosition != null) {
                              _mapController.move(
                                LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                15.0,
                              );
                            }
                          },
                          heroTag: 'myLocationButton',
                          tooltip: 'My location',
                          mini: true,
                        ),
                        const SizedBox(height: 8),
                        
                        // Route directions button
                        _buildFloatingActionButton(
                          icon: Icons.route,
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/issues/routes',
                              arguments: _selectedFilter,
                            );
                          },
                          heroTag: 'routeButton',
                          tooltip: 'Get directions',
                          mini: true,
                        ),
                        const SizedBox(height: 8),
                        
                        // List view button
                        _buildFloatingActionButton(
                          icon: Icons.format_list_bulleted,
                          onPressed: () {
                            Navigator.pushNamed(context, '/issues/list');
                          },
                          heroTag: 'listViewButton',
                          tooltip: 'List view',
                          mini: true,
                        ),
                        
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ModernBottomNavigation(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });
          
          // Handle navigation
          if (index == 0) {
            // Already on dashboard
          } else if (index == 1) {
            Navigator.pushNamed(context, '/issues/list');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/profile');
          }
        },
        items: const [
          BottomNavigationItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: 'Dashboard',
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

  // Build zone/ward info button
  Widget _buildZoneWardInfoButton(bool hasZoneWard, int? zoneId, int? wardId) {
    return GestureDetector(
      onTap: _goToZoneWardSelection,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: hasZoneWard 
            ? AppTheme.primaryColor.withOpacity(0.1) 
            : AppTheme.warningColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasZoneWard 
              ? AppTheme.primaryColor.withOpacity(0.2) 
              : AppTheme.warningColor.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasZoneWard ? Icons.location_on : Icons.location_off,
              size: 16,
              color: hasZoneWard ? AppTheme.primaryColor : AppTheme.warningColor,
            ),
            const SizedBox(width: 4),
            Text(
              hasZoneWard 
                ? 'Z${zoneId}-W${wardId}' 
                : 'Set Zone',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: hasZoneWard ? AppTheme.primaryColor : AppTheme.warningColor,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.edit,
              size: 12,
              color: hasZoneWard ? AppTheme.primaryColor : AppTheme.warningColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String heroTag,
    String? tooltip,
    bool mini = false,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return FloatingActionButton(
      heroTag: heroTag,
      mini: mini,
      backgroundColor: backgroundColor ?? Colors.white,
      foregroundColor: foregroundColor ?? AppTheme.primaryColor,
      elevation: 4,
      onPressed: onPressed,
      tooltip: tooltip,
      child: Icon(icon),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 14,
      ),
      backgroundColor: Colors.white,
      selectedColor: AppTheme.primaryColor.withOpacity(0.1),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryColor : AppTheme.neutral300,
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
        });
        _fetchNearbyIssues();
      },
    );
  }
  
  Widget _buildDrawer(String displayName, AuthProvider authProvider, bool isAdmin) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // User info section
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Name and email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authProvider.currentUser?.email ?? '',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isAdmin)
                          const Text(
                            'Admin',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(),
            
            // Menu items
            ListTile(
              leading: const Icon(Icons.dashboard, color: AppTheme.primaryColor),
              title: const Text('Dashboard'),
              selected: true,
              selectedColor: AppTheme.primaryColor,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt, color: AppTheme.textSecondaryColor),
              title: const Text('Issues List'),
              selectedColor: AppTheme.primaryColor,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/issues/list');
              },
            ),
            
            // Admin-only: Change Zone/Ward
            if (isAdmin)
              ListTile(
                leading: const Icon(Icons.location_on, color: AppTheme.textSecondaryColor),
                title: const Text('Change Zone/Ward'),
                selectedColor: AppTheme.primaryColor,
                onTap: () {
                  Navigator.pop(context);
                  _goToZoneWardSelection();
                },
              ),

            // Admin-only: User Management
            if (isAdmin)
              ListTile(
                leading: const Icon(Icons.people, color: AppTheme.textSecondaryColor),
                title: const Text('User Management'),
                selectedColor: AppTheme.primaryColor,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/admin/users');
                },
              ),
            
            // Detection Camera for all users
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
              title: const Text('Detection Camera'),
              selectedColor: AppTheme.primaryColor,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/camera/detection');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: AppTheme.textSecondaryColor),
              title: const Text('Settings'),
              selectedColor: AppTheme.primaryColor,
              onTap: () {
                Navigator.pop(context);
                // Navigator.pushNamed(context, '/settings');
                CustomSnackbar.show(
                  context: context,
                  message: 'Settings feature coming soon!',
                );
              },
            ),
            
            const Spacer(),
            
            // Logout button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: AppButton(
                text: 'Logout',
                icon: Icons.logout,
                type: ButtonType.secondary,
                onPressed: () {
                  // Close drawer first to avoid Navigator lock issues
                  Navigator.pop(context);
                  
                  // Show dialog to confirm logout
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to log out?'),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            // Close dialog
                            Navigator.pop(context);
                            
                            // Show loading indicator
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                            
                            try {
                              await authProvider.logout();
                              
                              // Close loading dialog
                              if (mounted) Navigator.pop(context);
                              
                              // Use microtask to avoid Navigator lock issues
                              if (mounted) {
                                Future.microtask(() {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/login',
                                    (route) => false,
                                  );
                                });
                              }
                            } catch (e) {
                              // Close loading dialog
                              if (mounted) Navigator.pop(context);
                              
                              if (mounted) {
                                CustomSnackbar.showError(
                                  context: context,
                                  message: 'Error during logout: ${e.toString()}',
                                );
                              }
                            }
                          },
                          child: const Text('Logout', style: TextStyle(color: AppTheme.errorColor)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // App version
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: AppTheme.textTertiaryColor,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
