import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cognoapp/presentation/authentication/auth_provider.dart';
import 'package:cognoapp/presentation/issue_management/detection_provider.dart';
import 'package:cognoapp/core/widgets/custom_snackbar.dart';
import 'package:cognoapp/core/widgets/primary_button.dart';
import 'package:cognoapp/config/theme.dart';
import 'package:cognoapp/presentation/common_widgets/bottom_navigation.dart';
import 'package:cognoapp/core/auth/roles.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isRefreshing = false;
  
  @override
  void initState() {
    super.initState();
    // Refresh user profile when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUserProfile();
    });
  }

  Future<void> _refreshUserProfile() async {
    setState(() {
      _isRefreshing = true;
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
          _isRefreshing = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshUserProfile,
          ),
        ],
      ),
      body: user == null || _isRefreshing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile header
                  Center(
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.primaryColor,
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.name.isNotEmpty ? user.name : 'User',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email.isNotEmpty ? user.email : 'No email found',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getRoleColor(user.userRole),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user.userRole.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Account Settings
                  const Text(
                    'Account Settings',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Settings list
                  _buildSettingsCard(
                    icon: Icons.person,
                    title: 'Edit Profile',
                    subtitle: 'Update your profile information',
                    onTap: () {
                      CustomSnackbar.show(
                        context: context,
                        message: 'Edit profile functionality will be implemented soon',
                      );
                    },
                  ),
                  
                  _buildSettingsCard(
                    icon: Icons.lock,
                    title: 'Change Password',
                    subtitle: 'Update your password',
                    onTap: () {
                      CustomSnackbar.show(
                        context: context,
                        message: 'Change password functionality will be implemented soon',
                      );
                    },
                  ),
                  
                  _buildSettingsCard(
                    icon: Icons.notifications,
                    title: 'Notification Settings',
                    subtitle: 'Manage notification preferences',
                    onTap: () {
                      CustomSnackbar.show(
                        context: context,
                        message: 'Notification settings will be implemented soon',
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // App Settings
                  const Text(
                    'App Settings',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSettingsCard(
                    icon: Icons.language,
                    title: 'Language',
                    subtitle: 'Change app language',
                    onTap: () {
                      CustomSnackbar.show(
                        context: context,
                        message: 'Language settings will be implemented soon',
                      );
                    },
                  ),
                  
                  _buildSettingsCard(
                    icon: Icons.dark_mode,
                    title: 'Theme',
                    subtitle: 'Change app theme',
                    onTap: () {
                      CustomSnackbar.show(
                        context: context,
                        message: 'Theme settings will be implemented soon',
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // More options
                  const Text(
                    'More',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSettingsCard(
                    icon: Icons.help,
                    title: 'Help & Support',
                    subtitle: 'Get help with the app',
                    onTap: () {
                      CustomSnackbar.show(
                        context: context,
                        message: 'Help & support will be implemented soon',
                      );
                    },
                  ),
                  
                  _buildSettingsCard(
                    icon: Icons.privacy_tip,
                    title: 'Privacy Policy',
                    subtitle: 'View our privacy policy',
                    onTap: () {
                      CustomSnackbar.show(
                        context: context,
                        message: 'Privacy policy will be implemented soon',
                      );
                    },
                  ),
                  
                  _buildSettingsCard(
                    icon: Icons.description,
                    title: 'Terms of Service',
                    subtitle: 'View our terms of service',
                    onTap: () {
                      CustomSnackbar.show(
                        context: context,
                        message: 'Terms of service will be implemented soon',
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Logout button
                  PrimaryButton(
                    text: 'Logout',
                    icon: Icons.logout,
                    backgroundColor: Colors.red,
                    onPressed: () async {
                      // Show loading indicator before logout
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
                        // Show success message
                        if (mounted) {
                          CustomSnackbar.show(
                            context: context,
                            message: 'Successfully logged out',
                          );
                        }
                        // Navigate to login screen
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
                        // Show error message
                        if (mounted) {
                          CustomSnackbar.showError(
                            context: context,
                            message: 'Error during logout: ${e.toString()}',
                          );
                        }
                      }
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // App version
                  Center(
                    child: Text(
                      'Cognoclean v1.0.0',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                ],
              ),
            ),
      bottomNavigationBar: ModernBottomNavigation(
        currentIndex: 3, // Profile index (updated)
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/alerts');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/issues/list');
          } else if (index == 3) {
            // Already on profile
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

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.amber;
      case UserRole.manager:
        return Colors.purple;
      case UserRole.operator:
        return AppTheme.primaryColor;
      case UserRole.viewer:
        return Colors.grey;
    }
  }
}
