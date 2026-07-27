import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:serenity/app.dart';

void main() {
  testWidgets('App builds with onboarding screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SerenityApp(),
      ),
    );

    // Should show Serenity app name on first launch (onboarding)
    expect(find.text('Serenity'), findsOneWidget);
    expect(find.text('Begin'), findsOneWidget);
  });
}
