import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasyn_app/ui/settings_screen.dart';

void main() {
  testWidgets('shows the coming-soon message', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SettingsScreen()),
      ),
    );

    expect(find.text('Tetapan akan datang'), findsOneWidget);
  });
}
