import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import '../core/theme/momo_theme.dart';

/// Main Application Widget — ConsumerWidget untuk akses Riverpod
class MomoApp extends ConsumerWidget {
  const MomoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use router dari provider (reactive auth-aware)
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Momo AI',
      debugShowCheckedModeBanner: false,
      theme: MomoTheme.lightTheme,
      routerConfig: router,
    );
  }
}
