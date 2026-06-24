import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:splitsmart/features/auth/splash_screen.dart';

void main() {
  testWidgets('Splash screen shows tagline', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen()),
    );

    expect(find.text('No more WhatsApp math.'), findsOneWidget);
    expect(find.text('SplitSmart'), findsOneWidget);
  });
}
