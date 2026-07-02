/// Audio asset paths for NASYN.
///
/// Semua audio adalah pre-recorded MP3.
/// - Quran: Al-Husary (set utama, 23 surah) / Al-Misyari (alt, 8 surah)
/// - Bacaan rukun & posisi: Rakaman sendiri (Bos)
///
/// STATUS D-004: APPROVED. Pemilik produk memiliki kelulusan syariah &
/// perundangan Islam, dan Jabatan Mufti Wilayah (JMWP) telah dimaklumkan
/// tentang pembikinan app ini (1 Julai 2026). Full Recite mode DIBUKA
/// tanpa blocking gate untuk bacaan rukun (folder `rukun/`).
///
/// Format penamaan: kebab-case, Bahasa Melayu.
class NasynAudio {
  NasynAudio._();

  static const String _quranHusary = 'assets/audio/quran/al-husary/';
  static const String _quranMisyari = 'assets/audio/quran/al-misyari/';
  static const String _rukun = 'assets/audio/rukun/';
  static const String _posisi = 'assets/audio/posisi/';

  // ─── Quran — Al-Husary (set utama) ───

  static const String alFatihah = '${_quranHusary}001-Al-Fatihah.mp3';
  static const String adDhuha = '${_quranHusary}093-Ad-Dhuha.mp3';
  static const String alInshirah = '${_quranHusary}094-Al-Inshirah.mp3';
  static const String atTin = '${_quranHusary}095-At-Tin.mp3';
  static const String alAlaq = '${_quranHusary}096-Al-Alaq.mp3';
  static const String alQadr = '${_quranHusary}097-Al-Qadr.mp3';
  static const String alBayyinah = '${_quranHusary}098-Al-Bayyinah.mp3';
  static const String azZalzalah = '${_quranHusary}099-Az-Zalzalah.mp3';
  static const String alAdiyat = '${_quranHusary}100-Al-Adiyat.mp3';
  static const String alQariah = '${_quranHusary}101-Al-Qariah.mp3';
  static const String atTakathur = '${_quranHusary}102-At-Takathur.mp3';
  static const String alAsr = '${_quranHusary}103-Al-Asr.mp3';
  static const String alHumazah = '${_quranHusary}104-Al-Humazah.mp3';
  static const String alFil = '${_quranHusary}105-Al-Fil.mp3';
  static const String quraish = '${_quranHusary}106-Quraish.mp3';
  static const String alMaun = '${_quranHusary}107-Al-Maun.mp3';
  static const String alKautsar = '${_quranHusary}108-Al-Kautsar.mp3';
  static const String alKafirun = '${_quranHusary}109-Al-Kafirun.mp3';
  static const String anNasr = '${_quranHusary}110-An-Nasr.mp3';
  static const String alLahab = '${_quranHusary}111-Al-Lahab.mp3';
  static const String alIkhlas = '${_quranHusary}112-Al-Ikhlas.mp3';
  static const String alFalaq = '${_quranHusary}113-Al-Falaq.mp3';
  static const String anNas = '${_quranHusary}114-An-Nas.mp3';

  /// Senarai penuh surah pendek untuk pemilihan (lepas Al-Fatihah)
  static const List<String> surahPendek = [
    adDhuha, alInshirah, atTin, alAlaq, alQadr, alBayyinah, azZalzalah,
    alAdiyat, alQariah, atTakathur, alAsr, alHumazah, alFil, quraish,
    alMaun, alKautsar, alKafirun, anNasr, alLahab, alIkhlas, alFalaq, anNas,
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
  static const String qunut = '${_rukun}qunut.mp3'; // Subuh sahaja — aliran lalai rakaat ke-2, selepas iktidal

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

  static const String doaIftitah = '${_rukun}doa-iftitah.mp3';
  static const String bismillah = '${_rukun}bismillah.mp3';
  static const String handoverNotis = '${_rukun}handover-notis.mp3';

  static const List<String> needRecording = [
    doaIftitah,
    bismillah,
    handoverNotis,
  ];

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
  ];

  static bool isPendingRecording(String path) => needRecording.contains(path);
}
