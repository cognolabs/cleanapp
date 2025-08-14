import 'package:flutter/material.dart';
import 'package:cognoapp/presentation/authentication/login_screen.dart';
import 'package:cognoapp/presentation/dashboard/google_maps_dashboard.dart';
import 'package:cognoapp/presentation/zone_ward/zone_ward_selection_screen.dart';
import 'package:cognoapp/presentation/issue_management/issue_details_screen.dart';
import 'package:cognoapp/presentation/issue_management/issue_resolution_screen.dart';
import 'package:cognoapp/presentation/issue_management/issues_list_screen.dart';
import 'package:cognoapp/presentation/issue_management/route_directions_screen.dart';
import 'package:cognoapp/presentation/profile/profile_screen.dart';
import 'package:cognoapp/presentation/dashboard/auth_guard.dart';
import 'package:cognoapp/presentation/admin/admin_dashboard_screen.dart';
import 'package:cognoapp/presentation/admin/user_management_screen.dart';
import 'package:cognoapp/presentation/alerts/alerts_screen.dart';
import 'package:cognoapp/presentation/alerts/manager_alerts_screen.dart';
import 'package:cognoapp/presentation/camera/camera_detection_screen.dart';
import 'package:cognoapp/presentation/camera/camera_results_screen.dart';
import 'package:cognoapp/presentation/camera/camera_provider.dart';

class AppRoutes {
  static const String login = '/login';
  static const String zoneWardSelection = '/zone-ward-selection';
  static const String dashboard = '/dashboard';
  static const String issuesList = '/issues/list';
  static const String issueDetails = '/issues/details';
  static const String issueResolution = '/issues/resolution';
  static const String routeDirections = '/issues/routes';
  static const String profile = '/profile';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String alerts = '/alerts';
  static const String managerAlerts = '/manager/alerts';
  static const String cameraDetection = '/camera/detection';
  static const String cameraResults = '/camera/results';
  static const String cameraHistory = '/camera/history';

  static Map<String, Widget Function(BuildContext)> routes = {
    login: (context) => const LoginScreen(),
    zoneWardSelection: (context) => const ZoneWardSelectionScreen(),
    dashboard: (context) => const AuthGuard(child: GoogleMapsDashboardScreen()),
    issuesList: (context) => const AuthGuard(child: IssuesListScreen()),
    routeDirections: (context) => const AuthGuard(child: RouteDirectionsScreen()),
    profile: (context) => const AuthGuard(child: ProfileScreen()),
    adminDashboard: (context) => const AuthGuard(child: AdminDashboardScreen()),
    adminUsers: (context) => const AuthGuard(child: UserManagementScreen()),
    alerts: (context) => const AuthGuard(child: AlertsScreen()),
    managerAlerts: (context) => const AuthGuard(child: ManagerAlertsScreen()),
    cameraDetection: (context) => const AuthGuard(child: CameraDetectionScreen()),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case issueDetails:
        final int issueId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (context) => AuthGuard(
            child: IssueDetailsScreen(issueId: issueId),
          ),
        );
      case issueResolution:
        final int issueId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (context) => AuthGuard(
            child: IssueResolutionScreen(issueId: issueId),
          ),
        );
      case routeDirections:
        final String statusFilter = settings.arguments as String? ?? 'Open';
        return MaterialPageRoute(
          builder: (context) => AuthGuard(
            child: RouteDirectionsScreen(statusFilter: statusFilter),
          ),
        );
      case cameraResults:
        final result = settings.arguments as ProcessingResult?;
        return MaterialPageRoute(
          builder: (context) => AuthGuard(
            child: CameraResultsScreen(result: result),
          ),
        );
      case cameraHistory:
        return MaterialPageRoute(
          builder: (context) => const AuthGuard(
            child: CameraResultsScreen(), // Will show history
          ),
        );
      default:
        return null;
    }
  }
}