import 'package:flutter_test/flutter_test.dart';
import 'package:momo_app/services/offline_message_queue.dart';

QueuedMessage _createQueuedMessage(String id) {
  return QueuedMessage(
    id: id,
    content: 'Message $id',
    type: 'text',
    queuedAt: DateTime.now(),
  );
}

void main() {
  group('OfflineMessageQueue', () {
    group('initial state', () {
      test('starts empty', () {
        final queue = OfflineMessageQueue();
        expect(queue.queueLength, 0);
        expect(queue.isAtCapacity, false);
        expect(queue.hasPendingMessages, false);
        expect(queue.pendingMessages, isEmpty);
        queue.dispose();
      });
    });

    group('enqueue', () {
      test('adds message to queue and returns success', () {
        final queue = OfflineMessageQueue();
        final result = queue.enqueue(_createQueuedMessage('1'));

        expect(result, EnqueueResult.success);
        expect(queue.queueLength, 1);
        expect(queue.hasPendingMessages, true);
        queue.dispose();
      });

      test('allows up to 20 messages', () {
        final queue = OfflineMessageQueue();

        for (int i = 0; i < 20; i++) {
          final result = queue.enqueue(_createQueuedMessage('$i'));
          expect(result, EnqueueResult.success);
        }

        expect(queue.queueLength, 20);
        expect(queue.isAtCapacity, true);
        queue.dispose();
      });

      test('returns queueFull when at capacity', () {
        final queue = OfflineMessageQueue();

        // Fill to capacity
        for (int i = 0; i < 20; i++) {
          queue.enqueue(_createQueuedMessage('$i'));
        }

        // 21st message should be rejected
        final result = queue.enqueue(_createQueuedMessage('overflow'));

        expect(result, EnqueueResult.queueFull);
        expect(queue.queueLength, 20);
        queue.dispose();
      });

      test('does not add message when queueFull', () {
        final queue = OfflineMessageQueue();

        for (int i = 0; i < 20; i++) {
          queue.enqueue(_createQueuedMessage('$i'));
        }

        queue.enqueue(_createQueuedMessage('should-not-exist'));

        expect(
          queue.pendingMessages.any((m) => m.id == 'should-not-exist'),
          isFalse,
        );
        queue.dispose();
      });
    });

    group('drainQueue', () {
      test('returns all queued messages', () {
        final queue = OfflineMessageQueue();
        queue.enqueue(_createQueuedMessage('1'));
        queue.enqueue(_createQueuedMessage('2'));
        queue.enqueue(_createQueuedMessage('3'));

        final drained = queue.drainQueue();

        expect(drained.length, 3);
        expect(drained[0].id, '1');
        expect(drained[1].id, '2');
        expect(drained[2].id, '3');
      });

      test('clears the queue after drain', () {
        final queue = OfflineMessageQueue();
        queue.enqueue(_createQueuedMessage('1'));

        queue.drainQueue();

        expect(queue.queueLength, 0);
        expect(queue.isAtCapacity, false);
        expect(queue.hasPendingMessages, false);
        queue.dispose();
      });

      test('returns empty list when queue is empty', () {
        final queue = OfflineMessageQueue();
        final drained = queue.drainQueue();

        expect(drained, isEmpty);
        queue.dispose();
      });
    });

    group('removeMessage', () {
      test('removes specific message by id', () {
        final queue = OfflineMessageQueue();
        queue.enqueue(_createQueuedMessage('1'));
        queue.enqueue(_createQueuedMessage('2'));
        queue.enqueue(_createQueuedMessage('3'));

        queue.removeMessage('2');

        expect(queue.queueLength, 2);
        expect(queue.pendingMessages.any((m) => m.id == '2'), isFalse);
        queue.dispose();
      });

      test('does nothing for non-existent id', () {
        final queue = OfflineMessageQueue();
        queue.enqueue(_createQueuedMessage('1'));

        queue.removeMessage('non-existent');

        expect(queue.queueLength, 1);
        queue.dispose();
      });
    });

    group('clear', () {
      test('removes all messages from queue', () {
        final queue = OfflineMessageQueue();
        for (int i = 0; i < 5; i++) {
          queue.enqueue(_createQueuedMessage('$i'));
        }

        queue.clear();

        expect(queue.queueLength, 0);
        expect(queue.isAtCapacity, false);
        queue.dispose();
      });
    });

    group('stateStream', () {
      test('emits state on enqueue', () async {
        final queue = OfflineMessageQueue();
        final states = <OfflineQueueState>[];
        queue.stateStream.listen(states.add);

        queue.enqueue(_createQueuedMessage('1'));
        await Future<void>.delayed(Duration.zero);

        expect(states.length, 1);
        expect(states.first.pendingCount, 1);
        expect(states.first.isAtCapacity, false);
        queue.dispose();
      });

      test('emits capacity state when queue is full', () async {
        final queue = OfflineMessageQueue();
        final states = <OfflineQueueState>[];
        queue.stateStream.listen(states.add);

        for (int i = 0; i < 20; i++) {
          queue.enqueue(_createQueuedMessage('$i'));
        }
        await Future<void>.delayed(Duration.zero);

        final lastState = states.last;
        expect(lastState.pendingCount, 20);
        expect(lastState.isAtCapacity, true);
        queue.dispose();
      });

      test('emits state on drain', () async {
        final queue = OfflineMessageQueue();
        queue.enqueue(_createQueuedMessage('1'));

        final states = <OfflineQueueState>[];
        queue.stateStream.listen(states.add);

        queue.drainQueue();
        await Future<void>.delayed(Duration.zero);

        expect(states.last.pendingCount, 0);
        expect(states.last.isAtCapacity, false);
        queue.dispose();
      });
    });

    group('constants', () {
      test('maxQueueSize is 20', () {
        expect(OfflineMessageQueue.maxQueueSize, 20);
      });
    });
  });
}
