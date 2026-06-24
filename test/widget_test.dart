import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:splitsmart/main.dart';

void main() {
  testWidgets('Splash screen shows tagline', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MyApp()),
    );

    expect(find.text('No more WhatsApp math.'), findsOneWidget);
    expect(find.text('SplitSmart'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });
}
