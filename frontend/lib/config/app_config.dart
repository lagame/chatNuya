class AppConfig {
  static const String _defaultApiBaseUrl = 'https://chatnuya.onrender.com';

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultApiBaseUrl,
  );

  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: apiBaseUrl,
  );
}
