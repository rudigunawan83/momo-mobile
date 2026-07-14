import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:momo_app/domain/repositories/i_chat_repository.dart';
import 'package:momo_app/services/connectivity_monitor.dart';
import 'package:momo_app/services/offline_message_cache.dart';
import 'package:momo_app/services/offline_message_queue.dart';
import 'package:momo_app/services/offline_mode_manager.dart';
import 'package:momo_app/services/token_refresh_service.dart';

void main() {
  late ConnectivityMonitor connectivityMonitor;
  late OfflineMessageCache messageCache;
  late OfflineMessageQueue messageQueue;
  late TokenRefreshService tokenRefreshService;
  late OfflineModeManager manager;
  late List<QueuedMessage> syncedMessages;
  late bool syncSuccess;

  setUp(() {
    syncedMessages = [];
    syncSuccess = true;

    connectivityMonitor = ConnectivityMonitor(
      connectivityChecker: () async => true,
      initialStatus: ConnectivityStatus.online,
    );

    messageCache = OfflineMessageCache();
    messageQueue = OfflineMessageQueue();
    tokenRefreshService = TokenRefreshService(
      refreshToken: () async => true,
      persistDrafts: (_) async {},
      redirectToLogin: () {},
    );

    manager = OfflineModeManager(
      connectivityMonitor: connectivityMonitor,
      messageCache: messageCache,
      messageQueue: messageQueue,
      tokenRefreshService: tokenRefreshService,
      messageSyncer: (messages) async {
        syncedMessages.addAll(messages);
        return syncSuccess;
      },
    );
  });

  tearDown(() {
    manager.dispose();
    connectivityMonitor.dispose();
  });

  group('OfflineModeManager', () {
    group('initial state', () {
      test('starts in online mode', () {
        expect(manager.currentMode, AppConnectivityMode.online);
        expect(manager.isOnline, true);
        expect(manager.isOffline, false);
      });

      test('queue is not at capacity initially', () {
        expect(manager.isQueueAtCapacity, false);
      });
    });

    group('connectivity changes', () {
      test('switches to offline mode when connectivity is lost', () async {
        final states = <OfflineModeState>[];
        manager.stateStream.listen(states.add);
        manager.start();

        // Simulate going offline
        connectivityMonitor.checkNow(); // Triggers check
        // We need to manually trigger the status change since our mock always returns true
        // Instead, let's create a controllable monitor

        // Verify via a custom connectivity monitor
        final offlineMonitor = ConnectivityMonitor(
          connectivityChecker: () async => false,
          initialStatus: ConnectivityStatus.online,
        );

        final offlineManager = OfflineModeManager(
          connectivityMonitor: offlineMonitor,
          messageCache: messageCache,
          messageQueue: messageQueue,
          tokenRefreshService: tokenRefreshService,
          messageSyncer: (messages) async => true,
        );

        final offlineStates = <OfflineModeState>[];
        offlineManager.stateStream.listen(offlineStates.add);
        offlineManager.start();

        await offlineMonitor.start();
        await Future<void>.delayed(Duration.zero);

        expect(offlineManager.isOffline, true);
        expect(offlineManager.currentMode, AppConnectivityMode.offline);

        offlineManager.dispose();
        offlineMonitor.dispose();
      });

      test('switches back to online mode when connectivity is restored',
          () async {
        bool isOnline = false;
        final monitor = ConnectivityMonitor(
          connectivityChecker: () async => isOnline,
          initialStatus: ConnectivityStatus.offline,
        );

        final mgr = OfflineModeManager(
          connectivityMonitor: monitor,
          messageCache: messageCache,
          messageQueue: OfflineMessageQueue(),
          tokenRefreshService: tokenRefreshService,
          messageSyncer: (messages) async => true,
        );

        mgr.start();

        // Start offline
        await monitor.start();
        await Future<void>.delayed(Duration.zero);
        expect(mgr.isOffline, true);

        // Go online
        isOnline = true;
        await monitor.checkNow();
        await Future<void>.delayed(Duration.zero);
        expect(mgr.isOnline, true);

        mgr.dispose();
        monitor.dispose();
      });
    });

    group('queueMessage', () {
      test('queues message and returns success', () {
        final result = manager.queueMessage(QueuedMessage(
          id: '1',
          content: 'Hello',
          type: 'text',
          queuedAt: DateTime.now(),
        ));

        expect(result, EnqueueResult.success);
        expect(manager.messageQueue.queueLength, 1);
      });

      test('returns queueFull when at capacity', () {
        // Fill queue to capacity
        for (int i = 0; i < 20; i++) {
          manager.queueMessage(QueuedMessage(
            id: '$i',
            content: 'Message $i',
            type: 'text',
            queuedAt: DateTime.now(),
          ));
        }

        final result = manager.queueMessage(QueuedMessage(
          id: 'overflow',
          content: 'Cannot send',
          type: 'text',
          queuedAt: DateTime.now(),
        ));

        expect(result, EnqueueResult.queueFull);
        expect(manager.isQueueAtCapacity, true);
      });
    });

    group('auto-sync on reconnect', () {
      test('syncs queued messages when connectivity is restored', () async {
        bool isOnline = false;
        final monitor = ConnectivityMonitor(
          connectivityChecker: () async => isOnline,
          initialStatus: ConnectivityStatus.offline,
        );

        final queue = OfflineMessageQueue();
        final synced = <QueuedMessage>[];

        final mgr = OfflineModeManager(
          connectivityMonitor: monitor,
          messageCache: messageCache,
          messageQueue: queue,
          tokenRefreshService: tokenRefreshService,
          messageSyncer: (messages) async {
            synced.addAll(messages);
            return true;
          },
        );

        mgr.start();
        await monitor.start();
        await Future<void>.delayed(Duration.zero);

        // Queue messages while offline
        queue.enqueue(QueuedMessage(
          id: '1',
          content: 'Offline msg 1',
          type: 'text',
          queuedAt: DateTime.now(),
        ));
        queue.enqueue(QueuedMessage(
          id: '2',
          content: 'Offline msg 2',
          type: 'text',
          queuedAt: DateTime.now(),
        ));

        // Go online — should trigger sync
        isOnline = true;
        await monitor.checkNow();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(synced.length, 2);
        expect(synced[0].id, '1');
        expect(synced[1].id, '2');
        expect(queue.queueLength, 0);

        mgr.dispose();
        monitor.dispose();
      });
    });

    group('getOfflineMessages', () {
      test('returns cached messages for offline display', () {
        final messages = [
          ChatMessage(
            id: '1',
            userId: 'user-1',
            role: 'user',
            content: 'Hello',
            type: 'text',
            createdAt: DateTime.now(),
          ),
          ChatMessage(
            id: '2',
            userId: 'user-1',
            role: 'assistant',
            content: 'Hi there!',
            type: 'text',
            createdAt: DateTime.now(),
          ),
        ];
        manager.updateMessageCache(messages);

        final offlineMessages = manager.getOfflineMessages();

        expect(offlineMessages.length, 2);
        expect(offlineMessages.first.id, '1');
      });
    });

    group('handleTokenExpired', () {
      test('delegates to token refresh service', () async {
        final result = await manager.handleTokenExpired();
        expect(result, TokenRefreshResult.success);
      });

      test('preserves drafts on failure', () async {
        List<String>? persistedDrafts;
        bool redirected = false;

        final failingTokenService = TokenRefreshService(
          refreshToken: () async => false,
          persistDrafts: (drafts) async => persistedDrafts = drafts,
          redirectToLogin: () => redirected = true,
        );

        final mgr = OfflineModeManager(
          connectivityMonitor: connectivityMonitor,
          messageCache: messageCache,
          messageQueue: messageQueue,
          tokenRefreshService: failingTokenService,
          messageSyncer: (messages) async => true,
        );

        final result = await mgr.handleTokenExpired(
          unsentDrafts: ['my draft message'],
        );

        expect(result, TokenRefreshResult.failure);
        expect(persistedDrafts, ['my draft message']);
        expect(redirected, true);

        mgr.dispose();
      });
    });

    group('stateStream', () {
      test('emits state changes', () async {
        final states = <OfflineModeState>[];
        manager.stateStream.listen(states.add);

        manager.queueMessage(QueuedMessage(
          id: '1',
          content: 'Hello',
          type: 'text',
          queuedAt: DateTime.now(),
        ));
        await Future<void>.delayed(Duration.zero);

        expect(states.isNotEmpty, true);
        expect(states.last.pendingMessageCount, 1);
        expect(states.last.isQueueAtCapacity, false);
      });
    });
  });
}
