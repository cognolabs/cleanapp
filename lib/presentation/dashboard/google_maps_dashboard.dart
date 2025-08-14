import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:cognoapp/data/models/zone_ward_model.dart';
import 'package:cognoapp/config/routes.dart';

class GoogleMapsDashboardScreen extends StatefulWidget {
  const GoogleMapsDashboardScreen({Key? key}) : super(key: key);

  @override
  _GoogleMapsDashboardScreenState createState() =>
      _GoogleMapsDashboardScreenState();
}

class _GoogleMapsDashboardScreenState extends State<GoogleMapsDashboardScreen>
    with SingleTickerProviderStateMixin {
  final Completer<GoogleMapController> _controller = Completer();
  CameraPosition? _initialCameraPosition;
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  String _selectedFilter = 'All';
  bool _isRefreshing = false;
  int _currentNavIndex = 0;
  Map<String, BitmapDescriptor> _markerIcons = {};
  Set<Marker> _markers = {};
  Set<Polygon> _polygons = {};
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

    _loadMarkerIcons();
    _getCurrentLocation();
    
    // Load ward boundary if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWardBoundary();
    });
  }

  // Load ward boundary from provider if available
  void _loadWardBoundary() {
    final zoneWardProvider = Provider.of<ZoneWardProvider>(context, listen: false);
    
    if (zoneWardProvider.selectedWardId != null && zoneWardProvider.wardPolygons.isNotEmpty) {
      setState(() {
        _polygons = zoneWardProvider.wardPolygons;
      });
      
      // If we have a ward boundary and location permission is not granted yet,
      // focus the map on the ward instead of default position
      if (_initialCameraPosition == null && zoneWardProvider.selectedWardBoundary != null) {
        // Calculate the center of the ward polygon
        final coords = zoneWardProvider.selectedWardBoundary!.coordinates;
        if (coords.isNotEmpty) {
          double latSum = 0.0;
          double lngSum = 0.0;
          for (var coord in coords) {
            latSum += coord.latitude;
            lngSum += coord.longitude;
          }
          final centerLat = latSum / coords.length;
          final centerLng = lngSum / coords.length;
          
          setState(() {
            _initialCameraPosition = CameraPosition(
              target: LatLng(centerLat, centerLng),
              zoom: 14,
            );
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadMarkerIcons() async {
    final Map<String, BitmapDescriptor> icons = {};

    // Create custom marker icons for different issue statuses
    icons['open'] = await _createCustomMarkerIcon(AppTheme.openStatusColor);
    icons['investigating'] =
        await _createCustomMarkerIcon(AppTheme.investigatingStatusColor);
    icons['closed'] = await _createCustomMarkerIcon(AppTheme.closedStatusColor);
    icons['default'] = await _createCustomMarkerIcon(Colors.blue);
    icons['currentLocation'] = await _createCustomLocationMarkerIcon();

    setState(() {
      _markerIcons = icons;
    });
  }

  Future<BitmapDescriptor> _createCustomMarkerIcon(Color color) async {
    final PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = Colors.white;
    final Paint borderPaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final double radius = 20;

    // Draw white background circle
    canvas.drawCircle(Offset(radius, radius), radius, paint);

    // Draw colored border
    canvas.drawCircle(Offset(radius, radius), radius - 2, borderPaint);

    // Draw location pin icon in the center
    final TextPainter textPainter =
        TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.location_on.codePoint),
      style: TextStyle(
        fontSize: 24,
        fontFamily: Icons.location_on.fontFamily,
        color: color,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(radius - textPainter.width / 2, radius - textPainter.height / 2),
    );

    // Convert to image
    final img = await pictureRecorder
        .endRecording()
        .toImage(radius.toInt() * 2, radius.toInt() * 2);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> _createCustomLocationMarkerIcon() async {
    final PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint circlePaint = Paint()..color = Colors.white;
    final Paint dotPaint = Paint()..color = AppTheme.primaryColor;
    final double radius = 24;

    // Draw white circle
    canvas.drawCircle(Offset(radius, radius), radius, circlePaint);

    // Draw blue dot in the center
    canvas.drawCircle(Offset(radius, radius), radius * 0.5, dotPaint);

    // Add shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(radius, radius + 2), radius, shadowPaint);

    // Convert to image
    final img = await pictureRecorder
        .endRecording()
        .toImage(radius.toInt() * 2, radius.toInt() * 2);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }


  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });
    
    // Default position (Pune, India)
    final defaultPosition = CameraPosition(
      target: LatLng(18.5204, 73.8567),
      zoom: 12,
    );

    try {
      // Set default position immediately to prevent blank map
      setState(() {
        _initialCameraPosition = defaultPosition;
      });

      // Get the actual location
      final position = await LocationHelper.getCurrentPosition();

      setState(() {
        _currentPosition = position;
        _initialCameraPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 15,
        );
        _isLoadingLocation = false;
      });

      // Debug location success
      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: 'Location acquired: ${position.latitude}, ${position.longitude}',
        );
      }

      // Fetch nearby issues
      await _fetchNearbyIssues();

      // Move camera to current position
      if (_controller.isCompleted) {
        final googleMapController = await _controller.future;
        googleMapController.animateCamera(
          CameraUpdate.newCameraPosition(_initialCameraPosition!),
        );
      }

      // Start animation after data is loaded
      _animationController.forward();
    } catch (e) {
      print('Location error: $e');
      setState(() {
        _isLoadingLocation = false;
        // Keep using the default position that was set earlier
      });

      if (mounted) {
        CustomSnackbar.showError(
          context: context,
          message: 'Using default location: ${e.toString()}',
        );
      }

      // Start animation even if we're using default location
      _animationController.forward();
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
      final detectionProvider =
          Provider.of<DetectionProvider>(context, listen: false);

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
        } else {
          _updateMarkers(detectionProvider.issues);
          
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

  void _updateMarkers(List<DetectionModel> issues) {
    final filteredIssues = issues
        .where((issue) =>
            _selectedFilter == 'All' ||
            issue.status.toLowerCase() == _selectedFilter.toLowerCase())
        .toList();

    Set<Marker> newMarkers = {};

    // Add current location marker if available
    if (_currentPosition != null &&
        _markerIcons.containsKey('currentLocation')) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: _markerIcons['currentLocation']!,
          zIndex: 2,
        ),
      );
    }

    // Add issue markers
    for (var issue in filteredIssues) {
      final status = issue.status.toLowerCase();
      final icon = _markerIcons[status] ?? _markerIcons['default']!;

      newMarkers.add(
        Marker(
          markerId: MarkerId('issue_${issue.id}'),
          position: LatLng(issue.latitude, issue.longitude),
          icon: icon,
          zIndex: 1,
          onTap: () {
            _showIssueBottomSheet(context, issue);
          },
          infoWindow: InfoWindow(
            title: issue.className,
            snippet: 'ID: ${issue.id} - ${issue.status.toUpperCase()}',
          ),
        ),
      );
    }

    setState(() {
      _markers = newMarkers;
    });
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
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
                        _buildInfoItem(Icons.calendar_today, 'Detected on',
                            issue.timestamp.toString().substring(0, 10)),
                        const SizedBox(width: 16),
                        _buildInfoItem(Icons.access_time, 'Time',
                            issue.timestamp.toString().substring(11, 16)),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        _buildInfoItem(Icons.percent, 'Confidence',
                            '${(issue.confidence * 100).toStringAsFixed(1)}%'),
                        const SizedBox(width: 16),
                        if (issue.wardName != null)
                          _buildInfoItem(Icons.domain, 'Ward', issue.wardName!),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        _buildInfoItem(Icons.location_on, 'Location',
                            '${issue.latitude.toStringAsFixed(4)}, ${issue.longitude.toStringAsFixed(4)}'),
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
    final displayName = authProvider.currentUser?.name ?? 'User';

    return Scaffold(
      appBar: ModernAppBar(
        title: 'Dashboard',
        showBackButton: false,
        backgroundColor: Colors.white,
        centerTitle: false,
        actions: [
          // Admin Dashboard Button (only for admin users)
          if (authProvider.isAdmin)
            IconButton(
              icon: Icon(Icons.admin_panel_settings),
              tooltip: 'Back to Admin Dashboard',
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/admin/dashboard');
              },
            ),
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
              Navigator.pushReplacementNamed(context, '/profile');
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
      drawer: _buildDrawer(displayName, authProvider),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

          // Google Map
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
                    Builder(
                      builder: (context) {
                        final defaultPosition = CameraPosition(
                          target: LatLng(18.5204, 73.8567),  // Pune, India
                          zoom: 12,
                        );
                          
                        return GoogleMap(
                          mapType: MapType.normal,
                          initialCameraPosition: _initialCameraPosition ?? defaultPosition,
                          markers: _markers,
                          polygons: _polygons,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: true,
                          mapToolbarEnabled: true,
                          compassEnabled: true,
                          onMapCreated: (GoogleMapController controller) {
                            print('Map created, setting controller');
                            _controller.complete(controller);
                            
                            // Add a delay before setting map style
                            Future.delayed(Duration(milliseconds: 500), () {
                              _setMapStyle(controller);
                              print('Map style applied with delay');
                            });
                            
                            // Start animation
                            if (!_animationController.isAnimating && !_animationController.isCompleted) {
                              _animationController.forward();
                            }
                          },
                        );
                      },
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
                          onPressed: () async {
                            if (_currentPosition != null &&
                                _controller.isCompleted) {
                              final GoogleMapController controller =
                                  await _controller.future;
                              controller.animateCamera(
                                CameraUpdate.newCameraPosition(
                                  CameraPosition(
                                    target: LatLng(_currentPosition!.latitude,
                                        _currentPosition!.longitude),
                                    zoom: 15,
                                  ),
                                ),
                              );
                            }
                          },
                          heroTag: 'myLocationButton',
                          tooltip: 'My location',
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
                        ),
                        const SizedBox(height: 8),
                        // Alerts button
                        _buildFloatingActionButton(
                          icon: Icons.notifications,
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.alerts);
                          },
                          heroTag: 'alertsButton',
                          tooltip: 'View alerts',
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
          // Handle navigation
          if (index == 0) {
            // Already on dashboard
            setState(() {
              _currentNavIndex = 0;
            });
          } else if (index == 1) {
            Navigator.pushNamed(context, AppRoutes.alerts);
          } else if (index == 2) {
            Navigator.pushNamed(context, '/issues/list');
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

  Future<void> _setMapStyle(GoogleMapController controller) async {
    try {
      // Set default style first
      controller.setMapStyle(null);
      
      // Load map style JSON
      String style = await rootBundle.loadString('assets/map_style.json');
      
      // Apply custom style
      await controller.setMapStyle(style);
      print('Map style applied successfully');
    } catch (e) {
      // Use default style if the custom style fails to load
      print('Error loading map style: $e');
      try {
        // Reset to default style
        controller.setMapStyle(null);
      } catch (e2) {
        print('Failed to reset map style: $e2');
      }
    }
  }

  Widget _buildFloatingActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String heroTag,
    String? tooltip,
    bool mini = false,
  }) {
    return FloatingActionButton(
      heroTag: heroTag,
      mini: mini,
      backgroundColor: Colors.white,
      foregroundColor: AppTheme.primaryColor,
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

        final detectionProvider =
            Provider.of<DetectionProvider>(context, listen: false);
        if (detectionProvider.issues.isNotEmpty) {
          _updateMarkers(detectionProvider.issues);
        } else {
          _fetchNearbyIssues();
        }
      },
    );
  }

  Widget _buildDrawer(String displayName, AuthProvider authProvider) {
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
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : 'U',
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
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Menu items
            // Admin Dashboard item (only for admin users)
            if (authProvider.isAdmin)
              ListTile(
                leading:
                    const Icon(Icons.admin_panel_settings, color: AppTheme.textSecondaryColor),
                title: const Text('Admin Dashboard'),
                selectedColor: AppTheme.primaryColor,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/admin/dashboard');
                },
              ),
              
            ListTile(
              leading:
                  const Icon(Icons.dashboard, color: AppTheme.primaryColor),
              title: const Text('Dashboard'),
              selected: true,
              selectedColor: AppTheme.primaryColor,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt,
                  color: AppTheme.textSecondaryColor),
              title: const Text('Issues List'),
              selectedColor: AppTheme.primaryColor,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/issues/list');
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt,
                  color: AppTheme.primaryColor),
              title: const Text('Detection Camera'),
              selectedColor: AppTheme.primaryColor,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/camera/detection');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings,
                  color: AppTheme.textSecondaryColor),
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
                                  message:
                                      'Error during logout: ${e.toString()}',
                                );
                              }
                            }
                          },
                          child: const Text('Logout',
                              style: TextStyle(color: AppTheme.errorColor)),
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
