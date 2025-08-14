import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cognoapp/config/theme.dart';
import 'package:cognoapp/presentation/authentication/auth_provider.dart';
import 'package:cognoapp/presentation/issue_management/detection_provider.dart';
import 'package:cognoapp/presentation/common_widgets/app_bar.dart';
import 'package:cognoapp/presentation/common_widgets/app_button.dart';
import 'package:cognoapp/core/widgets/custom_snackbar.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  
  bool _isLoadingProfile = false;
  
  @override
  void initState() {
    super.initState();
    // Make sure profile is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUserProfile();
    });
  }
  
  Future<void> _refreshUserProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.checkAuthStatus();
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(
          context: context,
          message: 'Failed to load profile: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final detectionProvider = Provider.of<DetectionProvider>(context);
    final displayName = authProvider.currentUser?.name ?? 'Admin';
    
    return Scaffold(
      appBar: ModernAppBar(
        title: 'Admin Dashboard',
        showBackButton: false,
        backgroundColor: Colors.white,
        centerTitle: false,
        actions: [
          // Profile button
          _isLoadingProfile 
              ? Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: 36,
                  height: 36,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A',
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
      drawer: _buildDrawer(context, displayName, authProvider),
      body: _buildDashboardContent(context),
    );
  }
  
  Widget _buildDashboardContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          Text(
            'Welcome to Admin Dashboard',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Manage users, zones/wards, and view issue statistics',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          
          // Admin menu cards
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(bottom: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.2,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                // Define the cards
                final cards = [
                  // User Management card
                  _buildAdminCard(
                    context,
                    title: 'User Management',
                    icon: Icons.people,
                    color: AppTheme.primaryColor,
                    onTap: () {
                      Navigator.pushNamed(context, '/admin/users');
                    },
                  ),
                  
                  // Map Dashboard card
                  _buildAdminCard(
                    context,
                    title: 'Map Dashboard',
                    icon: Icons.map,
                    color: AppTheme.secondaryColor,
                    onTap: () {
                      Navigator.pushNamed(context, '/dashboard');
                    },
                  ),
                  
                  // Zone & Ward Management card
                  _buildAdminCard(
                    context,
                    title: 'Zone & Ward',
                    icon: Icons.location_on,
                    color: AppTheme.warningColor,
                    onTap: () {
                      Navigator.pushNamed(context, '/zone-ward-selection');
                    },
                  ),
                  
                  // Issues Overview card
                  _buildAdminCard(
                    context,
                    title: 'Issues List',
                    icon: Icons.list_alt,
                    color: AppTheme.errorColor,
                    onTap: () {
                      Navigator.pushNamed(context, '/issues/list');
                    },
                  ),
                  
                  // Statistics card
                  _buildAdminCard(
                    context,
                    title: 'Statistics',
                    icon: Icons.bar_chart,
                    color: Colors.purple,
                    onTap: () {
                      CustomSnackbar.show(
                        context: context,
                        message: 'Statistics feature coming soon!',
                      );
                    },
                  ),
                  
                  // Settings card
                  _buildAdminCard(
                    context,
                    title: 'Settings',
                    icon: Icons.settings,
                    color: Colors.grey,
                    onTap: () {
                      CustomSnackbar.show(
                        context: context,
                        message: 'Settings feature coming soon!',
                      );
                    },
                  ),
                ];
                
                return cards[index];
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAdminCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDrawer(BuildContext context, String displayName, AuthProvider authProvider) {
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
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A',
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
              title: const Text('Admin Dashboard'),
              selected: true,
              selectedColor: AppTheme.primaryColor,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people, color: AppTheme.textSecondaryColor),
              title: const Text('User Management'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/admin/users');
              },
            ),
            ListTile(
              leading: const Icon(Icons.map, color: AppTheme.textSecondaryColor),
              title: const Text('Map Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on, color: AppTheme.textSecondaryColor),
              title: const Text('Zone & Ward Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/zone-ward-selection');
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt, color: AppTheme.textSecondaryColor),
              title: const Text('Issues List'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/issues/list');
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
