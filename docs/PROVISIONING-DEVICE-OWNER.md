# NASYN — Provisioning Device Owner (COSU Kiosk)

Rujukan: PRD v3.1 §4 & §9. Untuk unit refurb yang kita provision sendiri.
Prasyarat: **tiada akaun** pada device (Google/Mi Account) semasa
`dpm set-device-owner` — sign out semua akaun dulu, atau factory reset.

## Unit Semasa: Redmi 9A (M2006C3LG "dandelion")

Android 10, RAM 4GB — lulus spec. Dua sekatan MIUI dikenal pasti (4 Julai 2026):

1. **Install via USB** — MIUI block `adb install` secara default.
   Settings → Additional settings → Developer options → ON-kan
   **"Install via USB"** dan **"USB debugging (Security settings)"**.
   (MIUI perlukan Mi Account log masuk untuk enable toggle ni — buat
   langkah ni DULU sebelum sign out Mi Account.)
2. **Mi Account** — mesti sign out sebelum set device owner:
   Settings → Mi Account → Sign out (perlu password Mi Account).

**Urutan betul: enable Install via USB → install APK → sign out Mi Account
→ dpm set-device-owner.**

## Checklist Sebelum Beli/Provision

- [ ] Android 10+ (bukan 8/9)
- [ ] RAM 3GB (jangan kompromi ke 2GB)
- [ ] Storage 32GB
- [ ] Kamera belakang 720p autofocus (untuk Vision Mode kelak)

## Langkah Provisioning

```bash
# 1. Enable Developer Options + USB Debugging (+ MIUI: Install via USB,
#    USB debugging Security settings — rujuk nota MIUI di atas)

# 2. Install APK release
adb install -r nasyn_app/build/app/outputs/flutter-apk/app-release.apk

# 3. Sign out SEMUA akaun (Mi Account/Google), kemudian set device owner
adb shell dpm set-device-owner com.nasyn.nasyn_app/.NasynDeviceAdminReceiver

# 4. Buka app sekali — MainActivity auto-setup COSU (lock task whitelist +
#    NASYN jadi HOME kekal). Reboot untuk verify auto-relaunch.
adb reboot
```

## Apa Yang Berlaku Selepas Device Owner Aktif (dah siap dalam kod, T-DO1)

- `setLockTaskPackages()` — `startLockTask()` sedia ada jadi full lock,
  tiada dialog "pin screen?", tiada escape gesture
- `addPersistentPreferredActivity(HOME)` — NASYN jadi launcher, auto-relaunch
  lepas reboot
- Setup ni automatik dalam `MainActivity.onCreate` (idempotent, senyap bila
  bukan device owner — dev/emulator tak terkesan)

## Verifikasi Unit (setiap unit sebelum serah)

- [ ] APK release install & buka tanpa crash
- [ ] Flow penuh Subuh (niat → takbir → salam → summary) dengan audio
- [ ] Skrin kekal ON sepanjang sesi (wakelock)
- [ ] Back/Home gesture tak keluar dari sesi tanpa dialog confirm
- [ ] Reboot device → app auto-relaunch (device owner sahaja)
- [ ] Volume audio sesuai pada jarak 1–2 meter
