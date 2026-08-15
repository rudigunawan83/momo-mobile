/// Analytics Service - abstraction untuk analytics provider
abstract class AnalyticsService {
  /// Log event
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters});

  /// Log screen view
  Future<void> logScreenView(String screenName);

  /// Log user properties
  Future<void> setUserProperties(String userId, {required Map<String, dynamic> properties});

  /// Log error
  Future<void> logError(dynamic error, {StackTrace? stackTrace});
}

/// Analytics Service Implementation - dapat diganti dengan Firebase, Segment, etc
class AnalyticsServiceImpl implements AnalyticsService {
  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    // TODO: Implement dengan provider pilihan (Firebase, Segment, etc)
    print('📊 Analytics Event: $name - $parameters');
  }

  @override
  Future<void> logScreenView(String screenName) async {
    print('📊 Analytics Screen: $screenName');
  }

  @override
  Future<void> setUserProperties(String userId, {required Map<String, dynamic> properties}) async {
    print('📊 Analytics User: $userId - $properties');
  }

  @override
  Future<void> logError(dynamic error, {StackTrace? stackTrace}) async {
    print('📊 Analytics Error: $error');
  }
}

/// Events enum
enum AnalyticsEvent {
  appOpen('app_open'),
  chatStarted('chat_started'),
  messageSent('message_sent'),
  messageReceived('message_received'),
  voiceStarted('voice_started'),
  voiceCompleted('voice_completed'),
  missionStarted('mission_started'),
  missionCompleted('mission_completed'),
  moodOpened('mood_opened'),
  musicOpened('music_opened'),
  cameraOpened('camera_opened'),
  levelUp('level_up'),
  relationshipLevelUp('relationship_level_up'),
  ;

  final String value;
  const AnalyticsEvent(this.value);
}
