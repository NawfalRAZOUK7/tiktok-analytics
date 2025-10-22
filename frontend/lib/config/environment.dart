// Environment Configuration for Flutter
// This class manages environment-specific settings

class Environment {
  // Current environment
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  static const int apiTimeout = int.fromEnvironment(
    'API_TIMEOUT',
    defaultValue: 30,
  );

  // App Configuration
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'TikTok Analytics',
  );

  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  // Feature Flags
  static const bool enableDebugMode = bool.fromEnvironment(
    'ENABLE_DEBUG_MODE',
    defaultValue: true,
  );

  static const bool enableLogging = bool.fromEnvironment(
    'ENABLE_LOGGING',
    defaultValue: true,
  );

  // Helper methods
  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
  static bool get isStaging => environment == 'staging';

  // Logging helper
  static void log(String message) {
    if (enableLogging && !isProduction) {
      print('[${DateTime.now()}] $message');
    }
  }

  // Get full configuration as map
  static Map<String, dynamic> getConfig() {
    return {
      'environment': environment,
      'apiBaseUrl': apiBaseUrl,
      'apiTimeout': apiTimeout,
      'appName': appName,
      'appVersion': appVersion,
      'enableDebugMode': enableDebugMode,
      'enableLogging': enableLogging,
      'isDevelopment': isDevelopment,
      'isProduction': isProduction,
      'isStaging': isStaging,
    };
  }

  // Print configuration (for debugging)
  static void printConfig() {
    if (!isProduction) {
      print('=== Environment Configuration ===');
      getConfig().forEach((key, value) {
        print('$key: $value');
      });
      print('================================');
    }
  }
}
