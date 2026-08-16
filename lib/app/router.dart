import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/home/presentation/pages/momo_home_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/chat/presentation/pages/chat_page.dart';
import '../features/memory/presentation/pages/memory_page.dart';
import '../features/mood/presentation/pages/mood_page.dart';
import '../features/mission/presentation/pages/mission_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/providers.dart';

// ===== RouterNotifier =====

/// Notifier yang listen ke auth state dan trigger router refresh
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  bool _isAuth = false;

  RouterNotifier(this._ref) {
    // Listen ke auth state changes
    _ref.listen<bool>(isAuthenticatedProvider, (previous, next) {
      if (_isAuth != next) {
        _isAuth = next;
        notifyListeners(); // Trigger GoRouter to re-evaluate redirects
      }
    });
    _isAuth = _ref.read(isAuthenticatedProvider);
  }

  bool get isAuthenticated => _isAuth;
}

/// RouterNotifier Provider
final routerNotifierProvider =
    ChangeNotifierProvider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

// ===== GoRouter Provider =====

/// Router Provider — gunakan ini di app.dart
final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final isAuth = notifier.isAuthenticated;
      final isOnLogin = state.matchedLocation == '/login';

      // Belum login → ke /login
      if (!isAuth) {
        return isOnLogin ? null : '/login';
      }

      // Sudah login tapi di /login → ke /
      if (isOnLogin) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const MomoHomePage(),
        routes: [
          GoRoute(
            path: 'chat',
            builder: (context, state) {
              final conversationId =
                  state.uri.queryParameters['id'];
              return ChatPage(conversationId: conversationId);
            },
          ),
          GoRoute(
            path: 'missions',
            builder: (context, state) => const MissionPage(),
          ),
          GoRoute(
            path: 'mood',
            builder: (context, state) => const MoodPage(),
          ),
          GoRoute(
            path: 'music',
            builder: (context, state) =>
                const _PlaceholderPage(title: 'Musik'),
          ),
          GoRoute(
            path: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: 'memory',
            builder: (context, state) => const MemoryPage(),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) =>
                const _PlaceholderPage(title: 'Pengaturan'),
          ),
        ],
      ),
    ],
  );
});

// ===== Placeholder Pages =====

class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5EF),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.construction_rounded,
              size: 64,
              color: Color(0xFF1683FF),
            ),
            const SizedBox(height: 16),
            Text(
              '$title akan hadir segera',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fitur ini sedang dikembangkan 🚀',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B6B6B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
