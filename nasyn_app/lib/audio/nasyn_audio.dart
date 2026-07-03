/// Audio asset paths for NASYN.
///
/// Semua audio adalah pre-recorded MP3.
/// - Quran: Muhammad Jibreel (set utama, 23 surah) / Al-Misyari (alt, 8 surah)
/// - Bacaan rukun & posisi: Rakaman sendiri (Bos)
///
/// STATUS D-004: APPROVED. Pemilik produk memiliki kelulusan syariah &
/// perundangan Islam, dan Jabatan Mufti Wilayah (JMWP) telah dimaklumkan
/// tentang pembikinan app ini (1 Julai 2026). Full Recite mode DIBUKA
/// tanpa blocking gate untuk bacaan rukun (folder `rukun/`).
///
/// Format penamaan: kebab-case, Bahasa Melayu.
library;

import '../prayer/prayer_config.dart';

class NasynAudio {
  NasynAudio._();

  static const String _quranJibreel = 'assets/audio/quran/muhammad-jibreel/';
  static const String _quranMisyari = 'assets/audio/quran/al-misyari/';
  static const String _rukun = 'assets/audio/rukun/';
  static const String _posisi = 'assets/audio/posisi/';

  // ─── Quran — Muhammad Jibreel (set utama) ───
  // Nama fail ikut set Jibreel (Ash-Sharh, Quraysh, Al-Kawthar, Al-Masad);
  // identifier Dart kekal nama lama supaya call site tak berubah.

  static const String alFatihah = '${_quranJibreel}001-Al-Fatihah.mp3';
  static const String adDhuha = '${_quranJibreel}093-Ad-Dhuha.mp3';
  static const String alInshirah = '${_quranJibreel}094-Ash-Sharh.mp3';
  static const String atTin = '${_quranJibreel}095-At-Tin.mp3';
  static const String alAlaq = '${_quranJibreel}096-Al-Alaq.mp3';
  static const String alQadr = '${_quranJibreel}097-Al-Qadr.mp3';
  static const String alBayyinah = '${_quranJibreel}098-Al-Bayyinah.mp3';
  static const String azZalzalah = '${_quranJibreel}099-Az-Zalzalah.mp3';
  static const String alAdiyat = '${_quranJibreel}100-Al-Adiyat.mp3';
  static const String alQariah = '${_quranJibreel}101-Al-Qariah.mp3';
  static const String atTakathur = '${_quranJibreel}102-At-Takathur.mp3';
  static const String alAsr = '${_quranJibreel}103-Al-Asr.mp3';
  static const String alHumazah = '${_quranJibreel}104-Al-Humazah.mp3';
  static const String alFil = '${_quranJibreel}105-Al-Fil.mp3';
  static const String quraish = '${_quranJibreel}106-Quraysh.mp3';
  static const String alMaun = '${_quranJibreel}107-Al-Maun.mp3';
  static const String alKautsar = '${_quranJibreel}108-Al-Kawthar.mp3';
  static const String alKafirun = '${_quranJibreel}109-Al-Kafirun.mp3';
  static const String anNasr = '${_quranJibreel}110-An-Nasr.mp3';
  static const String alLahab = '${_quranJibreel}111-Al-Masad.mp3';
  static const String alIkhlas = '${_quranJibreel}112-Al-Ikhlas.mp3';
  static const String alFalaq = '${_quranJibreel}113-Al-Falaq.mp3';
  static const String anNas = '${_quranJibreel}114-An-Nas.mp3';

  /// Senarai penuh surah pendek untuk pemilihan (lepas Al-Fatihah)
  static const List<String> surahPendek = [
    adDhuha,
    alInshirah,
    atTin,
    alAlaq,
    alQadr,
    alBayyinah,
    azZalzalah,
    alAdiyat,
    alQariah,
    atTakathur,
    alAsr,
    alHumazah,
    alFil,
    quraish,
    alMaun,
    alKautsar,
    alKafirun,
    anNasr,
    alLahab,
    alIkhlas,
    alFalaq,
    anNas,
  ];

  // ─── Quran — Al-Misyari (alt reciter, subset) ───

  static const String alFatihahMisyari = '${_quranMisyari}001-al-fatihah.mp3';
  // ... 7 lagi surah subset, ikut struktur sama jika diperlukan sebagai
  // alternative reciter setting dalam Tetapan.

  // ─── Bacaan Rukun Solat (Full Recite — Level 3) ───
  // Status: APPROVED — kelulusan syariah/perundangan Islam pemilik produk,
  // JMWP telah dimaklumkan. Tiada blocking gate untuk Full Recite mode.

  static const String takbiratulIhram = '${_rukun}takbiratul-ihram.mp3';
  static const String bacaanRukuk = '${_rukun}tasbih-rukuk.mp3';
  static const String bacaanIktidal = '${_rukun}iktidal.mp3';
  static const String bacaanSujud = '${_rukun}bacaan-sujud.mp3';
  static const String bacaanDudukAntaraSujud =
      '${_rukun}bacaan-duduk-antara-sujud.mp3';
  static const String tahiyatAwal = '${_rukun}tahiyat-awal.mp3';
  static const String tahiyatAkhir = '${_rukun}tahiyat-akhir.mp3';
  static const String salam = '${_rukun}salam.mp3';
  static const String qunut =
      '${_rukun}qunut.mp3'; // Subuh sahaja — aliran lalai rakaat ke-2, selepas iktidal
  // Direkod 2 Julai 2026 — belum diwire ke resolver & belum masuk senarai
  // approved (keputusan Bos).
  static const String doaIftitah = '${_rukun}doa-iftitah.mp3';
  static const String bismillah = '${_rukun}bismillah.mp3';

  // ─── Niat Solat (pre-session cue — dimainkan SEKALI sebelum FSM mula) ───
  // Bukan PrayerState; dimain di permulaan sesi, takbir menyusul selepas
  // audio habis (gate onComplete, bukan fixed timer).

  static const String niatSubuh = '${_rukun}niat-subuh.mp3';
  static const String niatZuhur = '${_rukun}niat-zuhur.mp3';
  static const String niatAsar = '${_rukun}niat-asar.mp3';
  static const String niatMaghrib = '${_rukun}niat-maghrib.mp3';
  static const String niatIsyak = '${_rukun}niat-isyak.mp3';

  /// Niat ikut solat fardu; sunat tiada rakaman niat — sesi terus mula.
  static const Map<PrayerType, String> niatBySolat = {
    PrayerType.subuh: niatSubuh,
    PrayerType.zuhur: niatZuhur,
    PrayerType.asar: niatAsar,
    PrayerType.maghrib: niatMaghrib,
    PrayerType.isyak: niatIsyak,
  };

  // ─── Nama Posisi Ringkas (Position Guide — Level 2) ───
  // BAHARU — tak wujud dalam manifest lama. Ini yang power-kan
  // "Panduan Posisi" dalam spektrum Takbir-only ↔ Full-recite.

  static const String posisiRukuk = '${_posisi}rukuk.mp3';
  static const String posisiSujud = '${_posisi}sujud.mp3';
  static const String posisiSujudKedua = '${_posisi}sujud-kedua.mp3';
  static const String posisiDudukDuaSujud = '${_posisi}duduk-dua-sujud.mp3';
  static const String posisiTahiyatAwal = '${_posisi}tahiyat-awal.mp3';
  static const String posisiTahiyatAkhir = '${_posisi}tahiyat-akhir.mp3';

  // ─── MASIH BELUM DIREKOD ───
  // Guna path placeholder supaya kod tak crash bila dipanggil;
  // NasynAudio.isPendingRecording() akan block playback + log warning.

  static const String handoverNotis = '${_rukun}handover-notis.mp3';

  static const List<String> needRecording = [handoverNotis];

  /// Bacaan rukun — APPROVED (kelulusan syariah/perundangan Islam pemilik
  /// produk, JMWP dimaklumkan 1 Julai 2026). Disimpan sebagai rekod audit
  /// sahaja — bukan gate blocking lagi.
  static const List<String> approvedForFullRecite = [
    takbiratulIhram,
    bacaanRukuk,
    bacaanIktidal,
    bacaanSujud,
    bacaanDudukAntaraSujud,
    tahiyatAwal,
    tahiyatAkhir,
    salam,
    qunut,
    niatSubuh,
    niatZuhur,
    niatAsar,
    niatMaghrib,
    niatIsyak,
  ];

  static bool isPendingRecording(String path) => needRecording.contains(path);

  /// Label UI dari path surah: '.../093-Ad-Dhuha.mp3' → 'Ad-Dhuha'.
  static String surahDisplayName(String path) {
    final file = path.split('/').last;
    return file.substring(4, file.length - 4);
  }
}
