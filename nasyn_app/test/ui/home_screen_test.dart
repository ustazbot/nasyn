import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasyn_app/prayer/prayer_config.dart';
import 'package:nasyn_app/ui/home_screen.dart';

void main() {
  testWidgets('shows mode toggle and all 6 solat buttons', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: HomeScreen()),
      ),
    );

    expect(find.text('GUIDED MODE'), findsOneWidget);
    expect(find.text('VISION MODE'), findsOneWidget);
    for (final type in PrayerType.values) {
      expect(
        find.text(prayerConfigs[type]!.displayName.toUpperCase()),
        findsOneWidget,
      );
    }
  });
}
