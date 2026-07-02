import 'package:flutter_test/flutter_test.dart';
import 'package:nasyn_app/prayer/prayer_config.dart';
import 'package:nasyn_app/prayer/prayer_state.dart';
import 'package:nasyn_app/prayer/prayer_state_engine.dart';

void main() {
  group('PrayerStateEngine - Zuhur (4 rakaat, tahiyat awal after 2)', () {
    test('walks the full expected state sequence', () {
      final engine = PrayerStateEngine(prayerConfigs[PrayerType.zuhur]!);

      final expected = <(PrayerState, int)>[
        (PrayerState.qiyam, 1),
        (PrayerState.rukuk, 1),
        (PrayerState.iktidal, 1),
        (PrayerState.sujud1, 1),
        (PrayerState.dudukAntaraSujud, 1),
        (PrayerState.sujud2, 1),
        (PrayerState.qiyam, 2),
        (PrayerState.rukuk, 2),
        (PrayerState.iktidal, 2),
        (PrayerState.sujud1, 2),
        (PrayerState.dudukAntaraSujud, 2),
        (PrayerState.sujud2, 2),
        (PrayerState.dudukTahiyatAwal, 2),
        (PrayerState.qiyam, 3),
        (PrayerState.rukuk, 3),
        (PrayerState.iktidal, 3),
        (PrayerState.sujud1, 3),
        (PrayerState.dudukAntaraSujud, 3),
        (PrayerState.sujud2, 3),
        (PrayerState.qiyam, 4),
        (PrayerState.rukuk, 4),
        (PrayerState.iktidal, 4),
        (PrayerState.sujud1, 4),
        (PrayerState.dudukAntaraSujud, 4),
        (PrayerState.sujud2, 4),
        (PrayerState.dudukTahiyatAkhir, 4),
        (PrayerState.salam, 4),
        (PrayerState.selesai, 4),
      ];

      expect(engine.currentState, PrayerState.takbiratulIhram);
      expect(engine.currentRakaat, 1);

      for (final (expectedState, expectedRakaat) in expected) {
        engine.advance();
        expect(engine.currentState, expectedState);
        expect(engine.currentRakaat, expectedRakaat);
      }
      expect(engine.isComplete, isTrue);
    });

    test('previous() reverses the full sequence back to the start', () {
      final engine = PrayerStateEngine(prayerConfigs[PrayerType.zuhur]!);
      const totalTransitions = 28;

      for (var i = 0; i < totalTransitions; i++) {
        engine.advance();
      }
      expect(engine.isComplete, isTrue);

      for (var i = 0; i < totalTransitions; i++) {
        engine.previous();
      }

      expect(engine.currentState, PrayerState.takbiratulIhram);
      expect(engine.currentRakaat, 1);
    });
  });

  group('PrayerStateEngine - Subuh (2 rakaat, no tahiyat awal)', () {
    test('rakaat 2 passes through qunut between iktidal and sujud1', () {
      final engine = PrayerStateEngine(prayerConfigs[PrayerType.subuh]!);
      final visited = <(PrayerState, int)>[];

      while (!engine.isComplete) {
        engine.advance();
        visited.add((engine.currentState, engine.currentRakaat));
      }

      // Rakaat 1: iktidal terus ke sujud1, TIADA qunut.
      final r1 = visited.where((v) => v.$2 == 1).map((v) => v.$1).toList();
      final r1Iktidal = r1.indexOf(PrayerState.iktidal);
      expect(r1[r1Iktidal + 1], PrayerState.sujud1,
          reason: 'rakaat 1 mesti terus iktidal → sujud1');
      expect(r1, isNot(contains(PrayerState.qunut)));

      // Rakaat 2: iktidal → qunut → sujud1.
      final r2 = visited.where((v) => v.$2 == 2).map((v) => v.$1).toList();
      final r2Iktidal = r2.indexOf(PrayerState.iktidal);
      expect(r2[r2Iktidal + 1], PrayerState.qunut,
          reason: 'Subuh rakaat 2 mesti laluan qunut selepas iktidal');
      expect(r2[r2Iktidal + 2], PrayerState.sujud1);
    });

    test('previous() is symmetric through qunut on rakaat 2', () {
      final engine = PrayerStateEngine(prayerConfigs[PrayerType.subuh]!);
      var transitions = 0;
      while (!engine.isComplete) {
        engine.advance();
        transitions++;
      }

      for (var i = 0; i < transitions; i++) {
        engine.previous();
      }
      expect(engine.currentState, PrayerState.takbiratulIhram);
      expect(engine.currentRakaat, 1);
    });

    test('previous() from sujud1 on rakaat 2 returns to qunut, rakaat 1 to iktidal', () {
      final engine = PrayerStateEngine(prayerConfigs[PrayerType.subuh]!);

      // Rakaat 1: advance sampai sujud1, previous → iktidal.
      while (engine.currentState != PrayerState.sujud1) {
        engine.advance();
      }
      engine.previous();
      expect(engine.currentState, PrayerState.iktidal);
      engine.advance(); // balik ke sujud1

      // Rakaat 2: advance sampai sujud1, previous → qunut.
      while (!(engine.currentState == PrayerState.sujud1 &&
          engine.currentRakaat == 2)) {
        engine.advance();
      }
      engine.previous();
      expect(engine.currentState, PrayerState.qunut);
      engine.previous();
      expect(engine.currentState, PrayerState.iktidal);
    });

    test('never enters dudukTahiyatAwal', () {
      final engine = PrayerStateEngine(prayerConfigs[PrayerType.subuh]!);
      final visitedStates = <PrayerState>[];

      while (!engine.isComplete) {
        engine.advance();
        visitedStates.add(engine.currentState);
      }

      expect(visitedStates, isNot(contains(PrayerState.dudukTahiyatAwal)));
      expect(visitedStates.last, PrayerState.selesai);
      expect(engine.currentRakaat, 2);
    });
  });

  group('PrayerStateEngine - qunut hanya untuk solat qunutEligible', () {
    test('Zuhur (qunutEligible: false) tidak pernah masuk qunut', () {
      final engine = PrayerStateEngine(prayerConfigs[PrayerType.zuhur]!);
      final visitedStates = <PrayerState>[];

      while (!engine.isComplete) {
        engine.advance();
        visitedStates.add(engine.currentState);
      }

      expect(visitedStates, isNot(contains(PrayerState.qunut)));
    });
  });

  group('PrayerStateEngine - Maghrib (3 rakaat, tahiyat awal after 2)', () {
    test('fires tahiyat awal after rakaat 2 and tahiyat akhir after rakaat 3', () {
      final engine = PrayerStateEngine(prayerConfigs[PrayerType.maghrib]!);

      var sawTahiyatAwal = false;
      while (!engine.isComplete) {
        engine.advance();
        if (engine.currentState == PrayerState.dudukTahiyatAwal) {
          sawTahiyatAwal = true;
          expect(
            engine.currentRakaat,
            2,
            reason: 'BUG #1: tahiyat awal must fire after rakaat 2, not rakaat 1',
          );
        }
        if (engine.currentState == PrayerState.dudukTahiyatAkhir) {
          expect(engine.currentRakaat, 3);
        }
      }

      expect(sawTahiyatAwal, isTrue);
      expect(engine.currentRakaat, 3);
    });
  });
}
