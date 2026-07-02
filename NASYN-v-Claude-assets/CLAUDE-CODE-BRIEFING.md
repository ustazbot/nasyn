# NASYN-v-Claude — Briefing untuk Claude Code

**Tarikh disediakan:** 1 Julai 2026
**Konteks:** Folder ini adalah restart bersih (fresh) selepas PRD naik ke **v3.0 (Kiosk Edition)**. Dokumen ini bridge antara sesi perbincangan strategi (Claude chat) dan kerja implementation (Claude Code).

---

## 1. Baca Dulu Sebelum Mula Kod

Susun ikut keutamaan:

1. `PRD-NASYN-v3-0-Kiosk-Edition.md` — **sumber kebenaran utama**, menang atas semua PRD lama
2. `CTO-AUDIT-2026-06-28.md` — 3 bug diketahui dalam FSM/validator/audio service (rujuk Seksyen 3 di bawah)
3. `NASYN-PROJECT-INSTRUCTION.md` (kalau ada disalin ke sini) — peranan CTO/fiqh guardrails
4. Fail ini (`CLAUDE-CODE-BRIEFING.md`) — apa yang **berubah** sejak audit terakhir

---

## 2. Apa Yang Berubah Sejak CTO-AUDIT-2026-06-28

| Item | Perubahan |
|---|---|
| PRD | v2.0 → **v3.0** — MVP kunci ke Refurb Kiosk (Device Owner mode), self-install jadi Fasa 6 |
| Assets audio | **7/10 bacaan rukun dah direkod** (sebelum ni 0/10) — rujuk Seksyen 3 |
| Assets audio baharu | Kategori `posisi/` (nama ringkas rukun) — **tak wujud dalam kod lama**, perlu wired untuk Level 2 "Panduan Posisi" |
| Assets Quran | Set Al-Husary (23 surah) ditambah sebagai reciter utama; Al-Misyari (8 surah) jadi alt/subset |
| UI copy | "Level 1/2/3" kekal secara logik tapi UI persembahkan sebagai spektrum **Takbir-only ↔ Full-recite** (rujuk PRD Seksyen 7) |
| Session controls | Guide Walkthrough Controls (⏪⏸⏩) — formal spec dalam PRD Seksyen 8.7, belum ada dalam kod |
| Rakaat UI | Pill indicator [1][2][3][4] (bukan dot) — rujuk PRD Seksyen 10 wireframe |

---

## 3. Status Audio Assets (Update Terkini)

### ✅ Sudah Direkod & DILULUSKAN (7/10 lama + 4 bonus baharu)

Lokasi: `assets/audio/rukun/`

- `takbiratul-ihram.mp3`, `bacaan-rukuk.mp3`, `bacaan-iktidal.mp3`, `bacaan-sujud.mp3`,
  `bacaan-duduk-antara-sujud.mp3`, `tahiyat-awal.mp3`, `tahiyat-akhir.mp3`, `salam.mp3`, `qunut.mp3`

✅ **STATUS: D-004 APPROVED — bukan blocking gate lagi.** Pemilik produk memiliki kelulusan syariah & perundangan Islam, dan JMWP telah dimaklumkan tentang pembikinan app ini (1 Julai 2026). **Full Recite mode dibuka terus**, tiada gate audio content sebelum pilot/release.

### ✅ Baharu — Nama Posisi Ringkas (Level 2 "Panduan Posisi")

Lokasi: `assets/audio/posisi/`

- `rukuk.mp3`, `sujud.mp3`, `sujud-kedua.mp3`, `duduk-dua-sujud.mp3`, `tahiyat-awal.mp3`, `tahiyat-akhir.mp3`

Ini **feature gap yang diisi** — sebelum ni Level 2 tak ada audio asset sendiri, guna mixed dari Level 3.

### ❌ Masih Belum Direkod (3 sahaja tinggal, dari 10 asal)

- `doa-iftitah.mp3`
- `bismillah.mp3`
- `handover-notis.mp3` — *"Beralih ke mod panduan masa"*

**Action:** 3 fail (`doa-iftitah`, `bismillah`, `handover-notis`) masih perlu direkod — tiada isu fiqh (arahan/notis, bukan bacaan wajib), boleh siapkan bila-bila.

### Quran (Surah Pendek)

- `assets/audio/quran/al-husary/` — 23 surah, reciter utama
- `assets/audio/quran/al-misyari/` — 8 surah, subset/alt (dah wujud dalam kod lama, kekalkan sebagai option Tetapan)

---

## 4. Fail Manifest Yang Perlu Ganti

`lib/services/audio/nasyn_audio.dart` — **gantikan sepenuhnya** dengan versi baharu yang disediakan (`nasyn_audio.dart` dalam package ini). Perubahan utama:

- Path restructure ikut folder baharu (`quran/al-husary/`, `quran/al-misyari/`, `rukun/`, `posisi/`)
- Tambah `approvedForFullRecite` list — rekod audit D-004 approved, **bukan** gate blocking
- Tambah kelas untuk kategori `posisi/`

**Kena update juga:** `pubspec.yaml` — daftar semua path folder baharu di bawah `flutter: assets:`.

---

## 5. Bug Yang Kena Fix Dulu (Kekal Dari CTO-AUDIT — Belum Fix)

Rujuk `CTO-AUDIT-2026-06-28.md` Seksyen 3 untuk full detail + code fix:

1. **BUG #1 (KRITIKAL — Fiqh):** `prayer_fsm_engine.dart` `_completeRakaat()` — Tahiyat Awal trigger di rakaat 1, patut rakaat 2
2. **BUG #2:** `prayer_logic_validator.dart` `isValidTransition()` — tak guna context `from`
3. **BUG #3:** `audio_service.dart` `play()` — status race condition bila exception

**Jangan sambung UI/feature baharu sebelum BUG #1 fix + retest.**

---

## 6. Git Strategy — Andaian Kerja

> ⚠️ **Bos: sila confirm/betulkan andaian ni sebelum Claude Code push apa-apa.**

Repo sedia ada: `github.com/ustazbot/nasyn` (rujuk memory — dah ada struktur Flutter, FSM, audio service, 8 surah Al-Misyari).

**Andaian saya (default kalau tiada arahan lain):**
- `NASYN-v-Claude/` ialah **clone/checkout baharu** dari repo yang sama — bukan repo git yang berasingan
- Kerja PRD v3.0 dibuat atas **branch baharu**, cadangan nama: `v3-kiosk-edition`
- Merge ke `main` selepas BUG #1/#2/#3 fix + audio manifest baharu wired + test pass
- Commit history sedia ada (FSM, DB, repositories) **dikekalkan** — bukan fresh git init

Kalau Bos nak **fresh git init** (buang history lama terus), atau nak **repo berasingan** untuk v3.0, beritahu Claude Code eksplisit sebelum commit pertama — senang nak reset git init tapi susah nak recover history yang dipadam secara tak sengaja.

---

## 7. Checklist Sebelum Mula Kod Dalam Claude Code

- [ ] Copy `PRD-NASYN-v3-0-Kiosk-Edition.md` ke root folder projek
- [ ] Extract `NASYN-v-Claude-assets.zip` → merge ke dalam `assets/`
- [ ] Ganti `lib/services/audio/nasyn_audio.dart` dengan versi baharu
- [ ] Update `pubspec.yaml` asset paths
- [ ] Confirm git branch strategy (rujuk Seksyen 6) dengan Bos
- [ ] Fix BUG #1 (fiqh — prioriti tertinggi) sebelum apa-apa lain
- [ ] Fix BUG #2, #3
- [ ] Tulis semula test FSM untuk Maghrib & Zuhur (validate tahiyat betul)
- [ ] Hantar 3 fail audio yang tinggal (`doa-iftitah`, `bismillah`, `handover-notis`) untuk direkod — tiada isu fiqh, bukan blocking

---

*Briefing ini adalah handover document dari sesi strategi (Claude chat) ke sesi implementation (Claude Code). Kemaskini fail ini setiap kali ada keputusan besar baharu dari sesi strategi.*
