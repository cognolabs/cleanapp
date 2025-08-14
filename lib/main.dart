import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

import 'package:cognoapp/config/routes.dart';
import 'package:cognoapp/config/theme.dart';
import 'package:cognoapp/core/network/api_client.dart';
import 'package:cognoapp/core/utils/api_helper.dart';
import 'package:cognoapp/presentation/authentication/auth_provider.dart';
import 'package:cognoapp/presentation/issue_management/detection_provider.dart';
import 'package:cognoapp/presentation/zone_ward/zone_ward_provider.dart';
import 'package:cognoapp/presentation/admin/admin_provider.dart';
import 'package:cognoapp/data/repositories/zone_ward_repository.dart';
import 'package:cognoapp/data/repositories/admin/user_management_repository.dart';
import 'package:cognoapp/presentation/authentication/login_screen.dart';
import 'package:cognoapp/presentation/dashboard/google_maps_dashboard.dart';
import 'package:cognoapp/presentation/common_widgets/splash_screen.dart';
import 'package:cognoapp/presentation/zone_ward/zone_ward_selection_screen.dart';
import 'package:cognoapp/presentation/admin/admin_dashboard_screen.dart';
import 'package:cognoapp/presentation/alerts/manager_alerts_screen.dart';
import 'package:cognoapp/presentation/alerts/alerts_provider.dart';
import 'package:cognoapp/presentation/camera/camera_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize shared preferences
  final sharedPreferences = await SharedPreferences.getInstance();
  
  // Initialize secure storage
  const secureStorage = FlutterSecureStorage();
  
  // Initialize logger
  final logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );
  
  // Initialize API client
  final apiClient = ApiClient(
    httpClient: http.Client(),
    dio: Dio(),
    secureStorage: secureStorage,
    logger: logger,
  );
  
  // Initialize API helper
  final apiHelper = ApiHelper(
    httpClient: http.Client(),
    secureStorage: secureStorage,
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            apiClient: apiClient,
            secureStorage: secureStorage,
            sharedPreferences: sharedPreferences,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => DetectionProvider(
            apiClient: apiClient,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ZoneWardProvider(
            repository: ZoneWardRepository(
              client: http.Client(),
              apiHelper: apiHelper,
            ),
            sharedPreferences: sharedPreferences,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminProvider(
            repository: UserManagementRepository(
              client: http.Client(),
              apiHelper: apiHelper,
            ),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AlertsProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CameraProvider(apiClient: apiClient),
        ),
      ],
      child: const CognoApp(),
    ),
  );
}

class CognoApp extends StatelessWidget {
  const CognoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cognoclean',
      theme: AppTheme.lightTheme,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _initialCheckDone = false;
  
  @override
  void initState() {
    super.initState();
    // This ensures the check runs only on first mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialCheckDone && mounted) {
        setState(() {
          _initialCheckDone = true;
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Only show splash screen during the initial check
    if (authProvider.isLoading && !_initialCheckDone) {
      return const SplashScreen();
    }
    
    if (authProvider.isAuthenticated) {
      // Check if zone and ward selection is required
      if (authProvider.requireZoneWardSelection) {
        return const ZoneWardSelectionScreen();
      } else {
        // All users go to map dashboard regardless of role
        return const GoogleMapsDashboardScreen();
      }
    } else {
      return const LoginScreen();
    }
  }
}
