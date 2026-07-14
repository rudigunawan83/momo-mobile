import 'package:flutter_test/flutter_test.dart';
import 'package:momo_app/domain/repositories/i_chat_repository.dart';
import 'package:momo_app/services/offline_message_cache.dart';

ChatMessage _createMessage(String id, {DateTime? createdAt}) {
  return ChatMessage(
    id: id,
    userId: 'user-1',
    role: 'user',
    content: 'Message $id',
    type: 'text',
    createdAt: createdAt ?? DateTime.now(),
  );
}

void main() {
  group('OfflineMessageCache', () {
    group('initial state', () {
      test('starts with empty cache', () {
        final cache = OfflineMessageCache();
        expect(cache.messages, isEmpty);
        expect(cache.messageCount, 0);
      });
    });

    group('updateCache', () {
      test('stores messages', () {
        final cache = OfflineMessageCache();
        final messages = List.generate(5, (i) => _createMessage('$i'));

        cache.updateCache(messages);

        expect(cache.messageCount, 5);
        expect(cache.messages.length, 5);
      });

      test('limits to 50 most recent messages', () {
        final cache = OfflineMessageCache();
        final messages = List.generate(60, (i) => _createMessage('$i'));

        cache.updateCache(messages);

        expect(cache.messageCount, OfflineMessageCache.maxCachedMessages);
        expect(cache.messageCount, 50);
        // Should keep the first 50 (most recent)
        expect(cache.messages.first.id, '0');
        expect(cache.messages.last.id, '49');
      });

      test('replaces previous cache entirely', () {
        final cache = OfflineMessageCache();
        cache.updateCache([_createMessage('old-1'), _createMessage('old-2')]);
        cache.updateCache([_createMessage('new-1')]);

        expect(cache.messageCount, 1);
        expect(cache.messages.first.id, 'new-1');
      });
    });

    group('addMessage', () {
      test('adds message at the beginning (most recent first)', () {
        final cache = OfflineMessageCache();
        cache.updateCache([_createMessage('existing')]);

        cache.addMessage(_createMessage('new'));

        expect(cache.messages.first.id, 'new');
        expect(cache.messages.last.id, 'existing');
      });

      test('removes oldest message when exceeding max capacity', () {
        final cache = OfflineMessageCache();
        final messages = List.generate(50, (i) => _createMessage('msg-$i'));
        cache.updateCache(messages);

        cache.addMessage(_createMessage('overflow'));

        expect(cache.messageCount, 50);
        expect(cache.messages.first.id, 'overflow');
        // Oldest message should be gone
        expect(cache.messages.any((m) => m.id == 'msg-49'), isFalse);
      });
    });

    group('getOfflineMessages', () {
      test('returns unmodifiable list', () {
        final cache = OfflineMessageCache();
        cache.updateCache([_createMessage('1')]);

        final offlineMessages = cache.getOfflineMessages();

        expect(() => (offlineMessages as List).add(_createMessage('x')),
            throwsA(isA<UnsupportedError>()));
      });

      test('returns current cached messages', () {
        final cache = OfflineMessageCache();
        final messages = [_createMessage('a'), _createMessage('b')];
        cache.updateCache(messages);

        expect(cache.getOfflineMessages().length, 2);
      });
    });

    group('clear', () {
      test('removes all cached messages', () {
        final cache = OfflineMessageCache();
        cache.updateCache(List.generate(10, (i) => _createMessage('$i')));

        cache.clear();

        expect(cache.messageCount, 0);
        expect(cache.messages, isEmpty);
      });
    });

    group('constants', () {
      test('maxCachedMessages is 50', () {
        expect(OfflineMessageCache.maxCachedMessages, 50);
      });
    });
  });
}
