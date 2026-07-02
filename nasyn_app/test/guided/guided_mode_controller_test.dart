import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasyn_app/audio/audio_cue_resolver.dart';
import 'package:nasyn_app/audio/nasyn_audio.dart';
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

      // takbiratulIhram IS the opening takbir (no prefix) -> advances on audio complete
      audio.completeCurrent();
      async.flushMicrotasks();
      expect(controller.currentState, PrayerState.qiyam);

      // entering qiyam plays a takbir transition prefix first; qiyam itself
      // (variable-reading, Takbir Only has no cue) waits for manual Next
      // regardless of whether that prefix ever completes
      async.elapse(const Duration(seconds: 10));
      expect(controller.currentState, PrayerState.qiyam);
      controller.next();
      expect(controller.currentState, PrayerState.rukuk);

      // rukuk's takbir transition prefix must finish before its own
      // (Takbir-Only-has-no-cue) fixed 3s tuma'ninah timer is armed
      audio.completeCurrent();
      async.flushMicrotasks();

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

      audio.completeCurrent(); // takbiratulIhram audio finishes (no prefix for it)
      async.flushMicrotasks();
      expect(controller.currentState, PrayerState.qiyam);

      audio.completeCurrent(); // qiyam's takbir transition prefix finishes
      async.flushMicrotasks();
      expect(controller.currentState, PrayerState.qiyam);

      audio.completeCurrent(); // Al-Fatihah finishes -> qiyam advances (Full Recite)
      async.flushMicrotasks();
      expect(controller.currentState, PrayerState.rukuk);

      audio.completeCurrent(); // rukuk's takbir transition prefix finishes
      async.flushMicrotasks();

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

      controller.resume(); // re-enters rukuk -> re-arms its takbir transition prefix
      audio.completeCurrent(); // rukuk's takbir transition prefix finishes
      async.flushMicrotasks();
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

  test('Iktidal plays its cue with no takbir prefix, unlike its neighbors', () {
    fakeAsync((async) {
      final audio = FakeAudioService();
      final controller = GuidedModeController(
        config: prayerConfigs[PrayerType.zuhur]!,
        level: AssistanceLevel.fullRecite,
        audioService: audio,
        cueResolver: AudioCueResolver(),
      );

      audio.completeCurrent(); // takbiratulIhram -> qiyam
      async.flushMicrotasks();
      audio.completeCurrent(); // qiyam's takbir transition prefix finishes
      async.flushMicrotasks();
      expect(audio.lastPlayedPath, NasynAudio.alFatihah);

      audio.completeCurrent(); // Al-Fatihah finishes -> rukuk
      async.flushMicrotasks();
      expect(controller.currentState, PrayerState.rukuk);
      // rukuk gets a takbir prefix first (unlike its neighbor iktidal below).
      expect(audio.lastPlayedPath, NasynAudio.takbiratulIhram);

      audio.completeCurrent(); // rukuk's takbir transition prefix finishes
      async.flushMicrotasks();
      expect(audio.lastPlayedPath, NasynAudio.bacaanRukuk);

      // rukuk (Full Recite, fixed-posture) advances on max(tuma'ninah, audio)
      async.elapse(const Duration(seconds: 3));
      audio.completeCurrent(); // rukuk's own cue finishes -> advance to iktidal
      async.flushMicrotasks();
      expect(controller.currentState, PrayerState.iktidal);

      // Iktidal is excluded from the takbir prefix -- its own cue plays
      // immediately upon entry, with no completeCurrent() needed for a takbir.
      expect(audio.lastPlayedPath, NasynAudio.bacaanIktidal);
    });
  });
}
