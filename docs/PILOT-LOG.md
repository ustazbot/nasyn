# NASYN — Log Pilot (Fasa 5)

Satu baris setiap sesi pemerhatian. Isi masa tengok pengguna guna — jangan
tangguh, memori pemerhatian cepat hilang.

**KPI dari PRD §12 yang dijejak melalui log ni:** Kadar Solat Lengkap
Berjaya >95% · False Alert <1% (tak relevan Guided Mode) · Masa setup <3 min.

| Tarikh | Pengguna (kod, bukan nama) | Solat | Level | Selesai sampai Salam? | Guna butang ⏪⏸⏩? | Keliru di mana? | Catatan |
|---|---|---|---|---|---|---|---|
| 2026-07-04 | BOS | Subuh | Bacaan Penuh | Tidak (exit awal — sesi QA) | Tidak | — | Sesi verifikasi teknikal, bukan pilot sebenar |
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
