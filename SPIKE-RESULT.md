# Fasa 0: Head-Based Pose Spike — Interim Result

**Tarikh:** 2026-07-02
**Device:** Xiaomi Redmi 9A (`M2006C3LG`), Android 10, ~3.8GB RAM, MediaTek Helio G25
**Status:** ⚠️ **PRELIMINARY — bukan verdict akhir.** Sampel jauh di bawah protokol penuh (≥15–20 rep setiap kelas pose, per design spec). Lihat "Apa Belum Cukup" di bawah sebelum buat keputusan produk atas laporan ini.

---

## Ringkasan Data

Data ditarik dari `pose_spike_tally.csv` — 16 baris, semua dari sesi smoke-test (Task 7), bukan dari protokol manual penuh yang dirancang dalam design spec.

| Kelas Pose | Bilangan Sampel | Confidence (min–max) | Betul (✓) |
|---|---|---|---|
| QIYAM | **0** | — | — |
| RUKUK | 2 | 69–71% | 2/2 |
| SUJUD | **0** (lihat isu kritikal di bawah) | — | — |
| DUDUK | 1 | 60% | 1/1 |
| UNKNOWN | 13 | 0–58% | (bukan pose sebenar) |

Dari 13 baris UNKNOWN: 9 baris confidence=0 (tiada landmark dikesan langsung), 2 baris confidence 54/58 (landmark dikesan tapi di bawah threshold 60% ACCEPT), 2 baris lagi termasuk dalam RUKUK/DUDUK yang disebut di atas.

### Latency (selepas fix perkaitan timestamp — commit `db4b48f`/`5e395a2`)

| Metrik | Nilai |
|---|---|
| n | 16 |
| Purata | 44.6ms |
| Min | 3ms |
| Max | 134ms |
| ~P95 (anggaran, n=16) | ~84–134ms |
| Target PRD | <100ms |

Purata jauh di bawah target, tapi satu outlier (134ms) melebihi 100ms — dengan n=16 tak cukup untuk anggaran p95 yang boleh dipercayai.

---

## 🔴 Isu Kritikal: SUJUD — Zero Landmark Detection

Semasa ujian langsung (bukan dari CSV — overlay diperhatikan secara real-time oleh Bos), **SUJUD sentiasa terus UNKNOWN dengan confidence 0 dan tiada titik landmark langsung** (bukan sekadar salah klasifikasi — MediaPipe tidak mengesan sebarang pose).

**Punca yang disyaki:** Kamera depan (front-facing) dipasang paras dada (~0.8–1.0m dari lantai) menghadap pengguna. Semasa sujud, muka pengguna menghadap **ke bawah ke arah lantai/sejadah**, bukan ke arah kamera — jadi kamera kemungkinan hanya nampak bahagian belakang/atas kepala dan badan yang sangat tunduk ke depan. Model MediaPipe Pose (dilatih kebanyakan atas manusia berdiri/duduk tegak) berkemungkinan gagal mengecam "manusia" langsung dalam orientasi tersungkur begini dari sudut kamera ini.

**Ini melanggar andaian PRD §5** ("Camera Placement... Front-facing... Visibiliti utama: Kepala + bahu mesti sentiasa dalam frame") — dalam praktik, kepala + bahu **tidak** kekal dalam frame yang berguna semasa sujud dengan kedudukan kamera ini.

**Bukan diagnosis penuh** — Bos pilih untuk rekod terus sebagai limitation dan teruskan, bukan siasat punca lanjut (contoh: cuba jarak/sudut kamera lain) buat masa ini.

---

## Apa Belum Cukup (Sebab Ini Interim, Bukan Verdict)

- **QIYAM: 0 sampel** — tiada data langsung untuk pose paling asas.
- **RUKUK/DUDUK: 1–2 sampel setiap satu** — jauh di bawah ≥15–20 rep yang diperlukan protokol, tak cukup untuk anggaran accuracy yang bermakna.
- **SUJUD: dikesahkan gagal** (lihat atas) tapi belum diuji sama ada penyelesaian mudah (kedudukan/sudut kamera lain) boleh betulkan — hanya diterima sebagai limitation semasa.
- **Semua ujian guna pakaian harian** — telekung/jubah dan variasi pencahayaan (per design spec, susulan selepas asas confirm) **belum diuji langsung**.
- Data ini dari sesi smoke-test eksploratori (Task 7), bukan protokol ≥15–20 rep/kelas yang dirancang dalam design spec §"Test Protocol".

---

## Cadangan Verdict Sementara

**PARTIAL** — bukan GO, bukan NO-GO penuh:

- ✅ Signal positif: RUKUK/DUDUK yang diklasifikasi betul menunjukkan pendekatan head-based *boleh* berfungsi bila kepala/bahu kekal dalam frame; latency purata jauh di bawah target.
- 🔴 Blocker jelas: SUJUD gagal sepenuhnya dengan setup kamera semasa (chest-height, front-facing) — ini **mesti** diselesaikan (reposisi kamera / sudut lain / terima Guided Mode fallback untuk rukun ini) sebelum Vision Mode boleh diisytiharkan GO untuk keseluruhan solat.
- ⚠️ Data QIYAM/RUKUK/DUDUK jauh tidak mencukupi untuk sebarang kesimpulan accuracy yang boleh dipercayai — perlu jalankan protokol penuh (≥15–20 rep/kelas) sebelum verdict akhir.

## Next Steps Dicadangkan

1. Jalankan protokol manual penuh (≥15–20 rep setiap QIYAM/RUKUK/SUJUD/DUDUK, pakaian biasa) untuk dapatkan sampel mencukupi — walaupun SUJUD dijangka gagal, kekalkan dalam protokol untuk sahkan kekerapan kegagalan.
2. Sebelum/semasa itu, uji sekurang-kurangnya satu variasi kedudukan/sudut kamera untuk SUJUD (contoh: kamera lebih tinggi menghadap ke bawah, atau sudut condong) — kalau ini menyelesaikan isu, ubah spesifikasi Camera Placement PRD §5 dan bukan NO-GO Vision Mode sepenuhnya.
3. Selepas asas (pakaian biasa) mencukupi, teruskan susulan telekung/jubah + pencahayaan rendah per design spec.

---

## Keputusan Bos (2026-07-02)

**Teruskan ke Fasa 1** (FSM + Guided Mode core) walaupun data spike masih tipis dan SUJUD belum selesai.

**Sebab:** Pemerhatian langsung berulang kali menunjukkan titik landmark (dots hijau) sentiasa mengiringi muka + bahu dengan stabil untuk pose selain SUJUD — cukup meyakinkan untuk teruskan pembangunan tanpa tunggu protokol penuh selesai.

**Implikasi:**
- Vision Mode integration (Fasa 3 dalam roadmap PRD §12) masih bergantung pada SUJUD diselesaikan (reposisi kamera / sudut) sebelum boleh declare GO penuh — ini **belum** selesai, cuma pembangunan lain (FSM, Guided Mode) tak perlu tunggu.
- Fasa 1 (FSM + Guided Mode, timing-based, tiada kamera) adalah pilihan selamat untuk teruskan sekarang sebab ia **tidak bergantung** pada Vision Mode/pose classification langsung — sebab inilah PRD sendiri strukturkan Fasa 1 sebelum Fasa 3 (Vision Integration).
- Protokol ujian penuh (≥15-20 rep/kelas) + eksperimen kedudukan kamera SUJUD masih outstanding — patut disambung selari atau sebelum Fasa 3 bermula, bukan dibuang terus.
