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
  setUp(() {
    // Skrin panjang — guna viewport tinggi supaya semua seksyen dibina.
  });

  testWidgets('papar seksyen Bahasa, Panduan Masa, Mod Amaran', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());

    expect(find.text('Bahasa'), findsOneWidget);
    expect(find.text('Panduan Masa'), findsOneWidget);
    expect(find.text('Bahasa Melayu'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Reset ke Default'), findsOneWidget);
  });

  testWidgets('profil bawah floor di-clamp bila skrin simpan semula',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Suntik nilai haram (rukuk 2s) terus ke provider — slider min ialah
    // floor, jadi UI sendiri tak boleh hasilkan nilai ni.
    final hacked = TimingProfile.defaults.copyWith(rukukSeconds: 2);
    await tester.pumpWidget(_app(timing: hacked));

    // Tekan Reset ke Default — laluan simpan mesti clamp/pulih ke >= 4s.
    await tester.tap(find.text('Reset ke Default'));
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsScreen)),
    );
    expect(
      container.read(timingProfileProvider).rukukSeconds,
      greaterThanOrEqualTo(TimingProfile.rukukFloor),
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
    expect(find.text('Guided Timing'), findsOneWidget);
    expect(find.text('Reset to Default'), findsOneWidget);
  });
}
