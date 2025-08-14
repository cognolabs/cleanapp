import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cognoapp/core/widgets/custom_snackbar.dart';
import 'package:cognoapp/core/widgets/primary_button.dart';
import 'package:cognoapp/presentation/issue_management/detection_provider.dart';
import 'package:cognoapp/config/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cognoapp/config/constants.dart';
import 'package:url_launcher/url_launcher_string.dart';

class IssueDetailsScreen extends StatefulWidget {
  final int issueId;

  const IssueDetailsScreen({Key? key, required this.issueId}) : super(key: key);

  @override
  _IssueDetailsScreenState createState() => _IssueDetailsScreenState();
}

class _IssueDetailsScreenState extends State<IssueDetailsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIssueDetails();
  }

  Future<void> _loadIssueDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final detectionProvider = Provider.of<DetectionProvider>(context, listen: false);
      await detectionProvider.fetchIssueById(widget.issueId);
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(
          context: context,
          message: 'Failed to load issue details: ${e.toString()}',
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

  Future<void> _openMapsLink(String url) async {
    try {
      if (await canLaunchUrlString(url)) {
        await launchUrlString(url);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      CustomSnackbar.showError(
        context: context,
        message: 'Could not open maps: ${e.toString()}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final detectionProvider = Provider.of<DetectionProvider>(context);
    final issue = detectionProvider.selectedIssue;

    return Scaffold(
      appBar: AppBar(
        title: Text('Issue Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadIssueDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : issue == null
              ? const Center(child: Text('Issue not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Issue #${issue.id}',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  issue.className,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(issue.status),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              issue.status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Detection Image
                      if (issue.framePath != null)
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Detection Image',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: '${AppConstants.BASE_URL}/${issue.framePath}',
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      height: 200,
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: Icon(
                                          Icons.image_not_supported,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      
                      // Issue Details
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Issue Details',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildDetailRow('Detected on', issue.timestamp.toString().substring(0, 16)),
                              _buildDetailRow('Model Type', issue.modelType),
                              _buildDetailRow('Confidence', '${(issue.confidence * 100).toStringAsFixed(1)}%'),
                              _buildDetailRow('Latitude', issue.latitude.toString()),
                              _buildDetailRow('Longitude', issue.longitude.toString()),
                              if (issue.wardName != null)
                                _buildDetailRow('Ward', issue.wardName!),
                              if (issue.zone != null)
                                _buildDetailRow('Zone', issue.zone!),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Location
                      if (issue.mapsLink != null)
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Location',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                PrimaryButton(
                                  text: 'Open in Maps',
                                  icon: Icons.map,
                                  onPressed: () {
                                    if (issue.mapsLink != null) {
                                      _openMapsLink(issue.mapsLink!);
                                    } else {
                                      CustomSnackbar.showError(
                                        context: context,
                                        message: 'Maps link not available',
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      
                      // Action buttons
                      issue.status.toLowerCase() != 'closed'
                          ? PrimaryButton(
                              text: 'Resolve Issue',
                              icon: Icons.check_circle,
                              backgroundColor: AppTheme.secondaryColor,
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/issues/resolution',
                                  arguments: issue.id,
                                );
                              },
                            )
                          : Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: AppTheme.closedStatusColor,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'This issue has been resolved',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ],
                  ),
                ),
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
}
