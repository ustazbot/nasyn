import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasyn_app/main.dart';
import 'package:nasyn_app/ui/home_screen.dart';

void main() {
  testWidgets('App starts on Boot then reaches Home screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: NasynApp()));

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
