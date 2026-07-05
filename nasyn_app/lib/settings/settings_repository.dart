import 'package:shared_preferences/shared_preferences.dart';

import '../audio/audio_cue_resolver.dart';
import '../audio/nasyn_audio.dart';
import '../i18n/app_locale.dart';
import 'timing_profile.dart';

/// Mod Amaran (PRD §8.8) — preference sahaja buat masa ini; enjin
/// amaran guna nilai ini bila dibina.
enum AlertMode { senyap, standard, pembelajaran }

/// Simpan/baca tetapan via SharedPreferences. Semua baca melalui
/// clamped() supaya floor tuma'ninah sentiasa dikuatkuasa.
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  // Extra seconds atas floor, key per posture (bukan durasi mutlak —
  // elak floor drift kalau nilai floor dalam kod berubah).
  static const _kRukukExtra = 'timing.extra.rukuk';
  static const _kIktidalExtra = 'timing.extra.iktidal';
  static const _kSujudExtra = 'timing.extra.sujud';
  static const _kDudukExtra = 'timing.extra.dudukAntaraSujud';
  static const _kQiyamReading = 'timing.reading.qiyam';
  static const _kTahiyatReading = 'timing.reading.tahiyat';
  static const _kAlertMode = 'alertMode';
  static const _kLocale = 'locale';
  static const _kSurahRakaat1 = 'lastSurahRakaat1';
  static const _kSurahRakaat2 = 'lastSurahRakaat2';

  static Future<SettingsRepository> load() async =>
      SettingsRepository(await SharedPreferences.getInstance());

  TimingProfile readTimingProfile() => TimingProfile(
    rukukExtra: _prefs.getInt(_kRukukExtra) ?? 0,
    iktidalExtra: _prefs.getInt(_kIktidalExtra) ?? 0,
    sujudExtra: _prefs.getInt(_kSujudExtra) ?? 0,
    dudukExtra: _prefs.getInt(_kDudukExtra) ?? 0,
    qiyamReading: _prefs.getInt(_kQiyamReading) ?? 0,
    tahiyatReading: _prefs.getInt(_kTahiyatReading) ?? 0,
  ).clamped();

  Future<void> saveTimingProfile(TimingProfile profile) async {
    final p = profile.clamped();
    await _prefs.setInt(_kRukukExtra, p.rukukExtra);
    await _prefs.setInt(_kIktidalExtra, p.iktidalExtra);
    await _prefs.setInt(_kSujudExtra, p.sujudExtra);
    await _prefs.setInt(_kDudukExtra, p.dudukExtra);
    await _prefs.setInt(_kQiyamReading, p.qiyamReading);
    await _prefs.setInt(_kTahiyatReading, p.tahiyatReading);
  }

  AlertMode readAlertMode() {
    final name = _prefs.getString(_kAlertMode);
    return AlertMode.values.where((m) => m.name == name).firstOrNull ??
        AlertMode.senyap;
  }

  Future<void> saveAlertMode(AlertMode mode) =>
      _prefs.setString(_kAlertMode, mode.name);

  // Surah selepas Fatihah (Full Recite) — pre-fill pilihan terakhir.
  // Fallback default: gandingan sunnah yang biasa diamalkan
  // (rakaat 1 Al-Kafirun, rakaat 2 Al-Ikhlas), bukan random pick.
  String readSurahRakaat1() =>
      _validSurah(_prefs.getString(_kSurahRakaat1)) ?? NasynAudio.alKafirun;

  String readSurahRakaat2() =>
      _validSurah(_prefs.getString(_kSurahRakaat2)) ?? NasynAudio.alIkhlas;

  Future<void> saveSurahRakaat1(String path) =>
      _prefs.setString(_kSurahRakaat1, path);

  Future<void> saveSurahRakaat2(String path) =>
      _prefs.setString(_kSurahRakaat2, path);

  // Guard nilai lama/rosak dalam prefs — mesti wujud dalam senarai rasmi.
  String? _validSurah(String? path) =>
      NasynAudio.surahPendek.contains(path) ? path : null;

  // Level bantuan — persist supaya "set sekali" kekal antara sesi
  // (pilot 4 Julai: level reset ke default selepas setiap sesi).
  static const _kAssistanceLevel = 'assistanceLevel';

  AssistanceLevel readAssistanceLevel() {
    final name = _prefs.getString(_kAssistanceLevel);
    return AssistanceLevel.values.where((l) => l.name == name).firstOrNull ??
        AssistanceLevel.fullRecite;
  }

  Future<void> saveAssistanceLevel(AssistanceLevel level) =>
      _prefs.setString(_kAssistanceLevel, level.name);

  // Vision Mode (§8.13): pengesahan SUJUD via kamera. Default OFF —
  // pilot mesti opt-in secara sedar (privasi kamera).
  static const _kVisionEnabled = 'visionEnabled';

  bool readVisionEnabled() => _prefs.getBool(_kVisionEnabled) ?? false;

  Future<void> saveVisionEnabled(bool enabled) =>
      _prefs.setBool(_kVisionEnabled, enabled);

  AppLocale readLocale() {
    final name = _prefs.getString(_kLocale);
    return AppLocale.values.where((l) => l.name == name).firstOrNull ??
        AppLocale.bm;
  }

  Future<void> saveLocale(AppLocale locale) =>
      _prefs.setString(_kLocale, locale.name);
}
