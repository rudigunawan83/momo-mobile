import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment Configuration
class EnvConfig {
  static late final String _environment;
  static late final String _apiBaseUrl;
  static late final String _liveKitUrl;
  static late final String _liveKitApiKey;
  static late final String _liveKitApiSecret;
  static late final String _logLevel;

  /// Initialize environment from .env file
  static Future<void> init({String environment = 'development'}) async {
    _environment = environment;

    // Load environment file
    final envFile = '.env.$environment';
    await dotenv.load(fileName: envFile);

    _apiBaseUrl = dotenv.get('API_BASE_URL', fallback: 'http://localhost:5000');
    _liveKitUrl = dotenv.get('LIVEKIT_URL', fallback: 'ws://localhost:7880');
    _liveKitApiKey = dotenv.get('LIVEKIT_API_KEY', fallback: '');
    _liveKitApiSecret = dotenv.get('LIVEKIT_API_SECRET', fallback: '');
    _logLevel = dotenv.get('LOG_LEVEL', fallback: 'debug');
  }

  // Getters
  static String get environment => _environment;
  static String get apiBaseUrl => _apiBaseUrl;
  static String get liveKitUrl => _liveKitUrl;
  static String get liveKitApiKey => _liveKitApiKey;
  static String get liveKitApiSecret => _liveKitApiSecret;
  static String get logLevel => _logLevel;

  // Computed properties
  static bool get isDevelopment => _environment == 'development';
  static bool get isStaging => _environment == 'staging';
  static bool get isProduction => _environment == 'production';

  /// Get full API URL
  static String getApiUrl(String endpoint) {
    return '$apiBaseUrl/api/v1$endpoint';
  }
}
