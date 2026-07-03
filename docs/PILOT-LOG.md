# NASYN — Log Pilot (Fasa 5)

Satu baris setiap sesi pemerhatian. Isi masa tengok pengguna guna — jangan
tangguh, memori pemerhatian cepat hilang.

**KPI dari PRD §12 yang dijejak melalui log ni:** Kadar Solat Lengkap
Berjaya >95% · False Alert <1% (tak relevan Guided Mode) · Masa setup <3 min.

| Tarikh | Pengguna (kod, bukan nama) | Solat | Level | Selesai sampai Salam? | Guna butang ⏪⏸⏩? | Keliru di mana? | Catatan |
|---|---|---|---|---|---|---|---|
| 2026-07-04 | BOS | Subuh | Bacaan Penuh | Tidak (exit awal — sesi QA) | Tidak | — | Sesi verifikasi teknikal, bukan pilot sebenar |
| 2026-07-04 | BOS | Zuhur | Bacaan Penuh | ✅ Ya — 4/4 sampai Salam + Summary | Tidak | — | Pilot pertama LENGKAP. Verified dari rakaman: tahiyat awal selepas rakaat 2, pill 3-state betul, skrin kekal ON sepanjang ~13 min (mWakefulness=Awake 21/21 sampel), Summary auto + unpin bersih |
| 2026-07-04 | BOS | Maghrib | Takbir Sahaja | ✅ Ya | Ya (⏩ di qiyam/tahiyat — by design) | Persoalan: level ni untuk Vision Mode? | 2 penemuan: (1) BUG audio iktidal 7s terpotong oleh floor 3s — FIXED (dual-gate semua level); (2) salam senyap dalam Takbir Sahaja — by design, kekal |
| 2026-07-04 | BOS | Isyak | Panduan Posisi | ✅ Ya | Ya — dan ITULAH isu utama | Kena tekan ⏩ pada setiap qiyam & selepas tahiyat awal — rasa mengganggu | Cue nama posisi OK. Fix iktidal disahkan. Penemuan UX: manual-Next pada qiyam/tahiyat = friction utama level bukan-Bacaan-Penuh. Nota tambahan: pilihan level reset ke Bacaan Penuh selepas sesi (tak persist) |
|  |  |  |  |  |  |  |  |

## Soalan khusus untuk diperhati (dari backlog)

- Takbir Only mode: adakah pengguna rasa "stuck" tanpa progress indicator?
  (penentu sama ada ring progress dibina — rujuk BACKLOG comment dalam kod)
- Volume: pernah ter-tekan volume rocker sampai audio hilang? (penentu
  sama ada volume lock dibina)
- Saiz teks cukup besar dari jarak sejadah sebenar?
- Adakah pengguna faham "Niat sedang dimainkan" atau cuba tekan sesuatu?

## Gate sebelum pilot luaran (bukan keluarga)

- [ ] Device Owner aktif (sign out Mi Account → dpm set-device-owner)
- [ ] FIQH-000 keputusan bertulis Bos
- [ ] Sekurang-kurangnya 3 sesi pilot dalaman lengkap tanpa isu kritikal
