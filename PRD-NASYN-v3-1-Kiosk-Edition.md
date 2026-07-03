# PRD: NASYN - Alat Bantu Solat Pintar (Kiosk Edition)

**Versi:** 3.1 (Vision Mode design refinement — camera mounting, audio Niat & Surah, tuma'ninah floor reconciliation)
**Tarikh:** 3 Julai 2026
**Status:** Draft — Guided Mode MVP dalam progress aktif (Pilihan A); Vision Mode kekal PARKED (Pilihan B, Spike SUJUD belum divalidasi semula)
**Pemilik:** Bos (CTO / Developer / Product)

> **NASYN** (ناسين) — manusia yang pelupa.
> *Every Prayer Matters.*

---

## Changelog v3.0 → v3.1

| Perubahan | Sebab |
|---|---|
| Tambah **§8.13 Camera Mounting — Vision Mode** (rendah + hadap atas, preview OFF) | Design candidate baharu untuk selesaikan Spike SUJUD 0% — proximity-based signal (kepala dekat lens), bukan facial landmark. **Belum divalidasi dengan spike sebenar** |
| Kemaskini **§8.5** jadual tuma'ninah default (4/3/4/3, bukan 3/2/3/2) | Selaras dengan kod terlaksana (`tumaninahDurations` constant) — versi PRD lama tak sync dengan implementation. +1s safety margin di atas fiqh minimum, bukan pengurangan |
| Kemaskini **§8.11 Audio Engine** — Niat Solat (5 fail) + Surah Selepas Fatihah (rakaat 1&2, pilihan berasingan) | Feature siap dilaksanakan dalam Guided Mode — PRD kena reflect keupayaan produk sebenar. D-004 status dikemaskini ke APPROVED |
| Tambah langkah **"NIAT + BERSEDIA"** dalam §10 Information Architecture | Selesaikan isu user tak sempat bersedia (jalan ke sejadah, ambil niat, angkat takbir) sebelum FSM Vision Mode mula aktif track pose |
| Status Vision Mode diperjelas eksplisit di header | Elak kekeliruan — mounting baharu §8.13 adalah *design note*, bukan keputusan yang dah ditest |

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

> **Nota v3.1:** Kaedah hajat yang sama ini turut menjadi asas untuk mekanisme teknikal Vision Mode (kamera proses-sahaja, tiada paparan/simpanan frame — rujuk §8.13). Ini bukan justifikasi berasingan; ia sub-set dari hajat yang sama yang dinyatakan di sini. Keputusan pemilik produk berdasarkan kelulusan syariah sendiri, JMWP dimaklumkan.

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
| **Vision Assisted Mode** (head-based detection) | Tinggi — perlu spike test | **PARKED** — Spike SUJUD asal 0%, mounting baharu (§8.13) adalah design candidate belum divalidasi. Guided Mode MVP diprioritikan dahulu (keputusan Bos, 2 Julai 2026) |
| **Guided Mode** (timing-based, tiada kamera) | Rendah | **Fokus aktif sekarang** — fallback yang sentiasa shippable, dan produk lengkap dengan sendirinya untuk solat duduk/baring, camera fail, low light |

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
| Kiosk method | **Device Owner / COSU mode** — full lock, auto-relaunch selepas reboot. (App Pinning basic sudah dilaksanakan sebagai interim untuk unit test — rujuk §9) |
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

> ⚠️ **Status v3.1:** Spec asal jadual di bawah (front-facing, paras dada) adalah rujukan MVP semasa. Spike preliminary (n=16) rekod SUJUD 0% detection pada konfigurasi ni — rujuk `SPIKE-RESULT.md`. **§8.13 memperkenalkan design candidate baharu** (rendah + hadap atas) untuk selesaikan isu ni, tapi **belum divalidasi dengan spike sebenar**. Vision Mode kekal PARKED sehingga salah satu pendekatan disahkan.

| Aspek | Spec (asal, belum disahkan berjaya) |
|---|---|
| Posisi | Front-facing (pengguna menghadap kamera) |
| Jarak | 1.0m – 1.5m dari pengguna |
| Tinggi kamera | Paras dada (≈ 0.8–1.0m dari lantai) |
| Visibiliti utama | Kepala + bahu mesti sentiasa dalam frame |
| Ruang minimum | 2m × 2m clear area |
| Mounting | Tripod kecil / phone stand — disediakan bersama unit refurb |

> **Nota teknikal:** QIYAM vs IKTIDAL **tidak dibezakan melalui pose** (kedua-dua kepala tegak). Dibezakan melalui **FSM context**.

---

## 6. Operating Modes

### Mode A: Vision Assisted (Head-Based) — MOD UTAMA (Objektif Jangka Panjang, PARKED Buat Masa Ini)

| Aspek | Detail |
|---|---|
| Sasaran | Pengguna mampu berdiri — termasuk persona teras (warga emas hilang ingatan rukun) |
| Input | Kamera → **Head + Shoulder Landmark** → Pose Classifier → FSM |
| Fungsi | Detect posisi automatik, kira rakaat, semak tuma'ninah, **reminder rukun real-time** |
| Offline | ✅ |
| Prasyarat | Spike Test = GO atau PARTIAL (rujuk status semasa di §5 & §8.13) |

### Mode B: Guided Prayer — FOKUS AKTIF MVP SEKARANG

| Aspek | Detail |
|---|---|
| Sasaran | Solat duduk/baring, camera fail, low light, atau pilihan manual pengguna. **Buat masa ini: mod utama produk** sementara Vision Mode PARKED |
| Input | User Timing Profile → Audio + Visual Guidance, dikawal Guide Walkthrough Controls |
| Kamera | ❌ Tidak digunakan |
| Trigger | Manual user selection ATAU auto-handover dari Vision Mode (tracking loss > 10s) — apabila Vision Mode dibina semula |

### Manual Override (Safety Net Dalam Vision Mode)

Walaupun Vision Mode aktif, pengguna boleh tekan ikon tangan → pilih posisi semasa dari senarai → FSM teruskan dari situ. Ini **bukan** mod berasingan — ia safety net dalam Vision Mode, guna komponen kawalan yang sama dengan Guide Walkthrough Controls (rujuk Seksyen 8.7).

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
| **Full Recite** | Level 3 (Bimbingan Penuh) | Audio + visual keseluruhan. Bacaan wajib dimainkan automatik (termasuk Surah selepas Fatihah — rujuk §8.11) — sesuai untuk muallaf/pelajar solat |

> ⚠️ **Nota fiqh — bukan isu, sekadar clarify:** "Takbir Only" bermaksud **app tidak memainkan audio bacaan penuh**, BUKAN bermaksud pengguna skip rukun qauli (Al-Fatihah, tasyahhud, dll.) dalam solat sebenar mereka. Pengguna yang pilih mod ni adalah mereka yang **sudah hafal** bacaan tapi perlukan bantuan mengingati urutan/rakaat sahaja. Tiada isu syarak — ini semata-mata verbosity setting untuk audio guidance.

Toggle ini dipaparkan di **Home Screen**, bukan buried dalam Settings — supaya user set sekali sebelum pilih solat (rujuk wireframe Seksyen 10).

---

## 8. System Architecture

### 8.1 High-Level Pipeline (Head-Based)

```
Camera (front-facing / rendah-hadap-atas — rujuk §8.13)
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
Audio / Visual Output (skrin UI sahaja — TIADA camera preview, rujuk §8.13)
```

### 8.2 Technology Stack

| Lapisan | Teknologi | Sebab |
|---|---|---|
| Framework | Flutter (Dart) | Android, maintain mudah, kiosk plugin |
| **Pose Detection (native)** | **Kotlin + CameraX + MediaPipe Tasks API** | Elak Flutter plugin instability & memory leak |
| Flutter↔Native bridge | Platform Channel | Hantar `PoseClass + confidence + landmarks` |
| State Management | Riverpod | Ringan, stabil |
| Local Storage | **SharedPreferences** (bukan SQLite — keputusan lean, restructure 2 Julai 2026) | Profile settings, timing, alert mode. Single-profile MVP tak perlukan overhead SQLite penuh |
| Audio | **Pre-recorded MP3** (bukan TTS) | Suara natural, tiada copyright |

> **Keputusan CTO:** Pose detection **mesti** native Kotlin dari Day 1, dipanggil dari Flutter via platform channel.

### 8.3 Prayer Pose Classification (Head-Based)

| Signal | Peranan |
|---|---|
| **Head Y-position** (relative to frame & calibration baseline) | PRIMARY — bezakan QIYAM/RUKUK/SUJUD/DUDUK |
| **Head-to-shoulder vertical ratio** | PRIMARY untuk SUJUD (pendekatan asal — rujuk §8.13 untuk alternatif proximity-based) |
| **Shoulder landmarks** | VALIDATOR — masih visible dalam telekung |
| **FSM context** | Bezakan QIYAM vs IKTIDAL (pose identik) |

| Class | Head Signal | Catatan |
|---|---|---|
| QIYAM | Head tinggi (baseline standing) | vs IKTIDAL via FSM |
| RUKUK | Head turun separa, condong ke depan | head-shoulder ratio berubah |
| IKTIDAL | Head tinggi semula | context: selepas RUKUK |
| SUJUD | Head paling rendah, rapat paras lantai (mounting asal) / **paling dekat dengan lens (mounting §8.13)** | Rujuk §8.13 untuk pendekatan proximity-based |
| DUDUK | Head paras sederhana, stabil rendah | vs SUJUD via head height |
| UNKNOWN | Tidak dapat diklasifikasi | trigger HOLD |

**Tahiyat:** ditentukan FSM (jenis solat × rakaat × context), bukan pose.

**Confidence:** ≥80% ACCEPT · 60-79% HOLD · <60% REJECT (adaptive threshold, tak bawah 65% walau low-light). Frame stabilization ≥ 500ms sebelum dianggap sah.

### 8.4 Calibration Wizard

4-step: Berdiri (QIYAM baseline) → Rukuk (head-shoulder ratio) → Sujud (head_y minimum / proximity minimum, ikut mounting yang dipakai) → Duduk. Output: User Head Profile — threshold diperibadikan mengikut tinggi individu.

### 8.5 Prayer State Engine (FSM)

Komponen paling kritikal. **Tidak bergantung pada pose detection** — terima `PoseClass` enum sahaja (dari kamera, guide walkthrough tap, ATAU mock test).

**Menyimpan:** Current State, Expected Next State, Current Rakaat, Current Solat.

**Transition Rule:** Pose Stable (≥500ms) AND Confidence ≥ Threshold AND Tumakninah Complete AND FSM Transition Valid.

**Tumakninah default (floor, dilaksanakan dalam kod — dikemaskini v3.1):**

| Posisi | Floor fiqh minimum | Floor dilaksanakan dalam kod (`tumaninahDurations`) |
|---|---|---|
| Rukuk | 3s | **4s** |
| Iktidal | 2s | **3s** |
| Sujud | 3s | **4s** |
| Duduk antara sujud | 2s | **3s** |

> **Nota v3.1:** Kod guna +1 saat safety margin di atas fiqh minimum di semua posisi — ini **lebih selamat**, bukan pengurangan (tuma'ninah floor fiqh adalah had bawah, melebihinya tidak menjejaskan kesahan solat). Settings Timing (Guided Mode) benarkan user tambah **lebih** masa lagi di atas floor kod ni (slow-down only, 0–10 saat tambahan) — floor kod sendiri **immutable**, tak boleh dikurangkan oleh user walau melalui Settings.

### 8.6 Prayer Logic & Tahiyat Detection

**Sah:** `RUKUK → IKTIDAL`, `SUJUD 1 → DUDUK → SUJUD 2`
**Tidak sah:** `RUKUK → SUJUD` (tertinggal iktidal), `SUJUD 1 → QIYAM` (tertinggal sujud kedua)

**Rakaat:** `Sujud Kedua → Qiyam Baharu = +1 Rakaat`.

| Solat | Rakaat | Tahiyat Awal | Tahiyat Akhir |
|---|---|---|---|
| Subuh | 2 | — | Selepas rakaat 2 |
| Maghrib | 3 | Selepas rakaat **2** | Selepas rakaat 3 |
| Zuhur/Asar/Isyak | 4 | Selepas rakaat **2** | Selepas rakaat 4 |

> ⚠️ Rujuk `CTO-AUDIT-2026-06-28.md` BUG #1 — pastikan fix ini kekal betul (Tahiyat Awal selepas rakaat **2**, bukan 1). **Verified dalam kod semasa (`prayer_state_engine.dart` + `prayer_config.dart`, 3 Julai 2026)** — logic derive dari `PrayerConfig` per-solat, bukan hardcoded conditional, jadi risiko regresi bug jenis ni rendah.

### 8.7 Guide Walkthrough Controls (Klarifikasi Interaksi)

| Kawalan | Fungsi dalam Guided Mode | Fungsi dalam Vision Mode |
|---|---|---|
| ⏪ Back | Override timing, kembali ke rukun sebelumnya | Correction — betulkan kalau FSM tersilap detect state |
| ⏸ Pause | Stop auto-progress sementara | Pause detection pipeline (sama seperti keluar frame). Turut boleh **extend countdown "Bersedia"** sebelum FSM mula aktif (rujuk §10) |
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
| Content validation (D-004) | **APPROVED** (1 Julai 2026) — pemilik produk memiliki kelulusan syariah/perundangan Islam sendiri, Jabatan Mufti Wilayah (JMWP) telah dimaklumkan. Tiada blocking gate untuk Full Recite mode |

**Niat Solat (pre-session cue) — BAHARU v3.1:**
5 rakaman (Subuh, Zuhur, Asar, Maghrib, Isyak), dimainkan **sekali** di permulaan sesi, sebelum Takbiratul Ihram. Niat **bukan** `PrayerState` dalam FSM — ia rukun qalbi (dalam hati), bukan rukun qauli, jadi ia pre-session cue sahaja, bukan state yang FSM "tunggu." Audio-complete gate (bukan fixed timer) memastikan niat tak terputus sebelum sambung ke Takbiratul Ihram.

**Surah Selepas Fatihah (Full Recite, rakaat 1 & 2 sahaja) — BAHARU v3.1:**
User pilih surah **berasingan** untuk rakaat 1 dan rakaat 2 (dari 22 surah pendek, Ad-Dhuha hingga An-Nas). Fiqh rule fixed dalam kod (`AudioCueResolver`): rakaat 1 → Fatihah + surah pilihan 1; rakaat 2 → Fatihah + surah pilihan 2; **rakaat 3/4 (Zuhur/Asar/Isyak) dan rakaat 3 (Maghrib) → Fatihah sahaja, tiada surah**, walau apa jua pilihan user. Default fallback kalau user skip pilih: Al-Kafirun (rakaat 1) + Al-Ikhlas (rakaat 2) — gandingan popular yang biasa diamalkan.

### 8.12 Data Storage

SharedPreferences local-only (rujuk §8.2 — bukan SQLite, keputusan lean). Tiada cloud, login, password, tracking, internet. Logging debug sahaja (session start/end, error type, confidence min/avg).

### 8.13 Camera Mounting — Vision Mode (Design Decision, BELUM Divalidasi Dengan Spike)

> **Status:** Design candidate untuk selesaikan Spike SUJUD 0% (rujuk `SPIKE-RESULT.md`, preliminary n=16). **Belum dijalankan spike sebenar dengan mounting baharu ni.** Vision Mode kekal PARKED di belakang Guided Mode MVP (Pilihan A, keputusan Bos 2 Julai 2026) sehingga salah satu pendekatan (mounting asal §5, atau mounting baharu di sini) disahkan melalui spike ulangan.

**Masalah asal:** Mounting front-facing paras dada (spec §5) — semasa SUJUD, muka pengguna tunduk terus ke lantai, landmark muka/mata hilang sepenuhnya dari sudut pandang kamera. Ini bukan sekadar isu confidence rendah — ia isu struktur (muka memang tak boleh nampak pada geometri ni).

**Pendekatan baharu (cadangan, belum test):** Kamera diletak **rendah, dekat sejadah, menghala ke atas** (contoh rujukan: phone stand seperti reka bentuk video-call biasa, diletak di hadapan/sisi sejadah). Prinsip teras: **jangan cuba "kenal muka" semasa Sujud — guna proximity/saiz kepala dalam frame sebagai signal**, yang secara struktur tak memerlukan muka menghadap kamera.

| Posisi | Signal yang dijangka (mounting baharu) |
|---|---|
| Qiyam | Kepala jauh dari lens (di bahagian atas frame) |
| Rukuk | Kepala mula mendekati lens semasa tunduk ke depan |
| **Sujud** | **Kepala PALING DEKAT dengan lens** — proximity/blob-size jadi signal utama |
| Duduk | Kepala di jarak sederhana — antara Qiyam & Sujud |

**Keputusan fiqh (LOCKED — kelulusan Bos, 3 Julai 2026):**

- Camera preview **OFF sepenuhnya** semasa Prayer Session aktif — skrin papar UI (rakaat, state, guidance) sahaja. Tiada live camera feed dipaparkan kepada sesiapa, termasuk pengguna sendiri
- Frame diproses **in-memory sahaja** oleh MediaPipe, terus dibuang selepas extract koordinat landmark — tiada storan, tiada paparan, tiada penghantaran data keluar peranti (selaras prinsip offline-first sedia ada)
- Output sistem = **koordinat numerik** (contoh `head_y: 0.73, shoulder_x: 0.41`), bukan imej visual, pada bila-bila masa
- **Asas fiqh:** sambungan terus dari kaedah *hajat yang diharuskan* yang dah locked dalam §0 (bantuan golongan uzur & pembelajaran). Mekanisme teknikal ni (proses-sahaja, tiada paparan/simpanan, pengguna hanya rujuk skrin UI bila keliru — bukan lihat kamera) adalah **sub-set dari hajat yang sama**, bukan justifikasi fiqh berasingan. Keputusan pemilik produk berdasarkan kelulusan syariah/perundangan Islam sendiri; JMWP telah dimaklumkan (rujuk §0 dan §8.11 D-004).

**Belum diselesaikan (untuk bila Vision Mode disambung semula):**

- Spike sebenar untuk validate proximity-signal approach ni — **tiada data lagi**, ini cadangan konsep sahaja berdasarkan prinsip geometri kamera
- Risiko fizikal: stand dekat sejadah, laluan tangan pengguna semasa sujud (turun/bangun) — perlu kaji jarak selamat supaya tak tersepak/tertumbuk
- **Cadangan tambahan (belum firm keputusan):** FOV/jarak constraint sebagai calibration checkpoint — sistem hadkan secara structural (software-level crop) supaya bahagian frame di bawah paras tertentu tak pernah diproses, walau apa jua sudut fizikal kamera. Ini defense-in-depth tambahan, bukan pengganti keputusan fiqh di atas
- Perbandingan dengan pendekatan alternatif (kamera tinggi menghadap bawah) yang turut dipertimbangkan tapi tidak dipilih — rujuk nota sejarah keputusan dalam session log 3 Julai 2026 jika perlu rujuk semula

---

## 9. Kiosk & Device Lockdown

> **Rujuk Seksyen 4 (Distribution Strategy)** untuk konteks penuh kenapa dua kaedah ini wujud.

### MVP: Device Owner / COSU Mode (Refurb Unit) — Target Akhir

| Aspek | Detail |
|---|---|
| Provisioning | `dpm set-device-owner` semasa setup unit — **wajib** device dalam keadaan factory-fresh, sebelum ada akaun Google/app lain |
| Ciri | Full lock — tiada back button, tiada nav bar, tiada app switching, notification disabled semasa sesi |
| Reboot recovery | Auto-relaunch app selepas reboot (device owner boleh set default launcher/persistent app) |
| Exit | Hanya melalui flow app sendiri (Session Summary → Home), tiada gesture keluar |

### Interim MVP: App Pinning Basic — **DILAKSANAKAN** (2 Julai 2026)

| Aspek | Detail |
|---|---|
| Status | ✅ Siap — `KioskService` (native Kotlin `startLockTask()`/`stopLockTask()` via Platform Channel `nasyn/kiosk`) |
| Trigger | Auto-pin bila Prayer Session mula, auto-unpin bila Summary reached ATAU exit-confirm "Ya" |
| Error handling | Gagal pin/unpin = senyap (log sahaja, tak throw) — solat tak boleh diblock oleh kegagalan kiosk lock |
| Limitation | Tak auto-relaunch selepas reboot (bukan Device Owner) — acceptable untuk fasa test unit/pilot internal sekarang |

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

### Information Architecture (Dikemaskini v3.1)

```
BOOT (3–5s auto)
  ↓
HOME (mode toggle + level spektrum + pilih solat [+ pilih surah jika 
      Full Recite dipilih — rujuk §8.11])
  ↓
PRE-CHECK (Vision Mode sahaja — camera/light/distance status)
  ↓
NIAT + BERSEDIA (BAHARU v3.1)
  - Audio niat solat (ikut solat dipilih) main sekali — sama fail 
    audio dikongsi Guided & Vision Mode
  - Vision Mode: countdown lembut (~5-8s, cadangan awal) bagi user 
    jalan/bersedia ke posisi sejadah SEBELUM FSM mula aktif track 
    pose — elak false trigger semasa user masih bergerak ke posisi. 
    Guide Walkthrough Controls (⏸) boleh extend countdown jika 
    warga emas perlukan lebih masa
  - Guided Mode: terus sambung ke Takbiratul Ihram lepas audio niat 
    habis main (tiada countdown — tiada isu "user belum sedia" 
    sebab tiada kamera untuk false-trigger)
  ↓
PRAYER SESSION (CORE) ←── Guide Walkthrough Controls + Manual Override sentiasa ada
  ↓
SUMMARY
```

> **Kenapa "Niat + Bersedia" perlu jadi langkah eksplisit (bukan sebahagian Pre-Check):** Masalah asal — dalam Vision Mode, kalau FSM terus aktif serta-merta lepas Pre-Check lulus, user yang baru nak jalan ke sejadah, ambil niat, angkat takbir tak sempat — boleh trigger false detection atau missed Takbiratul Ihram. Langkah ni reuse niat audio (dah dibina untuk Guided Mode) dan reuse Guide Walkthrough Controls (§8.7) yang dah documented — tiada kerja berganda bila Vision Mode akhirnya dibina.

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

- **Mode toggle** (Guided/Vision) — pilihan default berdasarkan Pre-Check status (kalau camera/light gagal, auto-suggest Guided). **Vision Mode disabled/hidden sehingga dibina** (status semasa: PARKED)
- **Assistance spectrum** — set sekali, applies untuk sesi ini. Pilih Full Recite → trigger skrin pilihan Surah (rakaat 1 & 2, rujuk §8.11) sebelum proceed
- **Grid solat** — dark teal buttons, rakaat count dipaparkan terus (bantu ingatan sebelum mula)
- **Bottom nav** — 🌐 BM/EN (language toggle), 🏠 HOME (app icon, balik Home), ⚙ SETTING (timing, calibration, alert mode — rujuk status implementasi §11)

### Screen: Pre-Check (Vision Mode sahaja)

> ⚠️ Status: skrin ni belum dibina (Vision Mode PARKED). Spec di bawah kekal sebagai rujukan design.

Live camera preview, status checks: Badan Dikesan ✔ · Cahaya OK ✔ · Jarak OK ✔. Kalau solat duduk/baring dipilih → skip terus ke Session dengan Guided Mode.

> **Nota v3.1:** Camera preview di skrin ni (semasa Pre-Check sahaja, BUKAN semasa Prayer Session aktif) adalah pengecualian yang dibenarkan untuk tujuan setup — user perlu nampak diri sendiri untuk confirm framing betul. Sebaik Prayer Session bermula, preview OFF sepenuhnya (rujuk §8.13).

### Screen: Niat + Bersedia (BAHARU v3.1)

```
┌─────────────────────────────┐
│                              │
│         SUBUH                │  ← nama solat dipilih
│                              │
│     Niat sedang dimainkan    │
│         🔊 ▮▮▮▮▮▯▯▯▯▯        │
│                              │
│   Bersedia ke tempat solat   │  ← Vision Mode sahaja
│         5...4...3...         │  ← countdown lembut
│                              │
│         [ ⏸ Beri Masa ]      │  ← extend countdown
│                              │
└─────────────────────────────┘
```

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
| Pose gagal akibat telekung | Head-based mengurangkan; sahkan dalam Spike ulangan |
| Android refurbish underpowered | Wajib RAM 3GB; sahkan latency dalam Spike |
| MediaPipe Flutter plugin tak stabil | Native Kotlin layer dari Day 1 — **dilaksanakan** |
| Device Owner tak boleh retrofit HP peribadi | Sebab utama kekal Refurb-first untuk MVP (rujuk Seksyen 4) |
| **SUJUD detection 0% pada mounting asal** | **BELUM SELESAI** — rujuk §8.13 untuk design candidate baharu, belum divalidasi spike |
| Risiko fizikal mounting rendah (§8.13) | Perlu kaji jarak selamat dari laluan tangan semasa sujud — belum diselesaikan |
| Pertimbangan syarak | Skop terhad (muallaf + uzur) + semakan JMWP sebelum pilot awam. Mekanisme kamera proses-sahaja (§8.13) turut dilocked di bawah kaedah hajat yang sama |
| False alert ganggu khusyuk | Target <1% + default Silent Elder mode |

### Fasa Pembangunan

| Fasa | Fokus | Output | Status (3 Julai 2026) |
|---|---|---|---|
| **Fasa 0** | Spike Test (head-based pose) | Go/No-Go decision | Preliminary selesai — SUJUD 0%, INVALIDATED untuk mounting asal. Spike ulangan (mounting §8.13) belum dijalankan |
| Fasa 1 | Scaffolding + FSM (fix BUG #1/#2/#3) + Timing + Audio | Guided Mode core | ✅ Selesai — FSM, timing, audio infra siap & verified |
| **Fasa 2** | UI + Device Owner Kiosk | **Release MVP: Refurb Kiosk Unit** | **Aktif — dalam progress.** Settings ✅, App Pinning (interim) ✅, Wakelock ⏳, Niat+Surah audio ✅, Build APK & test hardware sebenar ⏳ |
| Fasa 3 | Pose Detection + Calibration + Vision Integration | Vision Mode (jika GO) | PARKED — menunggu spike ulangan §8.13 |
| Fasa 4 | Testing | Test coverage | Berterusan (unit test dilaksanakan serentak dengan setiap feature) |
| Fasa 5 | FIQH-000 → Pilot (refurb unit) → Iteration | Validated product | ⏳ FIQH-000 status belum confirm eksplisit (berasingan dari D-004 yang dah APPROVED) |
| **Fasa 6** | **Self-Install APK (Screen Pinning variant)** | **Distribution Fasa 2 — objektif "semua org install sendiri"** | Belum mula |
| Fasa 7 (future) | Raspberry Pi / IoT custom hardware | V2/V3 hardware | Belum mula |

---

## 13. Prinsip Rekabentuk (Summary)

- Offline First · Elderly Friendly · Large Text (≥32px) · One Tap Operation · Minimum Configuration
- Refurb Kiosk First — kawal kualiti pengalaman sebelum buka self-install
- Vision Mode primary **sebagai objektif jangka panjang** — objektif teras membantu ingatan rukun secara real-time, tapi PARKED buat masa ini sehingga Spike SUJUD diselesaikan
- Guided Mode sentiasa shippable sebagai safety net — **dan fokus aktif MVP sekarang**
- Skop pengguna terhad (muallaf + uzur/hilang ingatan) — bukan app solat awam
- Aplikasi percuma — untuk semua yang memerlukan

---

*NASYN — Every Prayer Matters.*
*PRD v3.1 — Guided Mode MVP aktif; Vision Mode PARKED menunggu resolusi Spike SUJUD (rujuk §8.13 untuk design candidate camera mounting baharu, belum divalidasi).*
