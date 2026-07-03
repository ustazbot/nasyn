import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nasyn_app/audio/audio_cue_resolver.dart';
import 'package:nasyn_app/audio/nasyn_audio.dart';
import 'package:nasyn_app/prayer/prayer_config.dart';
import 'package:nasyn_app/prayer/prayer_state.dart';

void main() {
  final resolver = AudioCueResolver();
  final zuhurConfig = prayerConfigs[PrayerType.zuhur]!;
  final subuhConfig = prayerConfigs[PrayerType.subuh]!;

  group('Takbir Only', () {
    test('only plays audio for takbiratulIhram, nothing else', () {
      expect(
        resolver.resolve(
            PrayerState.takbiratulIhram, AssistanceLevel.takbirOnly, zuhurConfig),
        [NasynAudio.takbiratulIhram],
      );
      expect(
        resolver.resolve(PrayerState.rukuk, AssistanceLevel.takbirOnly, zuhurConfig),
        isEmpty,
      );
      expect(
        resolver.resolve(PrayerState.qiyam, AssistanceLevel.takbirOnly, zuhurConfig),
        isEmpty,
      );
    });
  });

  group('Panduan Posisi', () {
    test('plays position-name cues', () {
      expect(
        resolver.resolve(
            PrayerState.rukuk, AssistanceLevel.panduanPosisi, zuhurConfig),
        [NasynAudio.posisiRukuk],
      );
      expect(
        resolver.resolve(
            PrayerState.sujud1, AssistanceLevel.panduanPosisi, zuhurConfig),
        [NasynAudio.posisiSujud],
      );
      expect(
        resolver.resolve(
            PrayerState.sujud2, AssistanceLevel.panduanPosisi, zuhurConfig),
        [NasynAudio.posisiSujudKedua],
      );
      expect(
        resolver.resolve(
            PrayerState.qiyam, AssistanceLevel.panduanPosisi, zuhurConfig),
        isEmpty,
      );
    });
  });

  group('Full Recite', () {
    test('plays full bacaan for every rukun', () {
      expect(
        resolver.resolve(PrayerState.qiyam, AssistanceLevel.fullRecite, zuhurConfig),
        [NasynAudio.alFatihah],
      );
      expect(
        resolver.resolve(PrayerState.rukuk, AssistanceLevel.fullRecite, zuhurConfig),
        [NasynAudio.bacaanRukuk],
      );
      expect(
        resolver.resolve(
            PrayerState.dudukTahiyatAwal, AssistanceLevel.fullRecite, zuhurConfig),
        [NasynAudio.tahiyatAwal],
      );
      expect(
        resolver.resolve(
            PrayerState.dudukTahiyatAkhir, AssistanceLevel.fullRecite, zuhurConfig),
        [NasynAudio.tahiyatAkhir],
      );
      expect(
        resolver.resolve(PrayerState.salam, AssistanceLevel.fullRecite, zuhurConfig),
        [NasynAudio.salam],
      );
    });
  });

  group('Surah selepas Fatihah (FIQH RULE — qiyam, Full Recite)', () {
    test('rakaat 1 → Fatihah + surahRakaat1; rakaat 2 → Fatihah + surahRakaat2',
        () {
      expect(
        resolver.resolve(
          PrayerState.qiyam,
          AssistanceLevel.fullRecite,
          zuhurConfig,
          currentRakaat: 1,
          surahRakaat1: NasynAudio.alKafirun,
          surahRakaat2: NasynAudio.alIkhlas,
        ),
        [NasynAudio.alFatihah, NasynAudio.alKafirun],
      );
      expect(
        resolver.resolve(
          PrayerState.qiyam,
          AssistanceLevel.fullRecite,
          zuhurConfig,
          currentRakaat: 2,
          surahRakaat1: NasynAudio.alKafirun,
          surahRakaat2: NasynAudio.alIkhlas,
        ),
        [NasynAudio.alFatihah, NasynAudio.alIkhlas],
      );
    });

    test('rakaat 3 & 4 → Fatihah SAHAJA walau surah dipilih', () {
      for (final rakaat in [3, 4]) {
        expect(
          resolver.resolve(
            PrayerState.qiyam,
            AssistanceLevel.fullRecite,
            zuhurConfig,
            currentRakaat: rakaat,
            surahRakaat1: NasynAudio.alKafirun,
            surahRakaat2: NasynAudio.alIkhlas,
          ),
          [NasynAudio.alFatihah],
          reason: 'rakaat $rakaat mesti Fatihah sahaja',
        );
      }
    });

    test('surah tak dipilih → Fatihah sahaja', () {
      expect(
        resolver.resolve(
          PrayerState.qiyam,
          AssistanceLevel.fullRecite,
          zuhurConfig,
          currentRakaat: 1,
        ),
        [NasynAudio.alFatihah],
      );
    });

    test('level bukan Full Recite: qiyam tiada surah langsung', () {
      for (final level in [
        AssistanceLevel.takbirOnly,
        AssistanceLevel.panduanPosisi,
      ]) {
        expect(
          resolver.resolve(
            PrayerState.qiyam,
            level,
            zuhurConfig,
            currentRakaat: 1,
            surahRakaat1: NasynAudio.alKafirun,
          ),
          isEmpty,
        );
      }
    });

    test('qunut tak terjejas — state berasingan dari qiyam', () {
      expect(
        resolver.resolve(
          PrayerState.qunut,
          AssistanceLevel.fullRecite,
          subuhConfig,
          currentRakaat: 2,
          surahRakaat1: NasynAudio.alKafirun,
          surahRakaat2: NasynAudio.alIkhlas,
        ),
        [NasynAudio.qunut],
      );
    });
  });

  group('Iktidal (always plays the full cue, every level)', () {
    test('plays bacaan-iktidal at every assistance level', () {
      for (final level in AssistanceLevel.values) {
        expect(
          resolver.resolve(PrayerState.iktidal, level, zuhurConfig),
          [NasynAudio.bacaanIktidal],
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

  test('semua fail Fatihah & surah pendek wujud dalam assets (kunci drift nama fail bila tukar qari)', () {
    for (final path in [NasynAudio.alFatihah, ...NasynAudio.surahPendek]) {
      expect(File(path).existsSync(), isTrue,
          reason: 'fail tak wujud: $path');
    }
  });

  test('never resolves to a not-yet-recorded asset for any state/level combination', () {
    for (final state in PrayerState.values) {
      for (final level in AssistanceLevel.values) {
        for (final path in resolver.resolve(state, level, zuhurConfig,
            surahRakaat1: NasynAudio.alKafirun,
            surahRakaat2: NasynAudio.alIkhlas)) {
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
