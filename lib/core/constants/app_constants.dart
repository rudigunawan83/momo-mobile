/// App Constants
class AppConstants {
  AppConstants._();

  // API
  static const String apiVersion = '/api/v1';
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int apiRetryCount = 3;

  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String conversationKey = 'conversations';

  // Chat
  static const int maxMessageLength = 2000;
  static const int typingIndicatorDuration = 1000; // milliseconds

  // Pagination
  static const int pageSize = 20;

  // Retry Policy
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(milliseconds: 500);
}

/// API Endpoints
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';

  // User
  static const String userMe = '/users/me';
  static const String userProfile = '/users/profile';

  // Chat — sesuai ChatController routes di API
  static const String conversations = '/conversations';
  static const String chatMessage = '/chat/message';         // POST — non-streaming
  static const String chatStream = '/chat/stream';           // POST — SSE streaming
  static const String chatMessages = '/chat/messages';       // legacy alias
  static const String chatHistory = '/chat/history';         // GET /{userId}

  // Memory
  static const String memory = '/memory';

  // Mood
  static const String mood = '/mood';

  // Mission
  static const String missions = '/missions';
  static const String missionsActive = '/missions/active';

  // XP & Profile
  static const String profileXp = '/profile/xp';
  static const String profileRelationship = '/profile/relationship';

  // Voice (LiveKit)
  static const String voiceToken = '/voice/token';
  static const String voiceSession = '/voice/session';
}

/// Error Messages - User-friendly
class ErrorMessages {
  ErrorMessages._();

  static const String networkError = 'Momo sedang mengalami sedikit gangguan.\nCoba lagi sebentar ya.';
  static const String timeoutError = 'Koneksi terputus. Coba lagi ya.';
  static const String serverError = 'Momo sedang sibuk. Coba lagi nanti.';
  static const String unauthorizedError = 'Session kamu sudah berakhir. Silakan login kembali.';
  static const String notFoundError = 'Data tidak ditemukan.';
  static const String genericError = 'Terjadi kesalahan. Coba lagi ya.';
  static const String offlineError = 'Kamu sedang offline. Cek koneksi internet mu.';
}

/// Duration Constants
class AppDurations {
  AppDurations._();

  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 500);
  static const Duration longAnimation = Duration(milliseconds: 1000);

  static const Duration debounceDelay = Duration(milliseconds: 300);
  static const Duration throttleDelay = Duration(milliseconds: 500);

  static const Duration snackBarDuration = Duration(seconds: 3);
  static const Duration dialogDuration = Duration(seconds: 2);
}
