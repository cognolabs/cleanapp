import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cognoapp/presentation/camera/camera_provider.dart';
import 'package:cognoapp/presentation/common_widgets/app_bar.dart';
import 'package:cognoapp/presentation/common_widgets/app_button.dart';
import 'package:cognoapp/presentation/common_widgets/app_card.dart';
import 'package:cognoapp/config/theme.dart';
import 'package:cognoapp/config/constants.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CameraResultsScreen extends StatelessWidget {
  final ProcessingResult? result;

  const CameraResultsScreen({Key? key, this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cameraProvider = Provider.of<CameraProvider>(context);
    final processingResult = result ?? cameraProvider.lastProcessingResult;

    if (processingResult == null) {
      return Scaffold(
        appBar: ModernAppBar(
          title: 'Detection Results',
          showBackButton: true,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: AppTheme.textSecondaryColor,
              ),
              SizedBox(height: 16),
              Text(
                'No Results Available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Capture an image to see detection results',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: ModernAppBar(
        title: 'Detection Results',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareResults(context, processingResult),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            _buildSummaryCard(processingResult),
            
            const SizedBox(height: 16),
            
            // Location Info
            _buildLocationCard(processingResult),
            
            const SizedBox(height: 16),
            
            // Detection Results
            if (processingResult.detections.isNotEmpty) ...[
              Text(
                'Detections Found (${processingResult.totalDetections})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...processingResult.detections.map((detection) => 
                _buildDetectionCard(context, detection)),
            ] else ...[
              _buildNoDetectionsCard(),
            ],
            
            const SizedBox(height: 16),
            
            // Models Processed
            _buildModelsCard(processingResult),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ProcessingResult result) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Processing Complete',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        'ID: ${result.processingId.substring(0, 8)}...',
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildSummaryItem(
                  'Total Detections',
                  result.totalDetections.toString(),
                  Icons.search,
                ),
                const SizedBox(width: 16),
                _buildSummaryItem(
                  'Models Used',
                  result.modelsProcessed.length.toString(),
                  Icons.memory,
                ),
                const SizedBox(width: 16),
                _buildSummaryItem(
                  'Processed',
                  DateFormat('HH:mm').format(result.processedAt),
                  Icons.access_time,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondaryColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(ProcessingResult result) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Capture Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Lat: ${result.imageCoordinates.latitude.toStringAsFixed(6)}',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontFamily: 'monospace',
              ),
            ),
            Text(
              'Lng: ${result.imageCoordinates.longitude.toStringAsFixed(6)}',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openInMaps(
                  result.imageCoordinates.latitude,
                  result.imageCoordinates.longitude,
                ),
                icon: const Icon(Icons.map, size: 16),
                label: const Text('View on Map'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionCard(BuildContext context, MobileDetection detection) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDetectionColor(detection.className).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      detection.className,
                      style: TextStyle(
                        color: _getDetectionColor(detection.className),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      detection.modelType,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(detection.confidence * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(Icons.location_city, 'Zone', detection.zone),
                        const SizedBox(height: 4),
                        _buildInfoRow(Icons.domain, 'Ward', detection.wardName),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(Icons.crop_free, 'Bbox', 
                          '${detection.bbox[2] - detection.bbox[0]} x ${detection.bbox[3] - detection.bbox[1]}'),
                        const SizedBox(height: 4),
                        _buildInfoRow(Icons.gps_fixed, 'Coords', 
                          '${detection.latitude.toStringAsFixed(4)}, ${detection.longitude.toStringAsFixed(4)}'),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Display processed image with bounding boxes if available
              if (detection.imageUrl != null) ...[
                const SizedBox(height: 12),
                _buildDetectionImage(context, detection),
              ],
              
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openInMaps(detection.latitude, detection.longitude),
                      icon: const Icon(Icons.map, size: 16),
                      label: const Text('View Location'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewDetectionDetails(context, detection),
                      icon: const Icon(Icons.info, size: 16),
                      label: const Text('Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetectionImage(BuildContext context, MobileDetection detection) {
    if (detection.imageUrl == null) return const SizedBox.shrink();
    
    final imageUrl = '${AppConstants.API_URL}${detection.imageUrl}';
    
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    SizedBox(height: 8),
                    Text('Failed to load image'),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Detection Result',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: GestureDetector(
                onTap: () => _showFullScreenImage(context, imageUrl),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_in, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Tap to enlarge',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondaryColor),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildNoDetectionsCard() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: AppTheme.textSecondaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'No Issues Detected',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Great news! No issues were found in this image.',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelsCard(ProcessingResult result) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Models Used',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.modelsProcessed.map((model) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.psychology,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      model,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        AppButton(
          text: 'Capture Another Image',
          icon: Icons.camera_alt,
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(height: 8),
        AppButton(
          text: 'View All Results',
          icon: Icons.history,
          type: ButtonType.secondary,
          onPressed: () => Navigator.pushNamed(context, '/camera/history'),
        ),
      ],
    );
  }

  Color _getDetectionColor(String className) {
    switch (className.toLowerCase()) {
      case 'garbage':
      case 'trash':
        return Colors.amber;
      case 'pothole':
        return Colors.red;
      case 'stray animal':
      case 'stray_animal':
        return Colors.green;
      case 'hoarding':
      case 'hoardings':
        return Colors.purple;
      case 'encroachment':
        return Colors.orange;
      default:
        return AppTheme.primaryColor;
    }
  }

  Future<void> _openInMaps(double latitude, double longitude) async {
    final url = 'https://www.google.com/maps?q=$latitude,$longitude';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _viewDetectionDetails(BuildContext context, MobileDetection detection) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Detection Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('ID', detection.detectionId),
            _buildDetailRow('Type', detection.className),
            _buildDetailRow('Model', detection.modelType),
            _buildDetailRow('Confidence', '${(detection.confidence * 100).toStringAsFixed(1)}%'),
            _buildDetailRow('Zone', detection.zone),
            _buildDetailRow('Ward', detection.wardName),
            _buildDetailRow('Coordinates', '${detection.latitude}, ${detection.longitude}'),
            _buildDetailRow('Bounding Box', detection.bbox.toString()),
            const SizedBox(height: 16),
            AppButton(
              text: 'Open in Maps',
              icon: Icons.map,
              onPressed: () {
                Navigator.pop(context);
                _openInMaps(detection.latitude, detection.longitude);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => Container(
                  width: 100,
                  height: 100,
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 200,
                  height: 200,
                  color: Colors.black26,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.white),
                      SizedBox(height: 8),
                      Text('Failed to load image', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareResults(BuildContext context, ProcessingResult result) {
    // Implement sharing functionality
    // For now, show a simple dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Results'),
        content: const Text('Sharing functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}