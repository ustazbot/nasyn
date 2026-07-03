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

> ⚠️ **Update 4 Julai 2026:** `dpm set-device-owner` via adb turut disekat
> MIUI (perlukan "USB debugging (Security settings)" = perlukan SIM).
> **Kaedah muktamad tanpa SIM: QR Provisioning (di bawah).**

## Kaedah Muktamad: QR Provisioning (tanpa SIM, tanpa adb)

1. **Factory reset** device (Settings → About phone → Factory reset)
2. Pada skrin welcome selepas reset: **tap 6 kali** di mana-mana → QR
   scanner provisioning muncul
3. Sambung WiFi bila diminta → **scan `docs/provisioning-qr.png`**
4. Android muat turun APK dari GitHub Release (`v1.0.0-pilot`) dan set
   NASYN sebagai device owner secara automatik
5. Verify: `adb shell dumpsys device_policy | grep -i owner`

QR mengandungi: component `com.nasyn.nasyn_app/.NasynDeviceAdminReceiver`,
URL APK release, dan signature checksum
`0aYii5yojEAHB1Hlr36XuuddvC_DDkuQ89sj-ZZJtws` (SHA-256 cert, base64url).
**Jana semula QR bila signing key berubah** (checksum tak sepadan = provisioning gagal).

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
