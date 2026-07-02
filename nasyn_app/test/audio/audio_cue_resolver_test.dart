import 'package:flutter_test/flutter_test.dart';
import 'package:nasyn_app/audio/audio_cue_resolver.dart';
import 'package:nasyn_app/audio/nasyn_audio.dart';
import 'package:nasyn_app/prayer/prayer_config.dart';
import 'package:nasyn_app/prayer/prayer_state.dart';

void main() {
  final resolver = AudioCueResolver();
  final zuhurConfig = prayerConfigs[PrayerType.zuhur]!;

  group('Takbir Only', () {
    test('only plays audio for takbiratulIhram, nothing else', () {
      expect(
        resolver.resolve(
            PrayerState.takbiratulIhram, AssistanceLevel.takbirOnly, zuhurConfig),
        NasynAudio.takbiratulIhram,
      );
      expect(
        resolver.resolve(PrayerState.rukuk, AssistanceLevel.takbirOnly, zuhurConfig),
        isNull,
      );
      expect(
        resolver.resolve(PrayerState.qiyam, AssistanceLevel.takbirOnly, zuhurConfig),
        isNull,
      );
    });
  });

  group('Panduan Posisi', () {
    test('plays position-name cues', () {
      expect(
        resolver.resolve(
            PrayerState.rukuk, AssistanceLevel.panduanPosisi, zuhurConfig),
        NasynAudio.posisiRukuk,
      );
      expect(
        resolver.resolve(
            PrayerState.sujud1, AssistanceLevel.panduanPosisi, zuhurConfig),
        NasynAudio.posisiSujud,
      );
      expect(
        resolver.resolve(
            PrayerState.sujud2, AssistanceLevel.panduanPosisi, zuhurConfig),
        NasynAudio.posisiSujudKedua,
      );
      expect(
        resolver.resolve(
            PrayerState.qiyam, AssistanceLevel.panduanPosisi, zuhurConfig),
        isNull,
      );
    });
  });

  group('Full Recite', () {
    test('plays full bacaan for every rukun', () {
      expect(
        resolver.resolve(PrayerState.qiyam, AssistanceLevel.fullRecite, zuhurConfig),
        NasynAudio.alFatihah,
      );
      expect(
        resolver.resolve(PrayerState.rukuk, AssistanceLevel.fullRecite, zuhurConfig),
        NasynAudio.bacaanRukuk,
      );
      expect(
        resolver.resolve(
            PrayerState.dudukTahiyatAwal, AssistanceLevel.fullRecite, zuhurConfig),
        NasynAudio.tahiyatAwal,
      );
      expect(
        resolver.resolve(
            PrayerState.dudukTahiyatAkhir, AssistanceLevel.fullRecite, zuhurConfig),
        NasynAudio.tahiyatAkhir,
      );
      expect(
        resolver.resolve(PrayerState.salam, AssistanceLevel.fullRecite, zuhurConfig),
        NasynAudio.salam,
      );
    });
  });

  group('Iktidal (always plays the full cue, every level)', () {
    test('plays bacaan-iktidal at every assistance level', () {
      for (final level in AssistanceLevel.values) {
        expect(
          resolver.resolve(PrayerState.iktidal, level, zuhurConfig),
          NasynAudio.bacaanIktidal,
          reason: '$level should always resolve iktidal to the full cue',
        );
      }
    });
  });

  group('needsTakbirTransition', () {
    test('is false for takbiratulIhram, iktidal, salam, selesai', () {
      expect(resolver.needsTakbirTransition(PrayerState.takbiratulIhram), isFalse);
      expect(resolver.needsTakbirTransition(PrayerState.iktidal), isFalse);
      expect(resolver.needsTakbirTransition(PrayerState.salam), isFalse);
      expect(resolver.needsTakbirTransition(PrayerState.selesai), isFalse);
    });

    test('is true for every other state', () {
      const otherStates = [
        PrayerState.qiyam,
        PrayerState.rukuk,
        PrayerState.sujud1,
        PrayerState.dudukAntaraSujud,
        PrayerState.sujud2,
        PrayerState.dudukTahiyatAwal,
        PrayerState.dudukTahiyatAkhir,
      ];
      for (final state in otherStates) {
        expect(resolver.needsTakbirTransition(state), isTrue, reason: '$state should get a takbir prefix');
      }
    });
  });

  test('never resolves to a not-yet-recorded asset for any state/level combination', () {
    for (final state in PrayerState.values) {
      for (final level in AssistanceLevel.values) {
        final path = resolver.resolve(state, level, zuhurConfig);
        if (path != null) {
          expect(
            NasynAudio.isPendingRecording(path),
            isFalse,
            reason: '$state/$level resolved to a not-yet-recorded asset: $path',
          );
        }
      }
    }
  });
}
