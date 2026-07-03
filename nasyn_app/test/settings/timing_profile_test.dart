import 'package:flutter_test/flutter_test.dart';
import 'package:nasyn_app/guided/guided_mode_controller.dart';
import 'package:nasyn_app/prayer/prayer_state.dart';
import 'package:nasyn_app/settings/timing_profile.dart';

void main() {
  test('floor diambil dari tumaninahDurations, bukan hardcode', () {
    expect(
      TimingProfile.rukukFloor,
      tumaninahDurations[PrayerState.rukuk]!.inSeconds,
    );
    expect(
      TimingProfile.iktidalFloor,
      tumaninahDurations[PrayerState.iktidal]!.inSeconds,
    );
    expect(
      TimingProfile.sujudFloor,
      tumaninahDurations[PrayerState.sujud1]!.inSeconds,
    );
    expect(
      TimingProfile.dudukFloor,
      tumaninahDurations[PrayerState.dudukAntaraSujud]!.inSeconds,
    );
  });

  test('clamped() tolak extra negatif — tak boleh bawah floor', () {
    final hacked = TimingProfile.defaults.copyWith(
      rukukExtra: -2,
      iktidalExtra: -1,
      sujudExtra: -10,
      dudukExtra: -5,
    );
    final clamped = hacked.clamped();

    expect(clamped.rukukExtra, 0);
    expect(clamped.iktidalExtra, 0);
    expect(clamped.sujudExtra, 0);
    expect(clamped.dudukExtra, 0);
    // Durasi efektif kekal floor — floor immutable.
    expect(
      clamped.tumaninahFor(PrayerState.rukuk),
      tumaninahDurations[PrayerState.rukuk],
    );
  });

  test('clamped() had extra ke maxExtra', () {
    final over = TimingProfile.defaults.copyWith(rukukExtra: 99);
    expect(over.clamped().rukukExtra, TimingProfile.maxExtra);
  });

  test('tumaninahFor = floor + extra, fixed-posture sahaja', () {
    final p = TimingProfile.defaults.copyWith(sujudExtra: 3);
    expect(
      p.tumaninahFor(PrayerState.sujud1),
      tumaninahDurations[PrayerState.sujud1]! + const Duration(seconds: 3),
    );
    expect(
      p.tumaninahFor(PrayerState.sujud2),
      tumaninahDurations[PrayerState.sujud2]! + const Duration(seconds: 3),
    );
    expect(p.tumaninahFor(PrayerState.qiyam), isNull);
    expect(p.tumaninahFor(PrayerState.qunut), isNull);
  });

  test('default = tiada extra, durasi efektif sama macam floor', () {
    for (final entry in tumaninahDurations.entries) {
      expect(TimingProfile.defaults.tumaninahFor(entry.key), entry.value);
    }
  });
}
