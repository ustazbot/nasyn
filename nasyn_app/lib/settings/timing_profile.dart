import '../guided/guided_mode_controller.dart';
import '../prayer/prayer_state.dart';

/// Profil masa Guided Mode. Nilai tuma'ninah TIDAK boleh bawah floor
/// dalam [tumaninahDurations] (sumber tunggal — fiqh minimum + safety
/// margin, sudah diverify dalam kod). Fatihah/Surah bebas dalam julat UI.
class TimingProfile {
  final int fatihahSeconds;
  final int surahSeconds;
  final int rukukSeconds;
  final int iktidalSeconds;
  final int sujudSeconds;
  final int dudukSeconds;

  const TimingProfile({
    required this.fatihahSeconds,
    required this.surahSeconds,
    required this.rukukSeconds,
    required this.iktidalSeconds,
    required this.sujudSeconds,
    required this.dudukSeconds,
  });

  // Floor dari tumaninahDurations — JANGAN hardcode nombor di sini.
  static final int rukukFloor =
      tumaninahDurations[PrayerState.rukuk]!.inSeconds;
  static final int iktidalFloor =
      tumaninahDurations[PrayerState.iktidal]!.inSeconds;
  static final int sujudFloor =
      tumaninahDurations[PrayerState.sujud1]!.inSeconds;
  static final int dudukFloor =
      tumaninahDurations[PrayerState.dudukAntaraSujud]!.inSeconds;

  /// Default = floor kod semasa; behavior sesi tak berubah tanpa tetapan.
  static final TimingProfile defaults = TimingProfile(
    fatihahSeconds: 30,
    surahSeconds: 20,
    rukukSeconds: rukukFloor,
    iktidalSeconds: iktidalFloor,
    sujudSeconds: sujudFloor,
    dudukSeconds: dudukFloor,
  );

  /// Clamp semua nilai tuma'ninah ke floor — dipanggil pada setiap
  /// laluan simpan DAN baca, jadi nilai bawah floor mustahil sampai
  /// ke controller walau storage dirosakkan.
  TimingProfile clamped() => TimingProfile(
        fatihahSeconds: fatihahSeconds.clamp(20, 90),
        surahSeconds: surahSeconds.clamp(20, 90),
        rukukSeconds: rukukSeconds < rukukFloor ? rukukFloor : rukukSeconds,
        iktidalSeconds:
            iktidalSeconds < iktidalFloor ? iktidalFloor : iktidalSeconds,
        sujudSeconds: sujudSeconds < sujudFloor ? sujudFloor : sujudSeconds,
        dudukSeconds: dudukSeconds < dudukFloor ? dudukFloor : dudukSeconds,
      );

  TimingProfile copyWith({
    int? fatihahSeconds,
    int? surahSeconds,
    int? rukukSeconds,
    int? iktidalSeconds,
    int? sujudSeconds,
    int? dudukSeconds,
  }) =>
      TimingProfile(
        fatihahSeconds: fatihahSeconds ?? this.fatihahSeconds,
        surahSeconds: surahSeconds ?? this.surahSeconds,
        rukukSeconds: rukukSeconds ?? this.rukukSeconds,
        iktidalSeconds: iktidalSeconds ?? this.iktidalSeconds,
        sujudSeconds: sujudSeconds ?? this.sujudSeconds,
        dudukSeconds: dudukSeconds ?? this.dudukSeconds,
      );

  /// Duration tuma'ninah untuk state tertentu, atau null untuk state
  /// yang bukan fixed-posture (qiyam, tahiyat, dll — kekal ikut
  /// controller logic sedia ada).
  Duration? tumaninahFor(PrayerState state) => switch (state) {
        PrayerState.rukuk => Duration(seconds: rukukSeconds),
        PrayerState.iktidal => Duration(seconds: iktidalSeconds),
        PrayerState.sujud1 ||
        PrayerState.sujud2 =>
          Duration(seconds: sujudSeconds),
        PrayerState.dudukAntaraSujud => Duration(seconds: dudukSeconds),
        _ => null,
      };
}
