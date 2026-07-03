import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasyn_app/audio/audio_cue_resolver.dart';
import 'package:nasyn_app/audio/nasyn_audio.dart';
import 'package:nasyn_app/guided/guided_mode_controller.dart';
import 'package:nasyn_app/prayer/prayer_config.dart';
import 'package:nasyn_app/prayer/prayer_state.dart';

import '../support/fake_audio_service.dart';

void main() {
  test(
    'Takbir Only: audio-driven takbir, manual-Next qiyam, fixed-timer rukuk',
    () {
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

        // rakaat-1 qiyam is the first Qiyam of the session, so it gets no
        // takbir transition prefix (it would double up with takbiratulIhram's
        // own takbir); qiyam itself (variable-reading, Takbir Only has no cue)
        // waits for manual Next regardless.
        async.elapse(const Duration(seconds: 10));
        expect(controller.currentState, PrayerState.qiyam);
        controller.next();
        expect(controller.currentState, PrayerState.rukuk);

        // rukuk's takbir transition prefix must finish before its own
        // (Takbir-Only-has-no-cue) fixed 3s tuma'ninah timer is armed
        audio.completeCurrent();
        async.flushMicrotasks();

        // rukuk is fixed-posture, Takbir Only has no cue -> fixed 4s timer
        async.elapse(const Duration(seconds: 3, milliseconds: 900));
        expect(controller.currentState, PrayerState.rukuk);
        async.elapse(const Duration(milliseconds: 200));
        expect(controller.currentState, PrayerState.iktidal);
      });
    },
  );

  test('Full Recite: fixed-posture state waits for max(tumaninah, audio)', () {
    fakeAsync((async) {
      final audio = FakeAudioService();
      final controller = GuidedModeController(
        config: prayerConfigs[PrayerType.zuhur]!,
        level: AssistanceLevel.fullRecite,
        audioService: audio,
        cueResolver: AudioCueResolver(),
      );

      audio
          .completeCurrent(); // takbiratulIhram audio finishes (no prefix for it)
      async.flushMicrotasks();
      expect(controller.currentState, PrayerState.qiyam);

      // first Qiyam of the session gets no takbir prefix (it would double up
      // with takbiratulIhram's own takbir) -> Al-Fatihah plays immediately
      audio
          .completeCurrent(); // Al-Fatihah finishes -> qiyam advances (Full Recite)
      async.flushMicrotasks();
      expect(controller.currentState, PrayerState.rukuk);

      audio.completeCurrent(); // rukuk's takbir transition prefix finishes
      async.flushMicrotasks();

      // rukuk: tuma'ninah 4s, audio not yet complete -> must NOT advance at 4s
      async.elapse(const Duration(seconds: 4));
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
      controller
          .next(); // qiyam -> rukuk (manual, Takbir Only has no qiyam cue)

      controller.pause();
      async.elapse(const Duration(seconds: 5));
      expect(controller.currentState, PrayerState.rukuk);

      controller
          .resume(); // re-enters rukuk -> re-arms its takbir transition prefix
      audio.completeCurrent(); // rukuk's takbir transition prefix finishes
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 4));
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
      // first Qiyam of the session gets no takbir prefix (it would double up
      // with takbiratulIhram's own takbir) -> Al-Fatihah plays immediately.
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
      async.elapse(const Duration(seconds: 4));
      audio.completeCurrent(); // rukuk's own cue finishes -> advance to iktidal
      async.flushMicrotasks();
      expect(controller.currentState, PrayerState.iktidal);

      // Iktidal is excluded from the takbir prefix -- its own cue plays
      // immediately upon entry, with no completeCurrent() needed for a takbir.
      expect(audio.lastPlayedPath, NasynAudio.bacaanIktidal);
    });
  });

  test(
    'Takbir Only: rakaat-2 Qiyam (Subuh) still gets its takbir prefix, unlike rakaat 1',
    () {
      fakeAsync((async) {
        final audio = FakeAudioService();
        final controller = GuidedModeController(
          config: prayerConfigs[PrayerType.subuh]!,
          level: AssistanceLevel.takbirOnly,
          audioService: audio,
          cueResolver: AudioCueResolver(),
        );

        // takbiratulIhram IS the opening takbir (no prefix) -> advances on audio complete
        audio.completeCurrent();
        async.flushMicrotasks();
        expect(controller.currentState, PrayerState.qiyam);
        expect(controller.currentRakaat, 1);

        // rakaat-1 qiyam is the first Qiyam of the session -> no takbir prefix
        // (Takbir Only has no cue for qiyam either) -> manual Next only.
        controller.next();
        expect(controller.currentState, PrayerState.rukuk);

        // rukuk's takbir transition prefix must finish before its own
        // (Takbir-Only-has-no-cue) fixed 4s tuma'ninah timer is armed.
        audio.completeCurrent();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 4));
        expect(controller.currentState, PrayerState.iktidal);

        // Iktidal is excluded from the takbir prefix; its own cue (bacaanIktidal)
        // always plays regardless of level. Dual-gate: waits for BOTH the fixed
        // 3s tuma'ninah floor AND audio completion (cue is 7s — never cut off).
        async.elapse(const Duration(seconds: 3));
        expect(controller.currentState, PrayerState.iktidal);
        audio.completeCurrent();
        async.flushMicrotasks();
        expect(controller.currentState, PrayerState.sujud1);

        // sujud1's takbir transition prefix, then its fixed 4s tuma'ninah timer.
        audio.completeCurrent();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 4));
        expect(controller.currentState, PrayerState.dudukAntaraSujud);

        // dudukAntaraSujud's takbir transition prefix, then its fixed 3s timer.
        audio.completeCurrent();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 3));
        expect(controller.currentState, PrayerState.sujud2);

        // sujud2's takbir transition prefix, then its fixed 4s timer. Subuh has
        // no tahiyat awal, so advancing from rakaat-1 sujud2 goes straight to
        // rakaat-2 qiyam -- the shortest path to a non-first-Qiyam entry.
        audio.completeCurrent();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 4));
        expect(controller.currentState, PrayerState.qiyam);
        expect(controller.currentRakaat, 2);

        // Unlike rakaat 1's qiyam, this rakaat-2 qiyam is NOT the first Qiyam of
        // the session, so isFirstQiyamOfSession does not suppress its takbir
        // transition prefix: it plays immediately upon entry.
        expect(audio.lastPlayedPath, NasynAudio.takbiratulIhram);
      });
    },
  );

  test('niatCue: main niat dulu, FSM mula selepas audio niat habis', () {
    fakeAsync((async) {
      final audio = FakeAudioService();
      final controller = GuidedModeController(
        config: prayerConfigs[PrayerType.subuh]!,
        level: AssistanceLevel.takbirOnly,
        audioService: audio,
        cueResolver: AudioCueResolver(),
        niatCue: NasynAudio.niatBySolat[PrayerType.subuh],
      );

      // Niat sedang main — takbir BELUM main, gate onComplete bukan timer.
      expect(audio.lastPlayedPath, NasynAudio.niatSubuh);
      expect(controller.isPlayingNiat, isTrue);
      async.elapse(const Duration(seconds: 30));
      expect(controller.currentState, PrayerState.takbiratulIhram);
      expect(audio.lastPlayedPath, NasynAudio.niatSubuh);

      // Niat habis → terus takbiratul ihram tanpa jeda, flag niat padam.
      audio.completeCurrent();
      async.flushMicrotasks();
      expect(controller.isPlayingNiat, isFalse);
      expect(audio.lastPlayedPath, NasynAudio.takbiratulIhram);

      // Takbir habis → qiyam, aliran biasa sambung.
      audio.completeCurrent();
      async.flushMicrotasks();
      expect(controller.currentState, PrayerState.qiyam);
    });
  });

  test('niatCue null (sunat): FSM mula terus macam sebelum', () {
    fakeAsync((async) {
      final audio = FakeAudioService();
      final controller = GuidedModeController(
        config: prayerConfigs[PrayerType.sunat]!,
        level: AssistanceLevel.takbirOnly,
        audioService: audio,
        cueResolver: AudioCueResolver(),
        niatCue: NasynAudio.niatBySolat[PrayerType.sunat],
      );

      expect(audio.lastPlayedPath, NasynAudio.takbiratulIhram);
      audio.completeCurrent();
      async.flushMicrotasks();
      expect(controller.currentState, PrayerState.qiyam);
    });
  });

  test('niatBySolat lengkap untuk 5 solat fardu', () {
    for (final type in [
      PrayerType.subuh,
      PrayerType.zuhur,
      PrayerType.asar,
      PrayerType.maghrib,
      PrayerType.isyak,
    ]) {
      expect(NasynAudio.niatBySolat[type], isNotNull);
      expect(
        NasynAudio.isPendingRecording(NasynAudio.niatBySolat[type]!),
        isFalse,
      );
    }
    expect(NasynAudio.niatBySolat[PrayerType.sunat], isNull);
  });

  test(
    'Surah: rakaat 1 → sequential Fatihah habis PENUH dulu baru surah 1',
    () {
      fakeAsync((async) {
        final audio = FakeAudioService();
        final controller = GuidedModeController(
          config: prayerConfigs[PrayerType.subuh]!,
          level: AssistanceLevel.fullRecite,
          audioService: audio,
          cueResolver: AudioCueResolver(),
          surahRakaat1: NasynAudio.alKafirun,
          surahRakaat2: NasynAudio.alIkhlas,
        );

        // takbiratulIhram habis → qiyam rakaat 1, Fatihah mula.
        audio.completeCurrent();
        async.flushMicrotasks();
        expect(controller.currentState, PrayerState.qiyam);
        expect(audio.lastPlayedPath, NasynAudio.alFatihah);

        // Masa berlalu TIDAK mula surah — gate onComplete, bukan timer.
        async.elapse(const Duration(seconds: 60));
        expect(audio.lastPlayedPath, NasynAudio.alFatihah);
        expect(controller.currentState, PrayerState.qiyam);

        // Fatihah habis penuh → BARU surah rakaat 1 mula (tiada overlap).
        audio.completeCurrent();
        async.flushMicrotasks();
        expect(audio.lastPlayedPath, NasynAudio.alKafirun);
        expect(controller.currentState, PrayerState.qiyam);

        // Surah habis → seluruh senarai selesai → advance ke rukuk.
        audio.completeCurrent();
        async.flushMicrotasks();
        expect(controller.currentState, PrayerState.rukuk);
      });
    },
  );

  test('Surah: rakaat 2 → surahRakaat2 (bukan surahRakaat1)', () {
    fakeAsync((async) {
      final audio = FakeAudioService();
      final controller = GuidedModeController(
        config: prayerConfigs[PrayerType.subuh]!,
        level: AssistanceLevel.fullRecite,
        audioService: audio,
        cueResolver: AudioCueResolver(),
        surahRakaat1: NasynAudio.alKafirun,
        surahRakaat2: NasynAudio.alIkhlas,
      );

      // Skip manual sampai qiyam rakaat 2.
      while (!(controller.currentRakaat == 2 &&
          controller.currentState == PrayerState.qiyam)) {
        controller.next();
      }
      // Qiyam rakaat 2 bukan qiyam pertama → takbir prefix dulu.
      expect(audio.lastPlayedPath, NasynAudio.takbiratulIhram);
      audio.completeCurrent();
      async.flushMicrotasks();
      expect(audio.lastPlayedPath, NasynAudio.alFatihah);

      audio.completeCurrent();
      async.flushMicrotasks();
      expect(audio.lastPlayedPath, NasynAudio.alIkhlas);
    });
  });

  test('Surah: Zuhur rakaat 3 & 4 → Fatihah SAHAJA, terus advance', () {
    fakeAsync((async) {
      final audio = FakeAudioService();
      final controller = GuidedModeController(
        config: prayerConfigs[PrayerType.zuhur]!,
        level: AssistanceLevel.fullRecite,
        audioService: audio,
        cueResolver: AudioCueResolver(),
        surahRakaat1: NasynAudio.alKafirun,
        surahRakaat2: NasynAudio.alIkhlas,
      );

      for (final rakaat in [3, 4]) {
        while (!(controller.currentRakaat == rakaat &&
            controller.currentState == PrayerState.qiyam)) {
          controller.next();
        }
        // Takbir prefix → Fatihah → habis → TERUS advance (tiada surah).
        audio.completeCurrent();
        async.flushMicrotasks();
        expect(
          audio.lastPlayedPath,
          NasynAudio.alFatihah,
          reason: 'rakaat $rakaat: Fatihah main',
        );
        audio.completeCurrent();
        async.flushMicrotasks();
        expect(
          controller.currentState,
          PrayerState.rukuk,
          reason: 'rakaat $rakaat: tiada surah, terus rukuk',
        );
      }
    });
  });

  test('Surah: qunut Subuh rakaat 2 tak terjejas', () {
    fakeAsync((async) {
      final audio = FakeAudioService();
      final controller = GuidedModeController(
        config: prayerConfigs[PrayerType.subuh]!,
        level: AssistanceLevel.fullRecite,
        audioService: audio,
        cueResolver: AudioCueResolver(),
        surahRakaat1: NasynAudio.alKafirun,
        surahRakaat2: NasynAudio.alIkhlas,
      );

      while (controller.currentState != PrayerState.qunut) {
        controller.next();
      }
      expect(controller.currentRakaat, 2);
      // Qunut tiada takbir prefix; cue qunut main terus, satu fail sahaja.
      expect(audio.lastPlayedPath, NasynAudio.qunut);
      audio.completeCurrent();
      async.flushMicrotasks();
      expect(controller.currentState, PrayerState.sujud1);
    });
  });
  test('Iktidal Takbir Only: audio 7s > floor 3s — TIDAK dipotong timer', () {
    fakeAsync((async) {
      final audio = FakeAudioService();
      final controller = GuidedModeController(
        config: prayerConfigs[PrayerType.maghrib]!,
        level: AssistanceLevel.takbirOnly,
        audioService: audio,
        cueResolver: AudioCueResolver(),
      );

      // Sampai ke iktidal: takbir -> qiyam (manual next) -> rukuk -> iktidal
      audio.completeCurrent();
      async.flushMicrotasks();
      controller.next(); // qiyam -> rukuk
      audio.completeCurrent(); // takbir prefix rukuk habis
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 4)); // tumaninah rukuk
      expect(controller.currentState, PrayerState.iktidal);
      expect(audio.lastPlayedPath, NasynAudio.bacaanIktidal);

      // Floor iktidal 3s berlalu tapi audio (7s) belum habis — JANGAN advance
      async.elapse(const Duration(seconds: 3));
      expect(controller.currentState, PrayerState.iktidal);

      // Audio habis selepas floor — baru advance (dual-gate)
      audio.completeCurrent();
      async.flushMicrotasks();
      expect(controller.currentState, PrayerState.sujud1);
    });
  });
}
