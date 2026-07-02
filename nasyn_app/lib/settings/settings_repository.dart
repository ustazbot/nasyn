import 'package:shared_preferences/shared_preferences.dart';

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

  static const _kFatihah = 'timing.fatihah';
  static const _kSurah = 'timing.surah';
  static const _kRukuk = 'timing.rukuk';
  static const _kIktidal = 'timing.iktidal';
  static const _kSujud = 'timing.sujud';
  static const _kDuduk = 'timing.duduk';
  static const _kAlertMode = 'alertMode';
  static const _kLocale = 'locale';

  static Future<SettingsRepository> load() async =>
      SettingsRepository(await SharedPreferences.getInstance());

  TimingProfile readTimingProfile() {
    final d = TimingProfile.defaults;
    return TimingProfile(
      fatihahSeconds: _prefs.getInt(_kFatihah) ?? d.fatihahSeconds,
      surahSeconds: _prefs.getInt(_kSurah) ?? d.surahSeconds,
      rukukSeconds: _prefs.getInt(_kRukuk) ?? d.rukukSeconds,
      iktidalSeconds: _prefs.getInt(_kIktidal) ?? d.iktidalSeconds,
      sujudSeconds: _prefs.getInt(_kSujud) ?? d.sujudSeconds,
      dudukSeconds: _prefs.getInt(_kDuduk) ?? d.dudukSeconds,
    ).clamped();
  }

  Future<void> saveTimingProfile(TimingProfile profile) async {
    final p = profile.clamped();
    await _prefs.setInt(_kFatihah, p.fatihahSeconds);
    await _prefs.setInt(_kSurah, p.surahSeconds);
    await _prefs.setInt(_kRukuk, p.rukukSeconds);
    await _prefs.setInt(_kIktidal, p.iktidalSeconds);
    await _prefs.setInt(_kSujud, p.sujudSeconds);
    await _prefs.setInt(_kDuduk, p.dudukSeconds);
  }

  AlertMode readAlertMode() {
    final name = _prefs.getString(_kAlertMode);
    return AlertMode.values
            .where((m) => m.name == name)
            .firstOrNull ??
        AlertMode.senyap;
  }

  Future<void> saveAlertMode(AlertMode mode) =>
      _prefs.setString(_kAlertMode, mode.name);

  AppLocale readLocale() {
    final name = _prefs.getString(_kLocale);
    return AppLocale.values.where((l) => l.name == name).firstOrNull ??
        AppLocale.bm;
  }

  Future<void> saveLocale(AppLocale locale) =>
      _prefs.setString(_kLocale, locale.name);
}
