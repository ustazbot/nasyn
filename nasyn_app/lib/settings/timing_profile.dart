import '../guided/guided_mode_controller.dart';
import '../prayer/prayer_state.dart';

/// Profil masa Guided Mode — slow-down only. User hanya boleh TAMBAH
/// masa (0–10s) atas floor [tumaninahDurations]; floor immutable dan
/// tak boleh dikurangkan. Simpan extra seconds, bukan durasi mutlak —
/// elak floor drift kalau nilai floor berubah kemudian hari.
class TimingProfile {
  final int rukukExtra;
  final int iktidalExtra;
  final int sujudExtra;
  final int dudukExtra;

  /// Tempoh Bacaan Sendiri (saat) untuk state bacaan-sendiri dalam level
  /// Takbir Sahaja/Panduan Posisi — user set ikut kelajuan bacaan sendiri,
  /// app auto-maju bila tempoh habis (⏩ masih boleh maju awal).
  /// 0 = manual (tunggu ⏩, behavior asal). Full Recite tak guna nilai ni
  /// (audio bacaan sendiri yang jadi gate).
  final int qiyamReading; // qiyam & qunut
  final int tahiyatReading; // tahiyat awal & akhir

  const TimingProfile({
    required this.rukukExtra,
    required this.iktidalExtra,
    required this.sujudExtra,
    required this.dudukExtra,
    this.qiyamReading = 0,
    this.tahiyatReading = 0,
  });

  /// Extra maksimum atas floor (cadangan task; ubah di sini sahaja).
  static const int maxExtra = 10;

  /// Tempoh Bacaan Sendiri maksimum (saat).
  static const int maxReading = 120;

  // Floor dari tumaninahDurations — JANGAN hardcode nombor di sini.
  static final int rukukFloor =
      tumaninahDurations[PrayerState.rukuk]!.inSeconds;
  static final int iktidalFloor =
      tumaninahDurations[PrayerState.iktidal]!.inSeconds;
  static final int sujudFloor =
      tumaninahDurations[PrayerState.sujud1]!.inSeconds;
  static final int dudukFloor =
      tumaninahDurations[PrayerState.dudukAntaraSujud]!.inSeconds;

  /// Default = tiada extra; behavior sesi sama macam floor kod.
  static const TimingProfile defaults = TimingProfile(
    rukukExtra: 0,
    iktidalExtra: 0,
    sujudExtra: 0,
    dudukExtra: 0,
  );

  /// Clamp semua extra ke [0, maxExtra] — dipanggil pada setiap laluan
  /// simpan DAN baca, jadi nilai negatif (bawah floor) mustahil sampai
  /// ke controller walau storage dirosakkan.
  TimingProfile clamped() => TimingProfile(
    rukukExtra: rukukExtra.clamp(0, maxExtra),
    iktidalExtra: iktidalExtra.clamp(0, maxExtra),
    sujudExtra: sujudExtra.clamp(0, maxExtra),
    dudukExtra: dudukExtra.clamp(0, maxExtra),
    qiyamReading: qiyamReading.clamp(0, maxReading),
    tahiyatReading: tahiyatReading.clamp(0, maxReading),
  );

  TimingProfile copyWith({
    int? rukukExtra,
    int? iktidalExtra,
    int? sujudExtra,
    int? dudukExtra,
    int? qiyamReading,
    int? tahiyatReading,
  }) => TimingProfile(
    rukukExtra: rukukExtra ?? this.rukukExtra,
    iktidalExtra: iktidalExtra ?? this.iktidalExtra,
    sujudExtra: sujudExtra ?? this.sujudExtra,
    dudukExtra: dudukExtra ?? this.dudukExtra,
    qiyamReading: qiyamReading ?? this.qiyamReading,
    tahiyatReading: tahiyatReading ?? this.tahiyatReading,
  );

  /// Tempoh Bacaan Sendiri untuk state bacaan; null = manual (tunggu ⏩)
  /// atau state bukan bacaan-sendiri.
  Duration? readingDurationFor(PrayerState state) {
    final saat = switch (state) {
      PrayerState.qiyam || PrayerState.qunut => qiyamReading,
      PrayerState.dudukTahiyatAwal ||
      PrayerState.dudukTahiyatAkhir => tahiyatReading,
      _ => 0,
    };
    return saat > 0 ? Duration(seconds: saat) : null;
  }

  /// Extra seconds untuk state fixed-posture; 0 untuk state lain.
  int extraFor(PrayerState state) => switch (state) {
    PrayerState.rukuk => rukukExtra,
    PrayerState.iktidal => iktidalExtra,
    PrayerState.sujud1 || PrayerState.sujud2 => sujudExtra,
    PrayerState.dudukAntaraSujud => dudukExtra,
    _ => 0,
  };

  /// Durasi tuma'ninah efektif (floor + extra) untuk state fixed-posture,
  /// atau null untuk state bukan fixed-posture (qiyam, tahiyat, dll).
  Duration? tumaninahFor(PrayerState state) {
    final floor = tumaninahDurations[state];
    if (floor == null) return null;
    return floor + Duration(seconds: extraFor(state));
  }
}
