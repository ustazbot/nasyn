import 'package:flutter_test/flutter_test.dart';
import 'package:nasyn_app/guided/guided_mode_controller.dart';
import 'package:nasyn_app/prayer/prayer_state.dart';
import 'package:nasyn_app/settings/timing_profile.dart';

void main() {
  test('floor diambil dari tumaninahDurations, bukan hardcode', () {
    expect(TimingProfile.rukukFloor,
        tumaninahDurations[PrayerState.rukuk]!.inSeconds);
    expect(TimingProfile.iktidalFloor,
        tumaninahDurations[PrayerState.iktidal]!.inSeconds);
    expect(TimingProfile.sujudFloor,
        tumaninahDurations[PrayerState.sujud1]!.inSeconds);
    expect(TimingProfile.dudukFloor,
        tumaninahDurations[PrayerState.dudukAntaraSujud]!.inSeconds);
  });

  test('clamped() tolak nilai bawah floor — Rukuk 2s jadi 4s', () {
    final hacked = TimingProfile.defaults.copyWith(
      rukukSeconds: 2,
      iktidalSeconds: 1,
      sujudSeconds: 0,
      dudukSeconds: -5,
    );
    final clamped = hacked.clamped();

    expect(clamped.rukukSeconds, 4);
    expect(clamped.iktidalSeconds, 3);
    expect(clamped.sujudSeconds, 4);
    expect(clamped.dudukSeconds, 3);
  });

  test('clamped() benarkan nilai atas floor', () {
    final longer = TimingProfile.defaults.copyWith(rukukSeconds: 10);
    expect(longer.clamped().rukukSeconds, 10);
  });

  test('tumaninahFor memetakan state fixed-posture sahaja', () {
    final p = TimingProfile.defaults.copyWith(sujudSeconds: 7);
    expect(p.tumaninahFor(PrayerState.sujud1), const Duration(seconds: 7));
    expect(p.tumaninahFor(PrayerState.sujud2), const Duration(seconds: 7));
    expect(p.tumaninahFor(PrayerState.qiyam), isNull);
    expect(p.tumaninahFor(PrayerState.qunut), isNull);
  });
}
