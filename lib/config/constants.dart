class AppConstants {
  // API URLs
  static const String BASE_URL = 'https://api.yogh.com'; // Production API URL
  static const String API_URL = '$BASE_URL/api';
  static const String LOGIN_URL = '$API_URL/auth/login';
  static const String LOGOUT_URL = '$API_URL/auth/logout';
  static const String REGISTER_URL = '$API_URL/auth/register';
  static const String PROFILE_URL = '$API_URL/auth/me';
  static const String NEARBY_ISSUES_URL = '$API_URL/mobile/nearby';
  static const String ISSUE_DETAIL_URL = '$API_URL/mobile/detail';
  static const String RESOLVE_ISSUE_URL = '$API_URL/mobile';

  // Storage Keys
  static const String TOKEN_KEY = 'token';
  static const String USER_ROLE_KEY = 'user_role';
  static const String REMEMBER_ME_KEY = 'remember_me';
  static const String SAVED_EMAIL_KEY = 'saved_email';

  // App Settings
  static const double DEFAULT_SEARCH_RADIUS_KM = 5.0;
  
  // Error Messages
  static const String NETWORK_ERROR = 'Network error. Please check your connection.';
  static const String GENERIC_ERROR = 'Something went wrong. Please try again.';
  static const String LOCATION_PERMISSION_DENIED = 'Location permissions are required for this app.';
  static const String CAMERA_PERMISSION_DENIED = 'Camera permission is required to take photos.';

  // Location Validation
  static const double MAX_DISTANCE_KM = 0.5; // Maximum distance to resolve an issue

  // Alert System Settings
  static const Duration DEFAULT_ALERT_CHECK_INTERVAL = Duration(minutes: 30);
  static const Duration OVERDUE_THRESHOLD = Duration(hours: 24);
  static const Duration CRITICAL_THRESHOLD = Duration(hours: 12);
  static const Duration REMINDER_THRESHOLD = Duration(hours: 48);
  static const int MAX_ALERTS_HISTORY_DAYS = 30;
  
  // Notification Settings
  static const bool ENABLE_PUSH_NOTIFICATIONS = true;
  static const bool ENABLE_EMAIL_NOTIFICATIONS = true;
  static const bool ENABLE_SMS_NOTIFICATIONS = false;
  static const bool ENABLE_IN_APP_NOTIFICATIONS = true;
  
  // Alert Messages
  static const String ALERT_OVERDUE_TITLE = 'Issue Overdue';
  static const String ALERT_CRITICAL_TITLE = 'Critical Issue Alert';
  static const String ALERT_REMINDER_TITLE = 'Issue Reminder';
  
  // Roles that can receive alerts
  static const List<String> ALERT_RECIPIENT_ROLES = ['admin', 'manager'];
}
