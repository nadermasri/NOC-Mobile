const String _envBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);

class AppConstants {
  AppConstants._();

  static const String appName = 'Pocket NOC';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Network diagnostics and infrastructure toolkit';

  /// Set at build time via --dart-define=API_BASE_URL=https://api.pocketnoc.app
  static const String baseUrl = _envBaseUrl;
  static const String apiPrefix = '/api';

  static const Duration pingTimeout = Duration(seconds: 5);
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);

  static const int defaultPingCount = 5;
  static const int defaultTracerouteMaxHops = 30;
  static const int defaultPortTimeout = 3;

  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String darkModeKey = 'dark_mode';
  static const String targetsBoxName = 'targets';
  static const String resultsBoxName = 'results';
  static const String settingsBoxName = 'settings';

  static const List<String> dnsRecordTypes = [
    'A',
    'AAAA',
    'CNAME',
    'MX',
    'TXT',
    'NS',
  ];

  static const List<int> commonPorts = [
    21, 22, 23, 25, 53, 80, 110, 143, 443, 465, 587, 993, 995,
    3306, 3389, 5432, 5900, 6379, 8080, 8443, 27017,
  ];
}
