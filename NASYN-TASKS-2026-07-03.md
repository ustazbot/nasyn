# NASYN — Penilaian PRD v3.1 vs Kod + Task List (3 Julai 2026)

Konteks: review menyeluruh PRD-NASYN-v3-1-Kiosk-Edition.md lawan codebase
`nasyn_app/`. Baseline: 56 test lulus, `flutter analyze` bersih, APK release
berjaya build (75.5MB).

---

## A. Penilaian — Apa Yang DAH SIAP (verified dalam kod)

| Item PRD | Status |
|---|---|
| FSM + tahiyat logic per-solat (§8.5, §8.6) | ✅ `prayer_state_engine.dart`, derive dari `PrayerConfig` |
| Tuma'ninah floor 4/3/4/3 immutable + slow-down slider (§8.5) | ✅ `tumaninahDurations` + `TimingProfile.clamped()` |
| Niat audio 5 fardu, gate onComplete (§8.11) | ✅ approved, bukan pending |
| Surah selepas Fatihah r1/r2, fiqh rule r3+ Fatihah sahaja (§8.11) | ✅ `AudioCueResolver` |
| 3 assistance level spectrum di Home (§7) | ✅ segmented control |
| App Pinning interim + exit confirm + PopScope (§9) | ✅ `KioskService`, `SessionGuard` |
| Wakelock sesi (§9) | ✅ `session_wakelock.dart` |
| Settings: timing slider + alert mode 3 pilihan (§8.7/8.8) | ✅ `settings_screen.dart` |
| i18n BM/EN semua 12 state | ✅ `prayerStateLabelsEn` |
| Boot → Home → Session → Summary flow (§10) | ✅ semua skrin wujud |
| Responsive + FittedBox (task list 2 Julai B1–B3) | ✅ |
| Visual redesign (task list 2 Julai D1–D2) | ✅ |
| SUNAT dashed border, Vision "Akan Datang" disabled | ✅ |

Kesimpulan: **semua task 2 Julai (A–D) dah selesai.** Fasa 2 hampir habis.

## B. Gap — Belum Dibuat (dalam skop Guided Mode MVP)

### T1. Penanda "Niat sedang dimainkan" (§10 Niat + Bersedia) — ✅ SIAP 3 JULAI
Masalah: semasa audio niat main, skrin dah papar "Takbiratul Ihram" — warga
emas boleh angkat takbir sebelum niat habis.
Fix: flag `isPlayingNiat` dalam `GuidedModeController`; UI papar icon speaker
+ "Niat sedang dimainkan" sehingga audio habis. Test ditambah, semua lulus.

### T2. Build APK release — ✅ VERIFIED 3 JULAI
`flutter build apk --release` berjaya (75.5MB). Baki: test pada hardware
refurb sebenar (perlu device fizikal — tindakan Bos).

### T3. Dokumen provisioning Device Owner — ✅ SIAP 3 JULAI
`docs/PROVISIONING-DEVICE-OWNER.md` — checklist beli, langkah dpm, verifikasi
per-unit.

### T-DO1. DeviceAdminReceiver untuk Device Owner mode — ✅ KOD SIAP 4 JULAI
- `NasynDeviceAdminReceiver.kt` + `<receiver>` manifest + `device_admin.xml`
- `MainActivity.setupCosuIfDeviceOwner()`: `setLockTaskPackages()` (full lock
  tanpa dialog) + `addPersistentPreferredActivity(HOME)` (auto-relaunch lepas
  reboot) — automatik & idempotent bila device owner
- Unit refurb = **Redmi 9A (M2006C3LG), Android 10, RAM 4GB** — dah disahkan
- **Baki (tindakan fizikal Bos pada skrin device):** enable "Install via USB"
  dalam Developer options MIUI → install APK → sign out Mi Account →
  `dpm set-device-owner` — urutan penuh dalam docs/PROVISIONING-DEVICE-OWNER.md

### T-F0. FIQH-000 gate — TINDAKAN BOS (bukan kod)
D-004 (content) dah APPROVED, tapi FIQH-000 (kelulusan produk keseluruhan
sebelum pilot awam) belum confirm eksplisit. Perlu keputusan bertulis sebelum
Fasa 5 pilot.

## C. Boleh Ditambah Baik (backlog, bukan blocker)

| Item | Nota |
|---|---|
| Light mode (§11 "wajib") | Sekarang dark sahaja. Kiosk provisioned sendiri → defer ke Fasa 6 self-install, masa tu WAJIB |
| `handover-notis.mp3` masih pending recording | Hanya diperlukan bila Vision Mode dibina — tak urgent |
| Ring progress keliling pose icon | BACKLOG comment dah ada dalam kod — tunggu pilot feedback |
| Session Summary: kiraan "Kesalahan" (§10) | Guided Mode tiada error detection (itu Vision) — summary sekarang tepat untuk Guided. Bina bila Vision Mode masuk |
| Volume rocker lock semasa sesi | Elak warga emas ter-mute audio tanpa sedar — pertimbang masa test hardware |

## D. Luar Skop Sekarang (PARKED, ikut PRD)

Vision Mode keseluruhan: Pre-Check screen, countdown Bersedia, calibration
wizard, pose detection Kotlin/MediaPipe, handover, alert enforcement §8.8.
Semua tunggu spike ulangan mounting §8.13.

## Urutan Seterusnya

```
1. (Bos) Dapatkan unit refurb → test APK release pada hardware sebenar
2. T-DO1 DeviceAdminReceiver — bila unit sampai
3. (Bos) FIQH-000 confirmation bertulis
4. Fasa 5 pilot internal
```
