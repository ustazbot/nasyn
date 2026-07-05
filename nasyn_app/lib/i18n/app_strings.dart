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
    'tempohBacaan': {
      AppLocale.bm: 'Tempoh Bacaan Sendiri',
      AppLocale.en: 'Own Recitation Duration',
    },
    'tempohBacaanNota': {
      AppLocale.bm:
          'Untuk Takbir Sahaja & Panduan Posisi — app tunggu '
          'anda habis baca, kemudian maju sendiri. 0 = tunggu butang ⏩.',
      AppLocale.en:
          'For Takbir Only & Position Guide — the app waits for '
          'you to finish reciting, then advances. 0 = wait for ⏩ button.',
    },
    'qiyamBacaanLabel': {
      AppLocale.bm: 'Qiyam (Fatihah + surah)',
      AppLocale.en: 'Qiyam (Fatihah + surah)',
    },
    'tahiyatBacaanLabel': {AppLocale.bm: 'Tahiyat', AppLocale.en: 'Tashahhud'},
    'manualLabel': {AppLocale.bm: 'Manual (⏩)', AppLocale.en: 'Manual (⏩)'},
    'niatPlaying': {
      AppLocale.bm: 'Niat sedang dimainkan',
      AppLocale.en: 'Intention being played',
    },
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
    'tambahMasa': {AppLocale.bm: 'Tambah Masa', AppLocale.en: 'Add Time'},
    'modAmaran': {AppLocale.bm: 'Mod Amaran', AppLocale.en: 'Alert Mode'},
    'senyap': {AppLocale.bm: 'Senyap', AppLocale.en: 'Silent'},
    'modVisi': {AppLocale.bm: 'Mod Visi (Kamera)', AppLocale.en: 'Vision Mode (Camera)'},
    'visionAktif': {AppLocale.bm: 'Aktif — sahkan sujud', AppLocale.en: 'Active — confirms sujud'},
    'visionOff': {AppLocale.bm: 'Mati — buka Tetapan', AppLocale.en: 'Off — open Settings'},
    'modVisiLabel': {
      AppLocale.bm: 'Pengesahan sujud melalui kamera',
      AppLocale.en: 'Sujud confirmation via camera',
    },
    'modVisiNota': {
      AppLocale.bm:
          'Kamera depan mengesan bila kepala sampai ke sejadah — masa '
          'tuma\'ninah sujud bermula pada waktu yang tepat. Kamera aktif '
          'semasa sesi solat sahaja. Tiada gambar disimpan.',
      AppLocale.en:
          'The front camera detects when your head reaches the mat — sujud '
          'tuma\'ninah timing starts at the right moment. Camera is active '
          'only during prayer sessions. No images are stored.',
    },
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
    'pilihSurah': {AppLocale.bm: 'Pilih Surah', AppLocale.en: 'Choose Surah'},
    'surahRakaat1': {
      AppLocale.bm: 'Surah Rakaat 1',
      AppLocale.en: 'Surah for Rakaat 1',
    },
    'surahRakaat2': {
      AppLocale.bm: 'Surah Rakaat 2',
      AppLocale.en: 'Surah for Rakaat 2',
    },
    'asasLabel': {AppLocale.bm: 'asas', AppLocale.en: 'base'},
  };

  static String of(String key, AppLocale locale) {
    final entry = _strings[key];
    if (entry == null) return key;
    return entry[locale] ?? entry[AppLocale.bm]!;
  }
}
