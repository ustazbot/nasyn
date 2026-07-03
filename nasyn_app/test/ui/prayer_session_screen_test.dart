import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasyn_app/audio/audio_cue_resolver.dart';
import 'package:nasyn_app/guided/guided_mode_controller.dart';
import 'package:nasyn_app/prayer/prayer_config.dart';
import 'package:nasyn_app/ui/prayer_session_screen.dart';

import '../support/fake_audio_service.dart';

Widget _app() => ProviderScope(
      overrides: [
        guidedModeControllerProvider.overrideWith(
          (ref, args) => GuidedModeController(
            config: prayerConfigs[args.type]!,
            level: args.level,
            audioService: FakeAudioService(),
            cueResolver: AudioCueResolver(),
          ),
        ),
      ],
      child: const MaterialApp(
        home: PrayerSessionScreen(
          prayerType: PrayerType.subuh,
          level: AssistanceLevel.takbirOnly,
        ),
      ),
    );

void main() {
  testWidgets('back sistem TIDAK keluar dari solat — dialog confirm muncul',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());

    // Simulate butang back sistem (nav bar / gesture).
    await tester.binding.handlePopRoute();
    await tester.pump();

    // Sesi masih ada, dialog confirm keluar.
    expect(find.byType(PrayerSessionScreen), findsOneWidget);
    expect(find.text('Keluar dari sesi solat?'), findsOneWidget);

    // Batal → kekal dalam sesi solat.
    await tester.tap(find.text('Batal'));
    await tester.pump();
    expect(find.byType(PrayerSessionScreen), findsOneWidget);
    expect(find.text('Keluar dari sesi solat?'), findsNothing);
  });
}
