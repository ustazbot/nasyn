# NASYN — Task List Claude Code (2 Julai 2026, Sesi Design Review)

Konteks: Susulan dari review repo + design discussion. Semua item di bawah
dah confirm dengan Bos — terus implement, tak perlu tanya balik kecuali
disebut "confirm dulu."

---

## A. Fix Segera (Bug/Gap Dari Audit Sebelum Ni)

### A1. i18n rukun state text
- `lib/prayer/prayer_state_labels.dart`: tambah `prayerStateLabelsEn`
  (English map — semua 12 PrayerState, padanan `prayerStateLabelsBm`)
- `lib/ui/prayer_session_screen.dart`: guna locale check (`AppLocale.bm`
  vs `AppLocale.en`) bila papar state label — jangan hardcode
  `prayerStateLabelsBm` terus

### A2. Rakaat pill warna "belum" — solid, bukan alpha-blend
- `lib/theme/app_colors.dart`: tambah `surfaceMuted = Color(0xFF16231D)`
- `_RakaatPillRow`: ganti `primaryTeal.withValues(alpha: 0.25)` dengan
  `AppColors.surfaceMuted` (solid) untuk rakaat belum sampai

### A3. Fix icon lepas Salam
- `_postureIconAssets`: `PrayerState.salam` → `'assets/images/poses/duduk.png'`
  (bukan `qiyam.png` — salam dibuat dalam keadaan duduk)

### A4. Ringkaskan label
- Semua rujukan "Duduk Antara Dua Sujud" → **"Duduk Antara Sujud"**
  (BM label, teks recitation, dan mana-mana UI string lain guna nama ni)

---

## B. Responsive Sizing (BAHARU — sesi hari ni)

### B1. Responsive scale helper
Buat fail baharu `lib/theme/responsive.dart`:
```dart
import 'package:flutter/material.dart';

class Responsive {
  Responsive._();
  static double scale(BuildContext context, {double min = 0.8, double max = 1.2}) {
    final width = MediaQuery.of(context).size.width;
    return (width / 360.0).clamp(min, max);
  }
}
```

### B2. Apply kat Home screen
- `_SolatButton`, `_ModeToggleRow`, `_AssistanceSpectrum`: fontSize guna
  `baseSize * Responsive.scale(context)`, bukan constant terus
- Bungkus setiap text block dengan `FittedBox(fit: BoxFit.scaleDown)`
  sebagai safety net — tak overflow apa jua saiz skrin
- `GridView.count`: tambah `childAspectRatio: 1.4` (kad lebih lapang,
  bukan kotak sempit)

### B3. Apply kat Prayer Session screen
- State label (`prayerStateLabelsBm`/`En`) dan header solat name: sama
  pattern — `Responsive.scale` + `FittedBox`
- Ini juga settle overflow "26 pixel" yang dilaporkan sebelum ni (punca:
  label panjang wrap 2 baris pada state tertentu, FittedBox auto-shrink
  elak push overflow)

---

## C. Perubahan Layout Prayer Session (Dari Design Discussion)

### C1. Buang tuma'ninah display
- Buang `LinearProgressIndicator`/text tuma'ninah dari UI sepenuhnya
- **PENTING:** enforcement tuma'ninah dalam `guided_mode_controller.dart`
  punya timer logic **KEKAL** — ni cuma buang paparan visual, bukan buang
  fiqh requirement. Jangan sentuh logic timer.
- Simpan idea "ring progress keliling icon posisi" sebagai comment
  `// BACKLOG: ring progress indicator — rujuk design session 2 Julai 2026,
  // bina hanya jika pilot feedback tunjuk Takbir Only mode rasa "stuck"`
  di atas widget pose icon — tak perlu bina sekarang

### C2. Buang bottom nav, ganti exit icon
- Buang `AppBottomNav()` dari `prayer_session_screen.dart` sepenuhnya
  (Home + Setting tak relevant mid-solat)
- Tambah icon exit kecil (✕ atau home outline) di header corner,
  sebelah/gantikan language toggle — tap target kekal 48x48dp walaupun
  visual kecil
- Bila tap → guna confirm dialog sedia ada ("Keluar dari sesi solat?")
  sebelum navigate balik Home
- Setting: **hanya** accessible dari Home screen, bukan dari session

### C3. Confirmation dialog sebelum mula sesi
- `home_screen.dart`, `_SolatButton.onTap`: sebelum push ke
  `PrayerSessionScreen`, papar dialog dulu — "Solat [Nama] — Teruskan?"
  dengan butang Ya/Batal
- Tujuan: elak accidental mis-tap pilih solat salah (contoh nak Zuhur,
  termampus tekan Maghrib)
- Simple `AlertDialog`, tak perlu logic kompleks (tiada prayer-time
  awareness — app offline, tak perlu backlog date/time dependency)

---

## D. Visual Redesign (Rujuk Mockup Dalam Chat — Design Session 2 Julai)

### D1. Home screen
- Tambah motif mihrab line-art (SVG, warna gold `#C9A84C`, opacity ~0.5)
  sebagai backdrop halus di belakang wordmark "NASYN"
- Tukar `_AssistanceSpectrum` dari 3 button rata ke segmented control
  style (satu pill container, satu segment highlighted gold/teal, dua
  lagi muted text sahaja — rujuk mockup)
- Settings: tukar dari mana-mana button besar ke icon kecil bulat corner
  (kalau ada button Settings sedia ada dalam layout)
- Kad solat (`_SolatButton`): tambah `border-left` accent 3px, warna ikut
  waktu (Subuh=gold, Zuhur/Asar=hijau terang, Maghrib/Isyak=biru). Sunat
  guna dashed border (bukan solid) untuk signal ia di luar 5 waktu fardu

### D2. Prayer Session screen
- Guide walkthrough controls (⏪⏸⏩): bungkus dalam satu Container pill
  gelap (`surfaceMuted`, border radius besar), center button (Pause/Play)
  jadi circle `accentGreen` dengan icon gelap di atasnya — bukan 3
  IconButton terapung berasingan
- Pose icon: bungkus dalam Container circle (`surfaceMuted` background,
  ~132dp) sebelum letak icon — bagi anchor visual
- Recitation panel (bottom sheet trigger): tukar dari block besar ke pill
  compact dengan leading icon buku (`Icons.book` atau Tabler `ti-book`
  kalau ada icon package sesuai), height lebih kecil dari sekarang
- Rakaat pill "sedang" state: tambah border 1.5px terang (accentGreen)
  di atas fill teal — extra distinction dari state "belum"

---

## Urutan Kerja Dicadangkan

```
1. A1-A4 (fix bug/gap) — cepat, isolated, buat dulu
2. B1-B3 (responsive) — foundational, elok siap sebelum visual redesign
   supaya D1-D2 dibina atas base yang dah responsive
3. C1-C3 (layout changes) — structural, buat sebelum visual polish
4. D1-D2 (visual redesign) — polish akhir sekali, atas struktur yang stabil
```

## Test Selepas Semua Siap

- [ ] Toggle EN pada semua 12 state — confirm label tukar (rukuk, sujud,
      duduk antara sujud, dll — bukan kekal BM)
- [ ] Test Home + Prayer Session pada sekurang-kurangnya 2 saiz skrin
      berbeza (emulator kecil ~5.5" dan besar ~6.5") — confirm tiada
      overflow, text nampak proportional pada dua-dua
- [ ] Flow penuh Subuh (2 rakaat + qunut) sampai Salam — confirm icon
      Salam = duduk, bukan qiyam
- [ ] Confirm tuma'ninah timer masih enforce (test: cuba skip cepat
      sebelum minimum tumaninah tercapai, patut belum boleh advance)
- [ ] Confirm exit icon dalam session masih trigger confirm dialog,
      tak terus keluar tanpa tanya
- [ ] Confirm dialog "Teruskan?" muncul bila pilih solat dari Home

Commit berasingan ikut Bahagian A/B/C/D (4 commit minimum), bukan satu
commit besar — senang review.
