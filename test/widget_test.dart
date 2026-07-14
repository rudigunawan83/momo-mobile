// Basic Flutter widget test for MomoApp.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:momo_app/di/service_locator.dart';
import 'package:momo_app/main.dart';

void main() {
  setUp(() async {
    // Ensure a fresh service locator for each test
    await GetIt.instance.reset();
    await configureDependencies();
  });

  tearDown(() async {
    await resetDependencies();
  });

  testWidgets('MomoApp renders title', (WidgetTester tester) async {
    await tester.pumpWidget(const MomoApp());

    // Advance past the CharacterEngine's idle timer (5s)
    await tester.pump(const Duration(seconds: 6));

    expect(find.text('Momo AI Companion'), findsOneWidget);

    // Dispose the app state to clean up timers
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 6));
  });
}
