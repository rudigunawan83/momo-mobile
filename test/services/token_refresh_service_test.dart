import 'package:flutter_test/flutter_test.dart';
import 'package:momo_app/services/token_refresh_service.dart';

void main() {
  group('TokenRefreshService', () {
    group('attemptRefresh - success', () {
      test('returns success when token refresh succeeds', () async {
        final service = TokenRefreshService(
          refreshToken: () async => true,
          persistDrafts: (_) async {},
          redirectToLogin: () {},
        );

        final result = await service.attemptRefresh();

        expect(result, TokenRefreshResult.success);
        service.dispose();
      });

      test('does not redirect to login on success', () async {
        bool redirected = false;
        final service = TokenRefreshService(
          refreshToken: () async => true,
          persistDrafts: (_) async {},
          redirectToLogin: () => redirected = true,
        );

        await service.attemptRefresh();

        expect(redirected, false);
        service.dispose();
      });

      test('does not persist drafts on success', () async {
        bool draftsPersisted = false;
        final service = TokenRefreshService(
          refreshToken: () async => true,
          persistDrafts: (_) async => draftsPersisted = true,
          redirectToLogin: () {},
        );

        await service.attemptRefresh(unsentDrafts: ['draft']);

        expect(draftsPersisted, false);
        service.dispose();
      });

      test('emits refreshStarted then refreshSucceeded events', () async {
        final service = TokenRefreshService(
          refreshToken: () async => true,
          persistDrafts: (_) async {},
          redirectToLogin: () {},
        );

        final events = <TokenRefreshEvent>[];
        service.eventStream.listen(events.add);

        await service.attemptRefresh();
        await Future<void>.delayed(Duration.zero);

        expect(events, contains(TokenRefreshEvent.refreshStarted));
        expect(events, contains(TokenRefreshEvent.refreshSucceeded));
        expect(events, isNot(contains(TokenRefreshEvent.refreshFailed)));
        service.dispose();
      });
    });

    group('attemptRefresh - failure', () {
      test('returns failure when token refresh fails', () async {
        final service = TokenRefreshService(
          refreshToken: () async => false,
          persistDrafts: (_) async {},
          redirectToLogin: () {},
        );

        final result = await service.attemptRefresh();

        expect(result, TokenRefreshResult.failure);
        service.dispose();
      });

      test('redirects to login on failure', () async {
        bool redirected = false;
        final service = TokenRefreshService(
          refreshToken: () async => false,
          persistDrafts: (_) async {},
          redirectToLogin: () => redirected = true,
        );

        await service.attemptRefresh();

        expect(redirected, true);
        service.dispose();
      });

      test('persists unsent drafts on failure', () async {
        List<String>? persistedDrafts;
        final service = TokenRefreshService(
          refreshToken: () async => false,
          persistDrafts: (drafts) async => persistedDrafts = drafts,
          redirectToLogin: () {},
        );

        await service.attemptRefresh(unsentDrafts: ['draft1', 'draft2']);

        expect(persistedDrafts, ['draft1', 'draft2']);
        service.dispose();
      });

      test('does not persist empty drafts list', () async {
        bool persistCalled = false;
        final service = TokenRefreshService(
          refreshToken: () async => false,
          persistDrafts: (_) async => persistCalled = true,
          redirectToLogin: () {},
        );

        await service.attemptRefresh(unsentDrafts: []);

        expect(persistCalled, false);
        service.dispose();
      });

      test('returns failure when refresh throws exception', () async {
        final service = TokenRefreshService(
          refreshToken: () async => throw Exception('network error'),
          persistDrafts: (_) async {},
          redirectToLogin: () {},
        );

        final result = await service.attemptRefresh();

        expect(result, TokenRefreshResult.failure);
        service.dispose();
      });

      test('still redirects to login when refresh throws', () async {
        bool redirected = false;
        final service = TokenRefreshService(
          refreshToken: () async => throw Exception('network error'),
          persistDrafts: (_) async {},
          redirectToLogin: () => redirected = true,
        );

        await service.attemptRefresh();

        expect(redirected, true);
        service.dispose();
      });

      test('still redirects even if draft persistence fails', () async {
        bool redirected = false;
        final service = TokenRefreshService(
          refreshToken: () async => false,
          persistDrafts: (_) async => throw Exception('storage error'),
          redirectToLogin: () => redirected = true,
        );

        await service.attemptRefresh(unsentDrafts: ['draft']);

        expect(redirected, true);
        service.dispose();
      });
    });

    group('concurrent refresh requests', () {
      test('coalesces concurrent refresh calls', () async {
        int refreshCallCount = 0;
        final service = TokenRefreshService(
          refreshToken: () async {
            refreshCallCount++;
            await Future<void>.delayed(const Duration(milliseconds: 50));
            return true;
          },
          persistDrafts: (_) async {},
          redirectToLogin: () {},
        );

        // Fire two concurrent refresh requests
        final results = await Future.wait([
          service.attemptRefresh(),
          service.attemptRefresh(),
        ]);

        // Both should succeed but only one actual refresh call
        expect(results, [TokenRefreshResult.success, TokenRefreshResult.success]);
        expect(refreshCallCount, 1);
        service.dispose();
      });
    });

    group('isRefreshing', () {
      test('is false initially', () {
        final service = TokenRefreshService(
          refreshToken: () async => true,
          persistDrafts: (_) async {},
          redirectToLogin: () {},
        );

        expect(service.isRefreshing, false);
        service.dispose();
      });

      test('is false after refresh completes', () async {
        final service = TokenRefreshService(
          refreshToken: () async => true,
          persistDrafts: (_) async {},
          redirectToLogin: () {},
        );

        await service.attemptRefresh();

        expect(service.isRefreshing, false);
        service.dispose();
      });
    });
  });
}
