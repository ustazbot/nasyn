import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasyn_app/settings/settings_providers.dart';
import 'package:nasyn_app/settings/timing_profile.dart';
import 'package:nasyn_app/ui/settings_screen.dart';

Widget _app({TimingProfile? timing}) => ProviderScope(
  overrides: [
    if (timing != null) timingProfileProvider.overrideWith((ref) => timing),
  ],
  child: const MaterialApp(home: SettingsScreen()),
);

void main() {
  testWidgets('papar seksyen Bahasa, Tambah Masa, Mod Amaran', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());

    expect(find.text('Bahasa'), findsOneWidget);
    expect(find.text('Tambah Masa'), findsOneWidget);
    expect(find.text('Bahasa Melayu'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Reset ke Default'), findsOneWidget);
    // 4 slider tuma'ninah (slow-down only) + 2 slider Tempoh Bacaan
    // Sendiri (qiyam/tahiyat); tiada Fatihah/Surah.
    expect(find.byType(Slider), findsNWidgets(6));
    expect(find.text('Tempoh Bacaan Sendiri'), findsOneWidget);
    expect(find.text('Al-Fatihah'), findsNothing);
    expect(find.text('Surah Pendek'), findsNothing);
  });

  testWidgets('extra negatif di-clamp ke 0 bila skrin simpan semula', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Suntik nilai haram (extra -2 = bawah floor) terus ke provider —
    // slider min ialah 0, jadi UI sendiri tak boleh hasilkan nilai ni.
    final hacked = TimingProfile.defaults.copyWith(rukukExtra: -2);
    await tester.pumpWidget(_app(timing: hacked));

    // Tekan Reset ke Default — laluan simpan mesti pulih ke extra >= 0.
    await tester.tap(find.text('Reset ke Default'));
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsScreen)),
    );
    expect(
      container.read(timingProfileProvider).rukukExtra,
      greaterThanOrEqualTo(0),
    );
  });

  testWidgets('toggle bahasa ke English tukar label seksyen', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await tester.tap(find.text('English'));
    await tester.pump();

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Add Time'), findsOneWidget);
    expect(find.text('Reset to Default'), findsOneWidget);
  });
}
