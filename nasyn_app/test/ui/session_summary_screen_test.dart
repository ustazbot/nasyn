import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasyn_app/prayer/prayer_config.dart';
import 'package:nasyn_app/ui/session_summary_screen.dart';

void main() {
  testWidgets('shows the prayer name and rakaat completion', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SessionSummaryScreen(
            prayerType: PrayerType.zuhur,
            totalRakaat: 4,
          ),
        ),
      ),
    );

    expect(find.text('ZUHUR'), findsOneWidget);
    expect(find.textContaining('4/4'), findsOneWidget);
  });
}
