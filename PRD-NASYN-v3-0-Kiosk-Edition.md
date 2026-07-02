# PRD: NASYN - Alat Bantu Solat Pintar (Kiosk Edition)

**Versi:** 3.0 (Fresh restart — Refurb Kiosk First, self-install sebagai fasa lanjutan)
**Tarikh:** 1 Julai 2026
**Status:** Draft — Pending Fasa 0 (Spike Test)
**Pemilik:** Bos (CTO / Developer / Product)

> **NASYN** (ناسين) — manusia yang pelupa.
> *Every Prayer Matters.*

---

## Changelog v2.0 → v3.0

| Perubahan | Sebab |
|---|---|
| **MVP = Refurb Kiosk sahaja** (bukan self-install awam) | Kawal kualiti pengalaman awal — Device Owner mode perlukan device yang kita provision dari kosong |
| **Self-install APK jadi Fasa 2 distribution goal**, bukan requirement MVP | "Semua orang install sendiri" tetap objektif akhir, tapi tak boleh guna Device Owner mode pada HP org lain yang dah ada akaun/app sedia ada |
| Tambah **Distribution Strategy** sebagai seksyen berasingan | Dulu tersirat dalam "Business Model" — sekarang perlu explicit sebab ada 2 channel dengan kiosk method berbeza |
| **Assistance Levels** dipersembahkan sebagai spektrum Takbir-only ↔ Full-recite | UI/UX lebih intuitif untuk warga emas — visual slider konsep, bukan menu "Level 1/2/3" abstrak |
| Tambah **Guide Walkthrough Controls** (rewind/pause/fast-forward) dalam System Architecture | Kawalan manual untuk pelajar solat — berasingan dari Vision detection pipeline |
| **UI/UX Screen Flow** disusun semula ikut wireframe baharu (rakaat pill indicator, mode toggle di Home) | Refine dari lakaran Bos — rakaat counter jadi pill 1-2-3-4 bukan dot, lebih jelas dari 1.5m |
| Persona 1 (Warga Emas) dinaikkan sebagai **primary use-case** dengan konteks peribadi | Objektif produk kena grounded pada keperluan sebenar, bukan abstraksi |

---

## 0. Skop Penggunaan & Pertimbangan Syarak

> **Bahagian ini adalah teras identiti produk, bukan disclaimer semata-mata.**

### Tujuan Penggunaan

NASYN direka khas sebagai **alat bantu (mu'in)**, bukan pengganti (badal), bagi:

- ✅ **Muallaf** — baru masuk Islam, sedang belajar solat dari awal
- ✅ **Warga emas / golongan yang cepat hilang ingatan (uzur)** — lupa rukun, lupa rakaat semasa, kurang keyakinan solat bersendirian
- ✅ Kanak-kanak/pelajar solat dalam konteks pembelajaran berstruktur
- ✅ Penggunaan **individu / bersendirian**

### Di Luar Skop (By Design)

- ❌ Solat berjemaah
- ❌ **Kegunaan awam umum tanpa keperluan khusus** — NASYN bukan direka untuk org yang solatnya sudah lancar/tak perlu bantuan
- ❌ Menggantikan pembelajaran solat secara talaqqi/bertalqin

### Pendirian

Penggunaan alat bantu semasa solat bagi tujuan pembelajaran dan bantuan kepada golongan yang memerlukan adalah satu keperluan (hajat) yang diharuskan. Ia tidak menggantikan tanggungjawab mempelajari solat secara betul.

> **Tindakan diperlukan:** Dapatkan ulasan/pengesahan daripada pihak berautoriti (JMWP) sebelum pelancaran awam (rujuk FIQH-000 gate). Skop pengguna yang terhad (muallaf + uzur/hilang ingatan) adalah bahagian penting dari justifikasi hajat ini — kena kekal jelas dalam semua onboarding & marketing copy supaya tak jadi kekeliruan sebagai "app solat untuk semua orang."

---

## 1. Executive Summary

NASYN (Alat Bantu Solat Pintar) ialah aplikasi Android kiosk yang membantu warga emas yang cepat hilang ingatan rukun solat, muallaf yang sedang belajar, dan mereka yang bermasalah ingatan — untuk solat dengan lebih yakin dan tepat.

**Motivasi produk ini peribadi:** ramai warga emas — termasuk golongan seperti bapa kepada pemilik produk — sering keliru rukun yang mana sedang dilakukan, atau lupa rakaat semasa solat bersendirian. NASYN wujud untuk isu spesifik ini, bukan sebagai app solat generik.

Sistem menggunakan gabungan **Computer Vision (head-based pose detection)** sebagai mod utama, dengan **Guided Mode (timing-based)** sebagai fallback untuk mereka yang solat duduk/baring, atau apabila kamera gagal berfungsi.

Semua audio menggunakan **pre-recorded bacaan** — suara natural, tiada TTS robotik, tiada isu copyright.

Sistem beroperasi **offline sepenuhnya** — tanpa internet, akaun, atau langganan.

### Strategi MVP: Refurb Kiosk First

> **Keputusan CTO (v3.0):** MVP dibina dan diuji di atas **device refurbish yang kita provision sendiri** (Device Owner / COSU kiosk mode). Self-install APK untuk orang awam pasang sendiri adalah **objektif Fasa 2**, bukan keperluan MVP.

**Sebab keputusan ni:**
1. Device Owner mode (full kiosk lock, auto-relaunch selepas reboot) **hanya boleh** diprovision pada device kosong (belum ada akaun Google/app lain) — tak boleh retrofit pada HP peribadi org lain
2. Refurb-first bagi kita kawalan penuh atas hardware baseline (RAM, kamera, Android version) — elak variance yang boleh rosakkan pengalaman pilot awal
3. Self-install (Screen Pinning variant) tetap dirancang, tapi dibina **selepas** Vision Mode & FSM disahkan stabil di refurb unit — bukan serentak

### Strategi Produk (Dua Mod, Risiko Berperingkat)

| Mod | Risiko | Bila Dibina |
|---|---|---|
| **Vision Assisted Mode** (head-based detection) | Tinggi — perlu spike test | **Prioriti utama** — objektif teras produk untuk bantu ingatan rukun secara real-time |
| **Guided Mode** (timing-based, tiada kamera) | Rendah | Fallback yang sentiasa shippable — solat duduk/baring, camera fail, low light |

---

## 2. Objektif Produk

### Objektif Utama

Membantu pengguna:
- Mengingati **rakaat semasa** — paparan besar + counter yang tak boleh terlepas pandang
- Mengingati **rukun solat yang sedang/akan dilakukan (fi'li & qauli)** — ini objektif teras: ramai warga emas keliru "saya baru buat apa, lepas ni apa"
- Mengingati **bacaan solat** — mainkan audio pre-record + papar teks bila diperlukan
- Menjaga **tuma'ninah** — timer untuk setiap posisi
- Menyelesaikan solat dengan **lebih yakin** — tanpa perlu bergantung pada ahli keluarga setiap kali

### Objektif Sekunder

- Membantu proses pembelajaran solat berstruktur (muallaf & kanak-kanak)
- Alat latihan solat untuk institusi pendidikan (tahfiz, pusat muallaf)
- Beroperasi **sepenuhnya offline** — 100% privasi, tiada data keluar dari peranti

---

## 3. Sasaran Pengguna

### Persona 1 (PRIMARY): Warga Emas Hilang Ingatan Rukun

| Aspek | Detail |
|---|---|
| Masalah teras | **Keliru rukun mana sedang dilakukan** — tersasar tengah solat, tak pasti dah rukuk ke belum, lupa rakaat |
| Konteks | Solat bersendirian di rumah, mungkin tiada ahli keluarga untuk bantu setiap waktu |
| Keperluan | Real-time reminder rukun (Vision Mode ideal untuknya), paparan besar, audio jelas, tiada setup rumit |
| Nota produk | Ini persona yang mendorong keseluruhan keutamaan Vision Mode dalam roadmap |

### Persona 2: Muallaf

| Aspek | Detail |
|---|---|
| Masalah | Tidak menghafal bacaan, tidak memahami urutan solat |
| Keperluan | Panduan langkah demi langkah (Guide Walkthrough Controls penting di sini), bacaan penuh, paparan teks, audio natural |

### Persona 3: Pelajar Solat (Kanak-Kanak & Remaja)

| Aspek | Detail |
|---|---|
| Masalah | Masih belajar pergerakan dan bacaan |
| Keperluan | Bimbingan lengkap, visual dan audio, repetition |

### Persona 4: Solat Duduk / Baring (Uzur Syarie)

| Aspek | Detail |
|---|---|
| Masalah | Tidak boleh berdiri atau sujud penuh |
| Keperluan | Guided Mode (timing-based), tiada kamera diperlukan |

---

## 4. Distribution Strategy

> **Seksyen baharu v3.0** — dulu tersirat dalam business model, sekarang eksplisit sebab dua channel ini ada **kaedah kiosk teknikal yang berbeza** dan tak boleh disamakan.

### Fasa MVP: Refurb Kiosk Programme

| Aspek | Detail |
|---|---|
| Device | Android refurbish < RM200, kita beli & provision sendiri |
| Kiosk method | **Device Owner / COSU mode** — full lock, auto-relaunch selepas reboot |
| Setup flow | Kita provision device dari kosong (factory reset → set device owner → install APK → auto-launch config) sebelum serah kepada pengguna |
| Sasaran channel awal | Keluarga/individu yang Bos kenali (termasuk pilot internal), rumah kebajikan, pusat muallaf |
| Model kos | RM150–200 kos unit, disalurkan melalui ehsan/kopi donation atau kos-sahaja |

### Fasa 2: Self-Install APK (Objektif Akhir — Bukan MVP)

| Aspek | Detail |
|---|---|
| Device | HP peribadi pengguna sendiri (Android 9+, RAM 3GB+) |
| Kiosk method | **Session-scoped Screen Pinning** (`startLockTask()`) — auto-pin bila mula solat, auto-unpin bila selesai. Bukan permanent lock — user kekal boleh guna phone macam biasa di luar sesi |
| Setup flow | Download APK dari GitHub Releases → sideload → buka app → guna terus (calibration wizard untuk Vision Mode) |
| Bila dibina | **Selepas** MVP refurb kiosk disahkan stabil (Vision Mode + FSM + audio) — bukan serentak dengan MVP |
| Kenapa defer | Screen Pinning ≠ Device Owner dari segi robustness (contoh: tak auto-relaunch lepas reboot). Perlu implementation & testing berasingan — jangan double scope MVP |

### Prinsip Distribution

```
MVP (sekarang):     Refurb Kiosk sahaja — kita kawal hardware + provisioning penuh
Fasa 2 (lepas MVP):  Self-Install APK — "semua orang boleh install sendiri" jadi kenyataan
```

> **Nota untuk roadmap:** Objektif asal "semua orang boleh install sendiri dan guna terus" **kekal** sebagai matlamat produk — cuma bukan keperluan MVP. Jangan scope creep masa build MVP dengan cuba handle self-install edge cases awal.

---

## 5. Platform & Peranti

### Fasa Perkembangan Hardware

| Fasa | Peranti | Anggaran Kos | Tujuan |
|---|---|---|---|
| **MVP / Spike / Pilot** | Android refurbish < RM200 (kita provision) | RM150–200 | Validate + dev + pilot test |
| **V2** | Raspberry Pi + touchscreen + USB camera | RM350–450 | Purpose-built device |
| **V3 (future)** | Custom IoT (ESP32-S3 + TFT + OV2640) | RM180–200 | Produk hardware dedicated |

### Spesifikasi Android Refurbish (MVP)

| Komponen | Minimum (wajib) | Catatan |
|---|---|---|
| Android | 10+ | MediaPipe Tasks API sokong Android 8+, tapi 10+ untuk kestabilan Device Owner provisioning |
| RAM | **3GB** (jangan 2GB) | MediaPipe + Flutter perlukan headroom |
| Storage | 32GB | App + audio assets + SQLite |
| Kamera belakang | 720p @ 30fps, autofocus | **Guna kamera belakang**, bukan depan |
| CPU | Snapdragon 450 setara ke atas | Untuk inference real-time |

**Calon model refurbish:** Samsung Galaxy A10s, Xiaomi Redmi 8/8A, Redmi Note 7 — julat RM150–200.

> ⚠️ **Verify masa beli:** Ramai unit < RM150 hanya 2GB RAM atau Android 8. Jangan kompromi pada RAM 3GB.

### Camera Placement

| Aspek | Spec |
|---|---|
| Posisi | **Front-facing** (pengguna menghadap kamera) |
| Jarak | **1.0m – 1.5m** dari pengguna |
| Tinggi kamera | Paras dada (≈ 0.8–1.0m dari lantai) |
| Visibiliti utama | **Kepala + bahu** mesti sentiasa dalam frame |
| Ruang minimum | 2m × 2m clear area |
| Mounting | Tripod kecil / phone stand — disediakan bersama unit refurb |

> **Nota teknikal:** QIYAM vs IKTIDAL **tidak dibezakan melalui pose** (kedua-dua kepala tegak). Dibezakan melalui **FSM context**.

---

## 6. Operating Modes

### Mode A: Vision Assisted (Head-Based) — MOD UTAMA

| Aspek | Detail |
|---|---|
| Sasaran | Pengguna mampu berdiri — termasuk persona teras (warga emas hilang ingatan rukun) |
| Input | Kamera → **Head + Shoulder Landmark** → Pose Classifier → FSM |
| Fungsi | Detect posisi automatik, kira rakaat, semak tuma'ninah, **reminder rukun real-time** |
| Offline | ✅ |
| Prasyarat | Spike Test = GO atau PARTIAL |

### Mode B: Guided Prayer — FALLBACK

| Aspek | Detail |
|---|---|
| Sasaran | Solat duduk/baring, camera fail, low light, atau pilihan manual pengguna |
| Input | User Timing Profile → Audio + Visual Guidance, dikawal Guide Walkthrough Controls |
| Kamera | ❌ Tidak digunakan |
| Trigger | Manual user selection ATAU auto-handover dari Vision Mode (tracking loss > 10s) |

### Manual Override (Safety Net Dalam Vision Mode)

Walaupun Vision Mode aktif, pengguna boleh tekan ikon tangan → pilih posisi semasa dari senarai → FSM teruskan dari situ. Ini **bukan** mod berasingan — ia safety net dalam Vision Mode, guna komponen kawalan yang sama dengan Guide Walkthrough Controls (rujuk Seksyen 10).

---

## 7. Tahap Bantuan (Assistance Levels)

### Spektrum Takbir-Only ↔ Full-Recite

> **Refinement v3.0:** Sistem 3-level (Visual/Position/Full) dari v2.0 **kekal secara logik**, tapi dipersembahkan sebagai satu **spektrum/toggle visual** di UI supaya lebih intuitif untuk warga emas — bukan menu pilihan abstrak "Level 1, 2, 3."

```
[ Takbir Only ] ◄────────────────●────────────────► [ Full Recite ]
   (Visual +                  (Position +              (Audio penuh
   audio ringkas)              audio nama rukun)         bacaan wajib)
```

| Posisi Spektrum | Setara Level Lama | Penerangan |
|---|---|---|
| **Takbir Only** | Level 1 (Visual Sahaja) | Paparan rukun + rakaat semasa. Audio minimum (takbir sahaja / bunyi transition). Untuk pengguna yang **dah hafal bacaan** tapi perlukan reminder rukun & rakaat sahaja — ini sesuai untuk persona warga emas hilang ingatan |
| **Tengah** | Level 2 (Panduan Posisi) | Paparan + audio ringkas nama posisi ("Rukuk", "Sujud"). Arahan pertukaran |
| **Full Recite** | Level 3 (Bimbingan Penuh) | Audio + visual keseluruhan. Bacaan wajib dimainkan automatik — sesuai untuk muallaf/pelajar solat |

> ⚠️ **Nota fiqh — bukan isu, sekadar clarify:** "Takbir Only" bermaksud **app tidak memainkan audio bacaan penuh**, BUKAN bermaksud pengguna skip rukun qauli (Al-Fatihah, tasyahhud, dll.) dalam solat sebenar mereka. Pengguna yang pilih mod ni adalah mereka yang **sudah hafal** bacaan tapi perlukan bantuan mengingati urutan/rakaat sahaja. Tiada isu syarak — ini semata-mata verbosity setting untuk audio guidance.

Toggle ini dipaparkan di **Home Screen**, bukan buried dalam Settings — supaya user set sekali sebelum pilih solat (rujuk wireframe Seksyen 10).

---

## 8. System Architecture

### 8.1 High-Level Pipeline (Head-Based)

```
Camera (front-facing)
  ↓
Pose Detection Layer (Abstraction: PoseDetectionProvider)
  ↓
Landmark Extraction → [PRIMARY: head (nose, ears) | VALIDATOR: shoulders]
  ↓
Head-Based Pose Classifier
  ↓
Confidence Scoring (Adaptive: ≥80% accept, 60-79% hold, <60% reject)
  ↓
Tumakninah Validator
  ↓
Prayer State Engine (FSM)  ← QIYAM/IKTIDAL & Tahiyat ditentukan di sini (context)
  ↓                              ↑
  ↓                     Guide Walkthrough Controls (manual override/correction)
  ↓
Prayer Logic Validation
  ↓
Guidance Engine
  ↓
Audio / Visual Output
```

### 8.2 Technology Stack

| Lapisan | Teknologi | Sebab |
|---|---|---|
| Framework | Flutter (Dart) | Android, maintain mudah, kiosk plugin |
| **Pose Detection (native)** | **Kotlin + CameraX + MediaPipe Tasks API** | Elak Flutter plugin instability & memory leak |
| Flutter↔Native bridge | Platform Channel | Hantar `PoseClass + confidence + landmarks` |
| State Management | Riverpod | Ringan, stabil |
| Local Storage | SQLite (sqflite) | Profile, timing, settings, logs |
| Audio | **Pre-recorded MP3** (bukan TTS) | Suara natural, tiada copyright |

> **Keputusan CTO:** Pose detection **mesti** native Kotlin dari Day 1, dipanggil dari Flutter via platform channel.

### 8.3 Prayer Pose Classification (Head-Based)

| Signal | Peranan |
|---|---|
| **Head Y-position** (relative to frame & calibration baseline) | PRIMARY — bezakan QIYAM/RUKUK/SUJUD/DUDUK |
| **Head-to-shoulder vertical ratio** | PRIMARY untuk SUJUD |
| **Shoulder landmarks** | VALIDATOR — masih visible dalam telekung |
| **FSM context** | Bezakan QIYAM vs IKTIDAL (pose identik) |

| Class | Head Signal | Catatan |
|---|---|---|
| QIYAM | Head tinggi (baseline standing) | vs IKTIDAL via FSM |
| RUKUK | Head turun separa, condong ke depan | head-shoulder ratio berubah |
| IKTIDAL | Head tinggi semula | context: selepas RUKUK |
| SUJUD | Head paling rendah, rapat paras lantai | head < shoulder line |
| DUDUK | Head paras sederhana, stabil rendah | vs SUJUD via head height |
| UNKNOWN | Tidak dapat diklasifikasi | trigger HOLD |

**Tahiyat:** ditentukan FSM (jenis solat × rakaat × context), bukan pose.

**Confidence:** ≥80% ACCEPT · 60-79% HOLD · <60% REJECT (adaptive threshold, tak bawah 65% walau low-light). Frame stabilization ≥ 500ms sebelum dianggap sah.

### 8.4 Calibration Wizard

4-step: Berdiri (QIYAM baseline) → Rukuk (head-shoulder ratio) → Sujud (head_y minimum) → Duduk. Output: User Head Profile — threshold diperibadikan mengikut tinggi individu.

### 8.5 Prayer State Engine (FSM)

Komponen paling kritikal. **Tidak bergantung pada pose detection** — terima `PoseClass` enum sahaja (dari kamera, guide walkthrough tap, ATAU mock test).

**Menyimpan:** Current State, Expected Next State, Current Rakaat, Current Solat.

**Transition Rule:** Pose Stable (≥500ms) AND Confidence ≥ Threshold AND Tumakninah Complete AND FSM Transition Valid.

**Tumakninah default:** Rukuk 3s · Iktidal 2s · Sujud 3s · Duduk antara sujud 2s.

### 8.6 Prayer Logic & Tahiyat Detection

**Sah:** `RUKUK → IKTIDAL`, `SUJUD 1 → DUDUK → SUJUD 2`
**Tidak sah:** `RUKUK → SUJUD` (tertinggal iktidal), `SUJUD 1 → QIYAM` (tertinggal sujud kedua)

**Rakaat:** `Sujud Kedua → Qiyam Baharu = +1 Rakaat`.

| Solat | Rakaat | Tahiyat Awal | Tahiyat Akhir |
|---|---|---|---|
| Subuh | 2 | — | Selepas rakaat 2 |
| Maghrib | 3 | Selepas rakaat **2** | Selepas rakaat 3 |
| Zuhur/Asar/Isyak | 4 | Selepas rakaat **2** | Selepas rakaat 4 |

> ⚠️ Rujuk `CTO-AUDIT-2026-06-28.md` BUG #1 — pastikan fix ini kekal betul (Tahiyat Awal selepas rakaat **2**, bukan 1) apabila FSM di-port/refactor untuk v3.0.

### 8.7 Guide Walkthrough Controls (Baharu — Klarifikasi Interaksi)

| Kawalan | Fungsi dalam Guided Mode | Fungsi dalam Vision Mode |
|---|---|---|
| ⏪ Back | Override timing, kembali ke rukun sebelumnya | Correction — betulkan kalau FSM tersilap detect state |
| ⏸ Pause | Stop auto-progress sementara | Pause detection pipeline (sama seperti keluar frame) |
| ⏩ Next | Override timing, terus ke rukun seterusnya | Correction — sync manual kalau detection lag |

Ini komponen kawalan **berasingan** dari bottom nav (BM/EN, HOME, SETTING) — bottom nav adalah navigasi app-level, kawalan ni adalah kawalan **dalam sesi solat** untuk pelajar solat/muallaf yang perlukan kawalan manual.

### 8.8 Error Detection & Alert Modes

**Critical (Alert):** tertinggal iktidal, tertinggal sujud kedua, tambah rakaat, salah tahiyat.
**Minor (Log sahaja):** confidence rendah, pose tidak jelas.

| Mode | Penerangan |
|---|---|
| Mode 1 (Silent Elder) — **default** | Vibration kecil sahaja, tiada visual disruption |
| Mode 2 (Standard) | "⚠ Subhanallah. Sila kembali ke posisi sebelumnya." |
| Mode 3 (Learning) | Arahan terperinci rukun yang dilangkau |

> False Alert Rate **mesti < 1%** — alert salah ganggu khusyuk, lebih teruk dari miss satu detection.

### 8.9 Tracking Loss Recovery & Mode Handover

| Tempoh | Tindakan |
|---|---|
| < 3s | Guna state terakhir (toleransi) |
| 3–10s | Pause detection, papar skrin pause |
| > 10s | **Handover ke Guided Mode** — bekukan `{currentRakaat, currentStep, currentPose, elapsedTumakninah}`, resume dari titik tepat (bukan restart), audio notis halus "Beralih ke mod panduan masa" |

### 8.10 Low Light & Clothing Handling

| Status | Tindakan |
|---|---|
| GOOD | Operasi normal |
| MEDIUM | Amaran halus + turunkan threshold (≥65%) |
| POOR | "Pencahayaan tidak mencukupi" → cadang Guided Mode |

Head-based approach mengurangkan (bukan menghapuskan) risiko telekung/jubah. Jika gagal → handover ke Guided Mode.

### 8.11 Audio Engine

| Aspek | Detail |
|---|---|
| Teknologi | Pre-recorded MP3 — tiada TTS |
| Bahasa | Bahasa Melayu, Bahasa Arab |
| Content validation | Wajib semakan ustaz/JMWP sebelum release (D-004) |

### 8.12 Data Storage

SQLite local-only. Tiada cloud, login, password, tracking, internet. Logging debug sahaja (session start/end, error type, confidence min/avg).

---

## 9. Kiosk & Device Lockdown

> **Rujuk Seksyen 4 (Distribution Strategy)** untuk konteks penuh kenapa dua kaedah ini wujud.

### MVP: Device Owner / COSU Mode (Refurb Unit)

| Aspek | Detail |
|---|---|
| Provisioning | `dpm set-device-owner` semasa setup unit — **wajib** device dalam keadaan factory-fresh, sebelum ada akaun Google/app lain |
| Ciri | Full lock — tiada back button, tiada nav bar, tiada app switching, notification disabled semasa sesi |
| Reboot recovery | Auto-relaunch app selepas reboot (device owner boleh set default launcher/persistent app) |
| Exit | Hanya melalui flow app sendiri (Session Summary → Home), tiada gesture keluar |

### Fasa 2: Session-Scoped Screen Pinning (Self-Install)

| Aspek | Detail |
|---|---|
| Trigger | Auto-pin (`startLockTask()`) bila user tap "MULA SOLAT" — automatik, tak perlu user toggle setting dulu |
| Release | Auto-unpin (`stopLockTask()`) bila sesi selesai (Session Summary) atau user confirm keluar awal |
| Incoming call | Screen pinning standard automatik benarkan call masuk, resume pinned state lepas call habis |
| Limitation diketahui | Tak auto-relaunch selepas reboot (bukan device owner) — edge case jarang berlaku (reboot mid-solat), tak perlu solve untuk v1 self-install |

### Edge Case — Exit Mid-Session

> Tap "HOME" semasa sesi solat sedang berjalan (Guided atau Vision) **mesti** papar confirmation dialog ("Keluar dari sesi solat?") sebelum unpin — elak mis-tap dari warga emas terkeluar accidental tengah solat.

### Motion & Transition

Transitions ≤ 200ms · Tiada fancy animation · Auto resume jika interrupted · Always return HOME selepas session.

---

## 10. UI/UX Screen Flow

### Design Principles

> *"Solat first, interface last"*

Max 2 taps sebelum solat bermula (selepas calibration) · Tiada navigation kompleks · Semua teks ≥ 32px · High contrast · 1–2 meter viewing distance.

### Information Architecture

```
BOOT (3–5s auto)
  ↓
HOME (mode toggle + level spektrum + pilih solat)
  ↓
PRE-CHECK (Vision Mode sahaja — camera/light/distance status)
  ↓
PRAYER SESSION (CORE) ←── Guide Walkthrough Controls + Manual Override sentiasa ada
  ↓
SUMMARY
```

### Screen: Boot

Logo NASYN + tagline "Every Prayer Matters", warna gelap tenang, auto-redirect 3–5s.

### Screen: Home / Solat Selection (rujuk wireframe)

```
┌─────────────────────────────┐
│  [GUIDED MODE] [VISION MODE]│  ← mode toggle, pill button
│                              │
│  Takbir Only ◄──●──► Full   │  ← assistance spectrum
│                    Recite    │
│                              │
│   [ SUBUH ]     [ ZUHUR  ]  │
│   (2 rakaat)    (4 rakaat)  │
│   [ ASAR  ]     [MAGHRIB ]  │
│   (4 rakaat)    (3 rakaat)  │
│   [ ISYAK ]     [ SUNAT  ]  │
│   (4 rakaat)    (2 rakaat)  │
│                              │
│  🌐 BM/EN   🏠 HOME   ⚙ SET │
└─────────────────────────────┘
```

- **Mode toggle** (Guided/Vision) — pilihan default berdasarkan Pre-Check status (kalau camera/light gagal, auto-suggest Guided)
- **Assistance spectrum** — set sekali, applies untuk sesi ini
- **Grid solat** — dark teal buttons, rakaat count dipaparkan terus (bantu ingatan sebelum mula)
- **Bottom nav** — 🌐 BM/EN (language toggle), 🏠 HOME (app icon, balik Home), ⚙ SETTING (timing, calibration, alert mode)

### Screen: Pre-Check (Vision Mode sahaja)

Live camera preview, status checks: Badan Dikesan ✔ · Cahaya OK ✔ · Jarak OK ✔. Kalau solat duduk/baring dipilih → skip terus ke Session dengan Guided Mode.

### Screen: Prayer Session (CORE — rujuk wireframe)

```
┌─────────────────────────────┐
│         ZUHUR                │  ← nama solat
│                              │
│  [1] [2] [3] [4]             │  ← rakaat pill, current highlighted
│                              │
│  ⏪    ⏸    ⏩              │  ← guide walkthrough controls
│                              │
│      (posture silhouette)    │
│         QIYAM                │  ← state semasa, besar
│         قيام                 │  ← label Arab
│                              │
│  ┌─────────────────────┐    │
│  │   show recitation     │    │  ← collapsed panel, tap expand
│  └─────────────────────┘    │
│                              │
│  🌐 BM/EN   🏠 HOME   ⚙ SET │
└─────────────────────────────┘
```

- **Rakaat pill indicator** — nombor 1-2-3-4, current rakaat highlighted dark teal, lain-lain light teal. Lebih jelas dari 1.5m berbanding dot kecil
- **Guide Walkthrough Controls** — rujuk Seksyen 8.7 untuk fungsi penuh
- **Posture silhouette + label BM/Arab** — rukun semasa, teks besar
- **Recitation panel** — collapsed by default (untuk pre-prayer review, bukan primary display semasa solat — elak information overload)
- **Manual Override** — ikon tangan, corner, untuk Vision Mode correction

### Screen: Error/Alert Overlay

Minimal, tak block lama. Default (Silent Elder): vibration sahaja. Kalau visual: "⚠ Subhanallah — kembali ke posisi sebelumnya."

### Screen: Pause / Handover

"Kami sedang mengesan anda..." + animated indicator. Option "Beralih ke mod panduan masa."

### Screen: Session Summary

Rakaat ✔ · Tuma'ninah ✔ · Kesalahan (jumlah). Butang "Selesai" → balik Home.

---

## 11. Visual Identity

### Logo NASYN

Ikon mihrab (gerbang masjid) berwarna gold gradient, dengan figura manusia bersolat (bulatan kepala + garis badan) di tengah dalam warna teal — melambangkan manusia yang "ناسين" (pelupa) dibimbing kembali ke kiblat. Wordmark "NASYN" dalam typeface sans-serif moden, huruf besar, dengan aksen "Y" berwarna teal berbeza dari huruf lain (putih).

### Palette

| Warna | Hex | Peranan |
|---|---|---|
| Hijau Teal dalam | `#0D4F4F` | Primary — background & brand |
| Hijau muda cerah | `#52B788` | Accent — status OK, progress, mode Guided |
| Kuning emas | `#C9A84C` | Rakaat counter, logo arch — elemen "keemasan" |
| Biru (mode Vision) | konsisten dgn wireframe | Accent — mode Vision toggle |
| Putih suci | `#F7F9F7` | Background light mode |
| Arang gelap | `#0F1A14` | Background dark mode |
| Merah amaran | `#C0392B` | Error/alert sahaja |

### Typography

- Display (rakaat counter, state name): Bold, 56–72px
- Body guidance text: Medium, 32–40px
- Label kecil: Regular, 24px minimum

### Design Constraints (Wajib)

Font ≥32px · High contrast (WCAG AA) · Dark + Light mode · Tap target min 48×48dp · Transitions ≤200ms.

---

## 12. Performance, KPI, Risiko & Fasa Pembangunan

### Performance Requirements

| Metrik | Target |
|---|---|
| Pose Detection Latency | < 100ms |
| FSM Response | < 50ms |
| Total Decision Time | < 200ms |
| Frame Stabilization | 500ms |

### MVP KPI

| Metrik | Target |
|---|---|
| Pose Classification Accuracy | >90% (QIYAM/RUKUK/DUDUK), >80% (SUJUD) |
| Rakaat Counting Accuracy | >95% |
| **False Alert Rate** | **<1%** |
| Tracking Recovery Success | >90% |
| Masa Setup (Calibration) | <3 minit |
| Kadar Solat Lengkap Berjaya | >95% |

### Risiko

| Risiko | Status / Mitigasi |
|---|---|
| Pose gagal akibat telekung | Head-based mengurangkan; sahkan dalam Spike 003 |
| Android refurbish underpowered | Wajib RAM 3GB; sahkan latency dalam Spike 008 |
| MediaPipe Flutter plugin tak stabil | Native Kotlin layer dari Day 1 |
| Device Owner tak boleh retrofit HP peribadi | Sebab utama kekal Refurb-first untuk MVP (rujuk Seksyen 4) |
| Pertimbangan syarak | Skop terhad (muallaf + uzur) + semakan JMWP sebelum pilot awam |
| False alert ganggu khusyuk | Target <1% + default Silent Elder mode |

### Fasa Pembangunan

| Fasa | Fokus | Output |
|---|---|---|
| **Fasa 0** | Spike Test (head-based pose) | Go/No-Go decision |
| Fasa 1 | Scaffolding + FSM (fix BUG #1/#2/#3) + Timing + Audio | Guided Mode core |
| Fasa 2 | UI + Device Owner Kiosk | **Release MVP: Refurb Kiosk Unit** |
| Fasa 3 | Pose Detection + Calibration + Vision Integration | Vision Mode (jika GO) |
| Fasa 4 | Testing | Test coverage |
| Fasa 5 | FIQH-000 → Pilot (refurb unit) → Iteration | Validated product |
| **Fasa 6** | **Self-Install APK (Screen Pinning variant)** | **Distribution Fasa 2 — objektif "semua org install sendiri"** |
| Fasa 7 (future) | Raspberry Pi / IoT custom hardware | V2/V3 hardware |

---

## 13. Prinsip Rekabentuk (Summary)

- Offline First · Elderly Friendly · Large Text (≥32px) · One Tap Operation · Minimum Configuration
- Refurb Kiosk First — kawal kualiti pengalaman sebelum buka self-install
- Vision Mode primary — objektif teras membantu ingatan rukun secara real-time
- Guided Mode sentiasa shippable sebagai safety net
- Skop pengguna terhad (muallaf + uzur/hilang ingatan) — bukan app solat awam
- Aplikasi percuma — untuk semua yang memerlukan

---

*NASYN — Every Prayer Matters.*
*PRD v3.0 — Refurb Kiosk First. Self-Install APK adalah objektif Fasa 2, bukan keperluan MVP.*
