import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasyn_app/audio/audio_cue_resolver.dart';
import 'package:nasyn_app/guided/guided_mode_controller.dart';
import 'package:nasyn_app/prayer/prayer_config.dart';
import 'package:nasyn_app/prayer/prayer_state.dart';

import '../support/fake_audio_service.dart';

void main() {
  test('Takbir Only: audio-driven takbir, manual-Next qiyam, fixed-timer rukuk', () {
    fakeAsync((async) {
      final audio = FakeAudioService();
      final controller = GuidedModeController(
        config: prayerConfigs[PrayerType.zuhur]!,
        level: AssistanceLevel.takbirOnly,
        audioService: audio,
        cueResolver: AudioCueResolver(),
      );

      // takbiratulIhram has a cue in Takbir Only -> advances on audio complete
      audio.completeCurrent();
      async.flushMicrotasks();
      expect(controller.currentState, PrayerState.qiyam);

      // qiyam is variable-reading, Takbir Only has no cue -> waits for manual Next
      async.elapse(const Duration(seconds: 10));
      expect(controller.currentState, PrayerState.qiyam);
      controller.next();
      expect(controller.currentState, PrayerState.rukuk);

      // rukuk is fixed-posture, Takbir Only has no cue -> fixed 3s timer
      async.elapse(const Duration(seconds: 2, milliseconds: 900));
      expect(controller.currentState, PrayerState.rukuk);
      async.elapse(const Duration(milliseconds: 200));
      expect(controller.currentState, PrayerState.iktidal);
    });
  });

  test('Full Recite: fixed-posture state waits for max(tumaninah, audio)', () {
    fakeAsync((async) {
      final audio = FakeAudioService();
      final controller = GuidedModeController(
        config: prayerConfigs[PrayerType.zuhur]!,
        level: AssistanceLevel.fullRecite,
        audioService: audio,
        cueResolver: AudioCueResolver(),
      );

      audio.completeCurrent(); // takbiratulIhram audio finishes
      async.flushMicrotasks();
      expect(controller.currentState, PrayerState.qiyam);

      audio.completeCurrent(); // Al-Fatihah finishes -> qiyam advances (Full Recite)
      async.flushMicrotasks();
      expect(controller.currentState, PrayerState.rukuk);

      // rukuk: tuma'ninah 3s, audio not yet complete -> must NOT advance at 3s
      async.elapse(const Duration(seconds: 3));
      expect(controller.currentState, PrayerState.rukuk);

      // audio finishes after tuma'ninah already elapsed -> advances now
      audio.completeCurrent();
      async.flushMicrotasks();
      expect(controller.currentState, PrayerState.iktidal);
    });
  });

  test('pause stops the timer; resume re-arms it', () {
    fakeAsync((async) {
      final audio = FakeAudioService();
      final controller = GuidedModeController(
        config: prayerConfigs[PrayerType.subuh]!,
        level: AssistanceLevel.takbirOnly,
        audioService: audio,
        cueResolver: AudioCueResolver(),
      );

      audio.completeCurrent(); // takbiratulIhram -> qiyam
      async.flushMicrotasks();
      controller.next(); // qiyam -> rukuk (manual, Takbir Only has no qiyam cue)

      controller.pause();
      async.elapse(const Duration(seconds: 5));
      expect(controller.currentState, PrayerState.rukuk);

      controller.resume();
      async.elapse(const Duration(seconds: 3));
      expect(controller.currentState, PrayerState.iktidal);
    });
  });

  test('back() reverses state via engine.previous()', () {
    fakeAsync((async) {
      final audio = FakeAudioService();
      final controller = GuidedModeController(
        config: prayerConfigs[PrayerType.subuh]!,
        level: AssistanceLevel.takbirOnly,
        audioService: audio,
        cueResolver: AudioCueResolver(),
      );

      audio.completeCurrent();
      async.flushMicrotasks();
      controller.next(); // qiyam -> rukuk
      expect(controller.currentState, PrayerState.rukuk);

      controller.back();
      expect(controller.currentState, PrayerState.qiyam);
    });
  });
}
