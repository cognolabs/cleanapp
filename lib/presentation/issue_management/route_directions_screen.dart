import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:provider/provider.dart';
import 'package:cognoapp/core/widgets/custom_snackbar.dart';
import 'package:cognoapp/core/utils/location_helper.dart';
import 'package:cognoapp/core/utils/route_optimizer.dart';
import 'package:cognoapp/presentation/issue_management/detection_provider.dart';
import 'package:cognoapp/presentation/zone_ward/zone_ward_provider.dart';
import 'package:cognoapp/config/theme.dart';
import 'package:cognoapp/data/models/detection_model.dart';
import 'package:cognoapp/presentation/common_widgets/app_button.dart';

class RouteDirectionsScreen extends StatefulWidget {
  final String statusFilter;
  
  const RouteDirectionsScreen({
    Key? key, 
    this.statusFilter = 'Open',
  }) : super(key: key);

  @override
  _RouteDirectionsScreenState createState() => _RouteDirectionsScreenState();
}

class _RouteDirectionsScreenState extends State<RouteDirectionsScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  List<DetectionModel> _optimizedRoute = [];
  bool _isLoading = true;
  double _routeDistance = 0;
  String _googleMapsUrl = '';
  
  @override
  void initState() {
    super.initState();
    _initializeRoute();
  }
  
  Future<void> _initializeRoute() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get current position
      final position = await LocationHelper.getCurrentPosition();
      
      setState(() {
        _currentPosition = position;
      });
      
      // Generate optimized route
      await _generateOptimizedRoute();
      
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(
          context: context,
          message: 'Failed to generate route: ${e.toString()}',
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _generateOptimizedRoute() async {
    if (_currentPosition == null) {
      CustomSnackbar.showError(
        context: context,
        message: 'Unable to get your current location',
      );
      return;
    }
    
    final detectionProvider = Provider.of<DetectionProvider>(context, listen: false);
    final zoneWardProvider = Provider.of<ZoneWardProvider>(context, listen: false);
    
    // Get the ward and zone IDs
    final wardId = zoneWardProvider.selectedWardId;
    final zoneId = zoneWardProvider.selectedZoneId;
    
    // Optimize the route
    final optimizedRoute = RouteOptimizer.optimizeRoute(
      _currentPosition!,
      detectionProvider.issues,
      statusFilter: widget.statusFilter,
      wardId: wardId,
      zoneId: zoneId,
    );
    
    // Calculate the total distance
    final totalDistance = RouteOptimizer.calculateTotalRouteDistance(
      _currentPosition!,
      optimizedRoute,
    );
    
    // Generate Google Maps URL
    final mapsUrl = RouteOptimizer.generateGoogleMapsUrl(
      _currentPosition!,
      optimizedRoute,
    );
    
    setState(() {
      _optimizedRoute = optimizedRoute;
      _routeDistance = totalDistance;
      _googleMapsUrl = mapsUrl;
    });
    
    // Fit the map to show the route
    _fitMapToRoute();
  }
  
  void _fitMapToRoute() {
    if (_currentPosition == null || _optimizedRoute.isEmpty) return;
    
    // Create initial bounds with the current position
    double minLat = _currentPosition!.latitude;
    double maxLat = _currentPosition!.latitude;
    double minLng = _currentPosition!.longitude;
    double maxLng = _currentPosition!.longitude;
    
    // Extend bounds with all the route points
    for (var issue in _optimizedRoute) {
      minLat = issue.latitude < minLat ? issue.latitude : minLat;
      maxLat = issue.latitude > maxLat ? issue.latitude : maxLat;
      minLng = issue.longitude < minLng ? issue.longitude : minLng;
      maxLng = issue.longitude > maxLng ? issue.longitude : maxLng;
    }
    
    // Create bounds with southwest and northeast corners
    final bounds = LatLngBounds(
      LatLng(minLat, minLng), // southwest corner
      LatLng(maxLat, maxLng), // northeast corner
    );
    
    // Fit the map to the bounds with padding
    Future.delayed(const Duration(milliseconds: 300), () {
      _mapController.fitBounds(
        bounds,
        options: const FitBoundsOptions(
          padding: EdgeInsets.all(40),
        ),
      );
    });
  }
  
  Future<void> _openInGoogleMaps() async {
    if (_googleMapsUrl.isEmpty) {
      CustomSnackbar.showError(
        context: context,
        message: 'Google Maps URL not available',
      );
      return;
    }
    
    try {
      if (await canLaunchUrlString(_googleMapsUrl)) {
        await launchUrlString(_googleMapsUrl);
      } else {
        throw 'Could not launch Google Maps';
      }
    } catch (e) {
      CustomSnackbar.showError(
        context: context,
        message: 'Failed to open Google Maps: ${e.toString()}',
      );
    }
  }
  
  Color _getIssueMarkerColor(String status) {
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

  @override
  Widget build(BuildContext context) {
    final zoneWardProvider = Provider.of<ZoneWardProvider>(context);
    final zoneId = zoneWardProvider.selectedZoneId;
    final wardId = zoneWardProvider.selectedWardId;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Optimized Route'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeRoute,
            tooltip: 'Refresh route',
          ),
        ],
      ),
      body: Column(
        children: [
          // Location and filter info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.primaryColor.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: AppTheme.textPrimaryColor,
                            fontSize: 14,
                          ),
                          children: [
                            const TextSpan(
                              text: 'Optimized route for ',
                            ),
                            TextSpan(
                              text: widget.statusFilter,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const TextSpan(
                              text: ' issues',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (zoneId != null || wardId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          [
                            if (zoneId != null) 'Zone $zoneId',
                            if (wardId != null) 'Ward $wardId',
                          ].join(' - '),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Route statistics
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                // Issue count
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.format_list_numbered,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Issues',
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _optimizedRoute.length.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Distance
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.route,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Distance',
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${_routeDistance.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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
          
          // Map with route
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _optimizedRoute.isEmpty
                ? _buildEmptyState()
                : Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          center: _currentPosition != null
                            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                            : const LatLng(20.5937, 78.9629), // Default to India if location not available
                          zoom: 15.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.cognoclean.app',
                          ),
                          
                          // Polyline for the route
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _buildRoutePoints(),
                                strokeWidth: 4.0,
                                color: AppTheme.primaryColor.withOpacity(0.7),
                              ),
                            ],
                          ),
                          
                          // Markers for the issues
                          MarkerLayer(
                            markers: _buildRouteMarkers(),
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
                        ],
                      ),
                      
                      // Floating action buttons
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: Column(
                          children: [
                            // My location button
                            FloatingActionButton(
                              heroTag: 'myLocationButton',
                              mini: true,
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.primaryColor,
                              elevation: 4,
                              onPressed: () {
                                if (_currentPosition != null) {
                                  _mapController.move(
                                    LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                    15.0,
                                  );
                                }
                              },
                              child: const Icon(Icons.my_location),
                            ),
                            const SizedBox(height: 8),
                            
                            // Fit to route button
                            FloatingActionButton(
                              heroTag: 'fitRouteButton',
                              mini: true,
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.primaryColor,
                              elevation: 4,
                              onPressed: _fitMapToRoute,
                              child: const Icon(Icons.fit_screen),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          
          // Bottom action button
          if (_optimizedRoute.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: AppButton(
                text: 'Open in Google Maps',
                icon: Icons.map,
                onPressed: _openInGoogleMaps,
              ),
            ),
        ],
      ),
    );
  }
  
  List<LatLng> _buildRoutePoints() {
    final List<LatLng> points = [];
    
    // Add current position
    if (_currentPosition != null) {
      points.add(LatLng(_currentPosition!.latitude, _currentPosition!.longitude));
    }
    
    // Add all issues in the route
    for (var issue in _optimizedRoute) {
      points.add(LatLng(issue.latitude, issue.longitude));
    }
    
    return points;
  }
  
  List<Marker> _buildRouteMarkers() {
    final List<Marker> markers = [];
    
    // Add numbered markers for each issue in the route
    for (int i = 0; i < _optimizedRoute.length; i++) {
      final issue = _optimizedRoute[i];
      
      markers.add(
        Marker(
          width: 50.0,
          height: 50.0,
          point: LatLng(issue.latitude, issue.longitude),
          builder: (context) => GestureDetector(
            onTap: () {
              // Show issue details on tap
              _showIssueBottomSheet(context, issue, i + 1);
            },
            child: Column(
              children: [
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
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: _getIssueMarkerColor(issue.status),
                          size: 22,
                        ),
                        Positioned(
                          top: 3,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _getIssueMarkerColor(issue.status),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: _getIssueMarkerColor(issue.status),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return markers;
  }
  
  void _showIssueBottomSheet(BuildContext context, DetectionModel issue, int routeIndex) {
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
                        // Route number badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Stop $routeIndex',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _getIssueMarkerColor(issue.status),
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
                        
                        // Close button
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
                    _buildDetailRow('Detected on', issue.timestamp.toString().substring(0, 16)),
                    _buildDetailRow('Model Type', issue.modelType),
                    _buildDetailRow('Confidence', '${(issue.confidence * 100).toStringAsFixed(1)}%'),
                    if (issue.wardName != null)
                      _buildDetailRow('Ward', issue.wardName!),
                    if (issue.zone != null)
                      _buildDetailRow('Zone', issue.zone!),
                    
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
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.route_outlined,
                size: 64,
                color: AppTheme.warningColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No issues found for this route',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Try changing your filter or selecting a different zone/ward',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            AppButton(
              text: 'Change Filter',
              icon: Icons.filter_alt,
              type: ButtonType.secondary,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => _buildFilterDialog(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFilterDialog() {
    String selectedFilter = widget.statusFilter;
    
    return AlertDialog(
      title: const Text('Select Issue Status'),
      content: StatefulBuilder(
        builder: (context, setState) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFilterOption('All', selectedFilter, (value) {
                  setState(() => selectedFilter = value);
                }),
                _buildFilterOption('Open', selectedFilter, (value) {
                  setState(() => selectedFilter = value);
                }),
                _buildFilterOption('Investigating', selectedFilter, (value) {
                  setState(() => selectedFilter = value);
                }),
                _buildFilterOption('Closed', selectedFilter, (value) {
                  setState(() => selectedFilter = value);
                }),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => RouteDirectionsScreen(
                  statusFilter: selectedFilter,
                ),
              ),
            );
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
  
  Widget _buildFilterOption(String label, String selectedValue, Function(String) onChanged) {
    return RadioListTile<String>(
      title: Text(label),
      value: label,
      groupValue: selectedValue,
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
      activeColor: AppTheme.primaryColor,
      contentPadding: EdgeInsets.zero,
    );
  }
}
