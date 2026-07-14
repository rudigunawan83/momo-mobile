import 'package:get_it/get_it.dart';

import '../data/realtime/signalr_client.dart';
import '../domain/engines/character_engine.dart';
import '../domain/engines/emotion_engine.dart';
import '../domain/engines/i_character_engine.dart';
import '../domain/engines/i_emotion_engine.dart';
import '../domain/services/virtual_room/i_virtual_room_manager.dart';
import '../domain/services/virtual_room/virtual_room_manager.dart';
import '../services/connectivity_monitor.dart';
import '../services/offline_message_cache.dart';
import '../services/offline_message_queue.dart';
import '../services/offline_mode_manager.dart';
import '../services/token_refresh_service.dart';
import 'signalr_bloc_bridge.dart';

/// Global service locator instance.
final GetIt sl = GetIt.instance;

/// Configures all dependency injection registrations for the Momo app.
///
/// Must be called before [runApp] in main.dart.
///
/// Registration order:
/// 1. External services & configuration
/// 2. Infrastructure (connectivity, SignalR, caching)
/// 3. Domain engines (Emotion, Character)
/// 4. Domain services (VirtualRoomManager)
/// 5. Coordination (SignalRBlocBridge)
///
/// Requirements: 1.1, 3.1, 4.6, 7.1, 8.3, 9.1
Future<void> configureDependencies() async {
  // --- Infrastructure ---

  // Connectivity Monitor
  sl.registerLazySingleton<ConnectivityMonitor>(
    () => ConnectivityMonitor(
      connectivityChecker: () async => true, // replaced with real check at app init
    ),
  );

  // Token Refresh Service
  sl.registerLazySingleton<TokenRefreshService>(
    () => TokenRefreshService(
      refreshToken: () async => true, // wired to Supabase at app init
      persistDrafts: (drafts) async {}, // wired to local storage at app init
      redirectToLogin: () {}, // wired to navigator at app init
    ),
  );

  // Offline Message Cache
  sl.registerLazySingleton<OfflineMessageCache>(
    () => OfflineMessageCache(),
  );

  // Offline Message Queue
  sl.registerLazySingleton<OfflineMessageQueue>(
    () => OfflineMessageQueue(),
  );

  // Offline Mode Manager
  sl.registerLazySingleton<OfflineModeManager>(
    () => OfflineModeManager(
      connectivityMonitor: sl<ConnectivityMonitor>(),
      messageCache: sl<OfflineMessageCache>(),
      messageQueue: sl<OfflineMessageQueue>(),
      tokenRefreshService: sl<TokenRefreshService>(),
      messageSyncer: (messages) async => true, // wired to repository at app init
    ),
  );

  // SignalR Client
  sl.registerLazySingleton<SignalRClient>(
    () => SignalRClient(
      config: const SignalRClientConfig(
        hubUrl: 'https://api.momo.app/hubs/chat',
      ),
    ),
  );

  // --- Domain Engines ---

  // Emotion Engine (singleton — state persists across app lifecycle)
  sl.registerLazySingleton<IEmotionEngine>(
    () => EmotionEngine(),
  );

  // Character Engine (singleton — manages visual state across screens)
  sl.registerLazySingleton<ICharacterEngine>(
    () => CharacterEngine(),
  );

  // --- Domain Services ---

  // Virtual Room Manager (singleton — manages room state and friendship-based unlocks)
  sl.registerLazySingleton<IVirtualRoomManager>(
    () => VirtualRoomManager(friendshipLevel: 1),
  );

  // --- Coordination Layer ---

  // SignalR ↔ BLoC Bridge: wires real-time events to engine/state updates
  sl.registerLazySingleton<SignalRBlocBridge>(
    () => SignalRBlocBridge(
      signalRClient: sl<SignalRClient>(),
      emotionEngine: sl<IEmotionEngine>(),
      characterEngine: sl<ICharacterEngine>(),
      virtualRoomManager: sl<IVirtualRoomManager>(),
    ),
  );
}

/// Disposes all registered singletons and resets the service locator.
///
/// Call this during app teardown or test cleanup.
Future<void> resetDependencies() async {
  await sl.reset();
}
