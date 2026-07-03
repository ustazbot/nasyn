import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasyn_app/ui/boot_screen.dart';
import 'package:nasyn_app/ui/home_screen.dart';

void main() {
  testWidgets('auto-navigates to Home after its timer elapses', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: BootScreen())),
    );

    expect(find.byType(BootScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
