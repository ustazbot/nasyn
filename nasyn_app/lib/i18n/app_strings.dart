import 'app_locale.dart';

class AppStrings {
  AppStrings._();

  static const Map<String, Map<AppLocale, String>> _strings = {
    'appTitle': {AppLocale.bm: 'NASYN', AppLocale.en: 'NASYN'},
    'tagline': {
      AppLocale.bm: 'Setiap Solat Penting',
      AppLocale.en: 'Every Prayer Matters',
    },
    'guidedMode': {AppLocale.bm: 'GUIDED MODE', AppLocale.en: 'GUIDED MODE'},
    'visionMode': {AppLocale.bm: 'VISION MODE', AppLocale.en: 'VISION MODE'},
    'comingSoon': {AppLocale.bm: 'Akan Datang', AppLocale.en: 'Coming Soon'},
    'takbirOnly': {AppLocale.bm: 'Takbir Sahaja', AppLocale.en: 'Takbir Only'},
    'panduanPosisi': {
      AppLocale.bm: 'Panduan Posisi',
      AppLocale.en: 'Position Guide',
    },
    'fullRecite': {AppLocale.bm: 'Bacaan Penuh', AppLocale.en: 'Full Recite'},
    'mula': {AppLocale.bm: 'MULA', AppLocale.en: 'START'},
    'home': {AppLocale.bm: 'LAMAN UTAMA', AppLocale.en: 'HOME'},
    'setting': {AppLocale.bm: 'TETAPAN', AppLocale.en: 'SETTING'},
    'showRecitation': {
      AppLocale.bm: 'Tunjuk Bacaan',
      AppLocale.en: 'Show Recitation',
    },
    'selesai': {AppLocale.bm: 'SELESAI', AppLocale.en: 'DONE'},
    'rakaatCheck': {AppLocale.bm: 'Rakaat', AppLocale.en: 'Rakaat'},
    'tumaninahCheck': {AppLocale.bm: "Tuma'ninah", AppLocale.en: "Tuma'ninah"},
    'settingsComingSoon': {
      AppLocale.bm: 'Tetapan akan datang',
      AppLocale.en: 'Settings coming soon',
    },
    'rakaatLabel': {AppLocale.bm: 'rakaat', AppLocale.en: 'rakaat'},
    'exitSession': {
      AppLocale.bm: 'Keluar dari sesi solat?',
      AppLocale.en: 'Exit prayer session?',
    },
    'startSession': {AppLocale.bm: 'Teruskan?', AppLocale.en: 'Continue?'},
    'solat': {AppLocale.bm: 'Solat', AppLocale.en: 'Prayer'},
    'ya': {AppLocale.bm: 'Ya', AppLocale.en: 'Yes'},
    'batal': {AppLocale.bm: 'Batal', AppLocale.en: 'Cancel'},
    'bahasa': {AppLocale.bm: 'Bahasa', AppLocale.en: 'Language'},
    'tambahMasa': {
      AppLocale.bm: 'Tambah Masa',
      AppLocale.en: 'Add Time',
    },
    'modAmaran': {AppLocale.bm: 'Mod Amaran', AppLocale.en: 'Alert Mode'},
    'senyap': {AppLocale.bm: 'Senyap', AppLocale.en: 'Silent'},
    'standardMode': {AppLocale.bm: 'Standard', AppLocale.en: 'Standard'},
    'pembelajaran': {AppLocale.bm: 'Pembelajaran', AppLocale.en: 'Learning'},
    'resetDefault': {
      AppLocale.bm: 'Reset ke Default',
      AppLocale.en: 'Reset to Default',
    },
    'rukukLabel': {AppLocale.bm: 'Rukuk', AppLocale.en: 'Ruku\''},
    'iktidalLabel': {AppLocale.bm: 'Iktidal', AppLocale.en: 'I\'tidal'},
    'sujudLabel': {AppLocale.bm: 'Sujud', AppLocale.en: 'Prostration'},
    'dudukLabel': {
      AppLocale.bm: 'Duduk Antara Sujud',
      AppLocale.en: 'Sitting Between Prostrations',
    },
    'saat': {AppLocale.bm: 'saat', AppLocale.en: 'sec'},
    'asasLabel': {AppLocale.bm: 'asas', AppLocale.en: 'base'},
  };

  static String of(String key, AppLocale locale) {
    final entry = _strings[key];
    if (entry == null) return key;
    return entry[locale] ?? entry[AppLocale.bm]!;
  }
}
