import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cognoapp/presentation/authentication/auth_provider.dart';
import 'package:cognoapp/presentation/common_widgets/splash_screen.dart';
import 'package:cognoapp/presentation/zone_ward/zone_ward_provider.dart';

class AuthGuard extends StatefulWidget {
  final Widget child;
  
  const AuthGuard({Key? key, required this.child}) : super(key: key);

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool _checkedAuth = false;
  
  bool _isInitialCheck = true;
  
  @override
  void initState() {
    super.initState();
    
    // Check auth status when the guard initializes, but only once
    if (_isInitialCheck) {
      _isInitialCheck = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAuthStatus();
      });
    }
  }
  
  Future<void> _checkAuthStatus() async {
    // Avoid multiple simultaneous auth checks
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Only do a full check if we haven't already or if we're not loading
    if (!_checkedAuth && !authProvider.isLoading) {
      final isAuthenticated = await authProvider.checkAuthStatus();
      
      if (mounted) {
        setState(() => _checkedAuth = true);
        
        if (!isAuthenticated && mounted) {
          // Navigate to login screen if not authenticated
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        } else if (isAuthenticated && authProvider.requireZoneWardSelection && mounted) {
          // Initialize zone ward provider
          final zoneWardProvider = Provider.of<ZoneWardProvider>(context, listen: false);
          zoneWardProvider.initialize();
          
          // Navigate to zone/ward selection screen
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/zone-ward-selection',
            (route) => false
          );
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Skip showing splash screen if we're already authenticated
    // This prevents the splash screen flash during navigation
    if (authProvider.isAuthenticated && !authProvider.requireZoneWardSelection) {
      _checkedAuth = true; // Mark as checked to prevent further checks
      return widget.child;
    }
    
    // For initial auth check, use the non-listener version to avoid rebuilds
    if (authProvider.isLoading && !_checkedAuth) {
      // Only show splash during initial loading
      return const SplashScreen();
    }
    
    // If not authenticated, handle navigation in post-frame callback
    if (!authProvider.isAuthenticated) {
      // Only handle navigation if not already in progress
      if (!_checkedAuth) {
        _checkedAuth = true; // Mark as checked to prevent endless redirects
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        });
      }
      // Show minimal widget while navigating
      return const SizedBox();
    }
    
    // If authenticated but zone/ward selection required
    if (authProvider.requireZoneWardSelection) {
      // Only handle navigation if not already in progress
      if (!_checkedAuth) {
        _checkedAuth = true; // Mark as checked to prevent endless redirects
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final zoneWardProvider = Provider.of<ZoneWardProvider>(context, listen: false);
            zoneWardProvider.initialize();
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/zone-ward-selection',
              (route) => false
            );
          }
        });
      }
      // Show minimal widget while navigating
      return const SizedBox();
    }
    
    // Auth check passed and zone/ward selected - show the protected content
    _checkedAuth = true; // Mark as checked to prevent further checks
    return widget.child;
  }
}
