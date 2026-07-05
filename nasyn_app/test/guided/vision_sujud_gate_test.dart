import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasyn_app/audio/audio_cue_resolver.dart';
import 'package:nasyn_app/guided/guided_mode_controller.dart';
import 'package:nasyn_app/prayer/prayer_config.dart';
import 'package:nasyn_app/prayer/prayer_state.dart';

import '../support/fake_audio_service.dart';
import '../support/fake_vision_service.dart';

// Vision-confirm SUJUD (§8.13): timer tuma'ninah sujud bermula bila sujud
// DIKESAN; fallback timeout jamin vision tak pernah block solat. Gate fiqh:
// signal hanya dilayan pada state sujud1/sujud2 (FSM hanya sampai ke situ
// selepas qiyam -> rukuk -> iktidal).
void main() {
  GuidedModeController buildController(
    FakeAudioService audio,
    FakeVisionService? vision,
  ) => GuidedModeController(
    config: prayerConfigs[PrayerType.zuhur]!,
    level: AssistanceLevel.takbirOnly,
    audioService: audio,
    cueResolver: AudioCueResolver(),
    vision: vision,
  );

  // Bawa controller Takbir Only ke sujud1 dengan gate vision/timer sujud1
  // sudah armed (takbir transition sujud1 selesai).
  void driveToSujud1(
    GuidedModeController c,
    FakeAudioService audio,
    dynamic async,
  ) {
    audio.completeCurrent(); // takbiratulIhram (audio sendiri)
    async.flushMicrotasks();
    expect(c.currentState, PrayerState.qiyam);
    c.next(); // qiyam manual-Next -> rukuk (takbir transition main)
    audio.completeCurrent();
    async.flushMicrotasks();
    expect(c.currentState, PrayerState.rukuk);
    async.elapse(const Duration(seconds: 4)); // tumaninah rukuk
    expect(c.currentState, PrayerState.iktidal);
    // iktidal: dual-gate — timer 3s DAN audio bacaanIktidal
    async.elapse(const Duration(seconds: 3));
    audio.completeCurrent();
    async.flushMicrotasks();
    expect(c.currentState, PrayerState.sujud1);
    // takbir transition masuk sujud1 — lepas habis, gate sujud1 armed
    audio.completeCurrent();
    async.flushMicrotasks();
  }

  test('sujud1: timer tuma\'ninah TIDAK bermula sebelum sujud dikesan', () {
    fakeAsync((async) {
      final audio = FakeAudioService();
      final vision = FakeVisionService();
      final c = buildController(audio, vision);
      expect(vision.started, isTrue);
      driveToSujud1(c, audio, async);

      // 6s berlalu TANPA detection (< visionWaitTimeout 10s) — tumaninah
      // 4s belum bermula, state kekal sujud1
      async.elapse(const Duration(seconds: 6));
      expect(c.currentState, PrayerState.sujud1);

      // Sujud dikesan -> timer 2s bermula sekarang
      vision.emitSujud(true);
      async.elapse(const Duration(seconds: 1, milliseconds: 900));
      expect(c.currentState, PrayerState.sujud1);
      async.elapse(const Duration(milliseconds: 200));
      expect(c.currentState, PrayerState.dudukAntaraSujud);
    });
  });

  test('fallback: tiada detection -> maju juga selepas timeout + tumaninah', () {
    fakeAsync((async) {
      final audio = FakeAudioService();
      final vision = FakeVisionService();
      final c = buildController(audio, vision);
      driveToSujud1(c, audio, async);

      // Tiada detection langsung: selepas visionWaitTimeout (10s), timer
      // tumaninah 4s bermula sendiri -> maju pada ~14s. Vision TIDAK
      // pernah block solat.
      async.elapse(
        GuidedModeController.visionWaitTimeout + const Duration(seconds: 4),
      );
      expect(c.currentState, PrayerState.dudukAntaraSujud);
    });
  });

  test('gate fiqh: signal sujud pada state rukuk DIABAIKAN', () {
    fakeAsync((async) {
      final audio = FakeAudioService();
      final vision = FakeVisionService();
      final c = buildController(audio, vision);
      audio.completeCurrent();
      async.flushMicrotasks();
      c.next(); // qiyam -> rukuk
      audio.completeCurrent(); // takbir transition
      async.flushMicrotasks();
      expect(c.currentState, PrayerState.rukuk);

      // Signal sujud palsu (contoh: pengguna dekat phone) semasa rukuk —
      // tiada kesan pada FSM, rukuk maju ikut timer biasa sahaja
      vision.emitSujud(true);
      async.flushMicrotasks();
      expect(c.currentState, PrayerState.rukuk);
      async.elapse(const Duration(seconds: 4));
      expect(c.currentState, PrayerState.iktidal);
    });
  });

  test('sujud dikesan awal (semasa takbir transition) -> timer terus mula', () {
    fakeAsync((async) {
      final audio = FakeAudioService();
      final vision = FakeVisionService();
      final c = buildController(audio, vision);
      // Sampai sujud1 tapi JANGAN habiskan takbir transition dulu
      audio.completeCurrent();
      async.flushMicrotasks();
      c.next();
      audio.completeCurrent();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 4));
      async.elapse(const Duration(seconds: 3));
      audio.completeCurrent();
      async.flushMicrotasks();
      expect(c.currentState, PrayerState.sujud1);

      // Pengguna dah turun sujud SEBELUM takbir transition habis
      vision.emitSujud(true);
      // Takbir habis -> _armTumaninah nampak _sujudDetected=true -> terus arm
      audio.completeCurrent();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 4));
      expect(c.currentState, PrayerState.dudukAntaraSujud);
    });
  });

  test('tanpa vision (null): behavior timing asal tak berubah', () {
    fakeAsync((async) {
      final audio = FakeAudioService();
      final c = buildController(audio, null);
      audio.completeCurrent();
      async.flushMicrotasks();
      c.next();
      audio.completeCurrent();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 4));
      expect(c.currentState, PrayerState.iktidal);
      async.elapse(const Duration(seconds: 3));
      audio.completeCurrent();
      async.flushMicrotasks();
      expect(c.currentState, PrayerState.sujud1);
      audio.completeCurrent(); // takbir transition sujud1
      async.flushMicrotasks();
      // Tiada vision -> timer sujud terus jalan macam sebelum ini
      async.elapse(const Duration(seconds: 4));
      expect(c.currentState, PrayerState.dudukAntaraSujud);
    });
  });

  test('dispose menghentikan kamera vision', () {
    fakeAsync((async) {
      final audio = FakeAudioService();
      final vision = FakeVisionService();
      final c = buildController(audio, vision);
      c.dispose();
      expect(vision.stopped, isTrue);
    });
  });
}
