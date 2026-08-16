// Basic smoke test untuk Momo AI app

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momo_ai/app/app.dart';

void main() {
  testWidgets('App boots without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MomoApp(),
      ),
    );
    // Just verify the app starts
    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
