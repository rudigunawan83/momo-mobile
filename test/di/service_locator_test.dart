import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:momo_app/data/realtime/signalr_client.dart';
import 'package:momo_app/di/service_locator.dart';
import 'package:momo_app/di/signalr_bloc_bridge.dart';
import 'package:momo_app/domain/engines/i_character_engine.dart';
import 'package:momo_app/domain/engines/i_emotion_engine.dart';
import 'package:momo_app/domain/services/virtual_room/i_virtual_room_manager.dart';
import 'package:momo_app/services/connectivity_monitor.dart';
import 'package:momo_app/services/offline_message_cache.dart';
import 'package:momo_app/services/offline_message_queue.dart';
import 'package:momo_app/services/offline_mode_manager.dart';
import 'package:momo_app/services/token_refresh_service.dart';

void main() {
  setUp(() async {
    await GetIt.instance.reset();
    await configureDependencies();
  });

  tearDown(() async {
    await resetDependencies();
  });

  group('Service Locator Configuration', () {
    test('registers ConnectivityMonitor as singleton', () {
      final instance1 = sl<ConnectivityMonitor>();
      final instance2 = sl<ConnectivityMonitor>();
      expect(instance1, same(instance2));
    });

    test('registers TokenRefreshService as singleton', () {
      final instance1 = sl<TokenRefreshService>();
      final instance2 = sl<TokenRefreshService>();
      expect(instance1, same(instance2));
    });

    test('registers OfflineMessageCache as singleton', () {
      final instance1 = sl<OfflineMessageCache>();
      final instance2 = sl<OfflineMessageCache>();
      expect(instance1, same(instance2));
    });

    test('registers OfflineMessageQueue as singleton', () {
      final instance1 = sl<OfflineMessageQueue>();
      final instance2 = sl<OfflineMessageQueue>();
      expect(instance1, same(instance2));
    });

    test('registers OfflineModeManager as singleton', () {
      final instance1 = sl<OfflineModeManager>();
      final instance2 = sl<OfflineModeManager>();
      expect(instance1, same(instance2));
    });

    test('registers SignalRClient as singleton', () {
      final instance1 = sl<SignalRClient>();
      final instance2 = sl<SignalRClient>();
      expect(instance1, same(instance2));
    });

    test('registers IEmotionEngine as singleton', () {
      final instance1 = sl<IEmotionEngine>();
      final instance2 = sl<IEmotionEngine>();
      expect(instance1, same(instance2));
    });

    test('registers ICharacterEngine as singleton', () {
      final instance1 = sl<ICharacterEngine>();
      final instance2 = sl<ICharacterEngine>();
      expect(instance1, same(instance2));
    });

    test('registers IVirtualRoomManager as singleton', () {
      final instance1 = sl<IVirtualRoomManager>();
      final instance2 = sl<IVirtualRoomManager>();
      expect(instance1, same(instance2));
    });

    test('registers SignalRBlocBridge as singleton', () {
      final instance1 = sl<SignalRBlocBridge>();
      final instance2 = sl<SignalRBlocBridge>();
      expect(instance1, same(instance2));
    });

    test('SignalRBlocBridge receives same engine instances', () {
      final bridge = sl<SignalRBlocBridge>();
      expect(bridge, isNotNull);
      expect(bridge.signalRClient, same(sl<SignalRClient>()));
    });
  });

  group('resetDependencies', () {
    test('clears all registrations', () async {
      // Resolve something first
      sl<IEmotionEngine>();

      await resetDependencies();

      expect(() => sl<IEmotionEngine>(), throwsA(isA<Error>()));
    });
  });
}
