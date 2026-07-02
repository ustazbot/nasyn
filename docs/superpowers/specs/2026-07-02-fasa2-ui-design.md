# Fasa 2 (Part 1): Real Visual UI — Design

**Tarikh:** 2026-07-02
**Sumber:** PRD-NASYN-v3-0-Kiosk-Edition.md §10 (UI/UX Screen Flow), §11
(Visual Identity), `NASYN-app-sample-design/*.png` (wireframe reference,
matches PRD exactly), `icon-solat/*.png` (posture silhouette assets)
**Bergantung pada:** Fasa 1 (FSM + Guided Mode core, merged to `master`) —
this replaces Fasa 1's plain/unstyled UI with the real PRD-designed one,
without touching `lib/prayer/`, `lib/audio/`, or `lib/guided/` logic.

## Tujuan

Bina UI visual sebenar (Boot, Home, Prayer Session, Session Summary) ikut
wireframe & palette PRD §10-11, atas Guided Mode yang sudah berfungsi
penuh dari Fasa 1. Fasa 2 ini adalah separuh pertama roadmap PRD Fasa 2
("UI + Device Owner Kiosk") — **kiosk/Device Owner lockdown adalah
sub-projek kedua, berasingan**, dibrainstorm/dibina selepas ini.

Bukan skop bahagian ini: Pre-Check screen (Vision Mode sahaja, kamera
belum wujud), Pause/Handover screen (Vision Mode sahaja), Error/Alert
Overlay (bergantung pada pose-mismatch detection, tiada makna dalam
Guided Mode murni — sama alasan seperti Fasa 1's Out of Scope), light
mode (dark mode sahaja buat masa ini — PRD sendiri jadikan warna gelap
sebagai default), kiosk lockdown/Device Owner (sub-projek berasingan),
kalibrasi & persistence settings (Fasa 1 sengaja tiada storan lagi).

## 1. Visual Foundation

**`lib/theme/app_colors.dart`** — palet PRD §11 sebagai constants:

```dart
class AppColors {
  static const primaryTeal = Color(0xFF0D4F4F);   // background & brand
  static const accentGreen = Color(0xFF52B788);   // OK, progress, Guided
  static const accentGold = Color(0xFFC9A84C);    // rakaat counter, logo arch
  static const accentBlue = Color(0xFF3B82C4);    // Vision mode accent (disabled state)
  static const darkBg = Color(0xFF0F1A14);        // dark mode background
  static const errorRed = Color(0xFFC0392B);      // error/alert only
  static const lightText = Color(0xFFF7F9F7);     // text on dark bg
}
```

(Exact blue hex not specified in PRD §11 beyond "konsisten dgn wireframe" —
sampled from the reference wireframe image, close to standard Material
blue used there.)

**`lib/theme/app_text_styles.dart`** — via `ThemeData.textTheme`: Display
(rakaat counter, state name) 56–72px bold; Body (guidance text) 32–40px
medium; Label (small text, bottom nav) 24px minimum regular. All meeting
WCAG AA contrast against `darkBg`/`primaryTeal`.

**Posture icons** — copy `icon-solat/qiyam.png`, `ruku.png`, `sujud.png`,
`duduk.png` into `nasyn_app/assets/images/poses/`. Mapping (`PrayerState`
→ icon file):

| PrayerState | Icon |
|---|---|
| `takbiratulIhram`, `qiyam`, `salam` | `qiyam.png` (standing) |
| `rukuk` | `ruku.png` |
| `sujud1`, `sujud2` | `sujud.png` |
| `dudukAntaraSujud`, `dudukTahiyatAwal`, `dudukTahiyatAkhir` | `duduk.png` |
| `selesai` | (no icon — Summary screen shown instead) |

**Logo** — copy `logo-NASYN.png` into `nasyn_app/assets/images/`.

## 2. Home Screen

Rebuilds `lib/ui/home_screen.dart` to match the wireframe exactly:

- **Mode toggle** (top): `[GUIDED MODE]` pill, `accentGreen`, selected/active. `[VISION MODE]` pill, `accentBlue`, visually greyed/dimmed with a small "Coming Soon" label, `onTap` does nothing (disabled) — Vision Mode doesn't exist until Fasa 3.
- **Assistance spectrum**: a 3-zone segmented control in one bar ("Takbir Only" | middle (unlabeled tap zone, visually the gradient midpoint) | "Full Recite"), tap-based (not draggable) — replaces Fasa 1's `RadioListTile` trio with the same underlying `AssistanceLevel` selection, just restyled.
- **Solat grid**: 2-column grid, dark teal (`primaryTeal`) buttons, `displayName` + rakaat count shown (e.g. "ZUHUR / (4 rakaat)"), matching the wireframe's SUBUH/ZUHUR/ASAR/MAGHRIB/ISYA/SUNAT 2×3 layout — reuses existing `prayerConfigs` from Fasa 1, no data model change.
- **Bottom nav**: 🌐 BM/EN (functional — see §5), 🏠 HOME (no-op here, already Home), ⚙ SETTING (opens a stub screen, see §4).

## 3. Prayer Session Screen

Rebuilds `lib/ui/prayer_session_screen.dart`:

- Solat name bar at top (e.g. "ZUHUR"), full-width, bordered.
- **Rakaat pill row** `[1][2][3][4]` (count matches `config.rakaatCount` — 2, 3, or 4 pills depending on prayer type): current rakaat pill `primaryTeal` (dark), others lighter teal. Replaces the plain "Rakaat X / Y" text from Fasa 1.
- **Guide Walkthrough Controls** ⏪⏸⏩ — same `GuidedModeController.back()/pause()-resume()/next()` wiring from Fasa 1 (Task 5), restyled with real icons matching the wireframe (⏪ and ⏩ as double-chevron icons, ⏸/▶ toggling based on `controller.isPaused`, already implemented logic unchanged).
- **Posture silhouette + labels**: icon from §1's mapping, state name in BM (large, bold, `AppTextStyles.display`), Arabic label beneath (reuses Fasa 1's `prayerStateLabelsBm`/`prayerStateLabelsArabic` maps, just restyled).
- **Collapsed recitation panel**: "show recitation" tap target, expands to show the Arabic recitation text for the current state. New file `lib/prayer/prayer_recitation_text.dart` — a `Map<PrayerState, String>` of Arabic text, sourced from `NASYN-v-Claude-assets/assets/audio/teks-rujukan-rukun.txt` (already contains the exact Arabic per rukun). Collapsed by default per PRD §10 ("bukan primary display semasa solat — elak information overload").
- Bottom nav — same as Home.
- Completion → Summary navigation: unchanged from Fasa 1 (the `_hasNavigated` one-shot guard fix already in place), just restyled destination.

## 4. Boot & Session Summary Screens

**Boot** (`lib/ui/boot_screen.dart`, new): NASYN logo centered, tagline
"Every Prayer Matters", `darkBg` background, `Timer` auto-navigates to
Home after 4 seconds (midpoint of PRD's 3–5s range) via
`Navigator.pushReplacement` — no tap required. Becomes the new
`home:` widget in `main.dart` (replacing direct `HomeScreen`).

**Session Summary** (`lib/ui/session_summary_screen.dart`, restyled):
"Rakaat ✔" and "Tuma'ninah ✔" (both simple confirmation checkmarks —
Fasa 1's Guided Mode has no failure-detection concept to report a real
count against, unlike Vision Mode's future error tracking). PRD's third
line ("Kesalahan (jumlah)") is omitted here rather than showing a
fabricated "0 kesalahan", since displaying a count implies detection
capability that doesn't exist yet — revisit when Vision Mode (Fasa 3)
adds real error tracking. "Selesai" button returns Home (unchanged
navigation from Fasa 1).

## 5. Bottom Nav Functionality

- **🏠 HOME**: navigates to Home (`pushAndRemoveUntil`, matching Fasa 1's existing Summary→Home behavior).
- **🌐 BM/EN**: a lightweight in-memory locale toggle — `enum AppLocale { bm, en }` behind a Riverpod `StateProvider<AppLocale>`, and an `AppStrings` class holding a `Map<AppLocale, Map<String, String>>` for the ~30 UI strings in scope (Home/Session/Summary labels, button text — prayer names and posture labels get BM+EN entries too). No `flutter_localizations`/`intl` package — that's overkill for this string count and would add a dependency for something a plain map handles.
- **⚙ SETTING**: a stub screen (`lib/ui/settings_screen.dart`, new) showing "Tetapan akan datang" (BM) / "Settings coming soon" (EN) and a back button — real settings (timing profile, alert mode, calibration) wait for their respective persistence/Vision-Mode work in later phases.

## Testing

Per Fasa 1's precedent (minimum/throwaway UI got no widget tests, but
this is now the *real* UI, not throwaway) — this warrants light widget
test coverage: one test per screen confirming it renders its key
elements (Home shows the solat grid and mode toggle; Prayer Session
shows the rakaat pills and posture icon; Summary shows the completion
state; Boot auto-navigates after its timer). Not exhaustive golden-image
testing — that's disproportionate for this phase — but enough to catch
a screen failing to build at all.

## Out of Scope (explicitly)

- Pre-Check screen, Pause/Handover screen (Vision Mode only, Fasa 3)
- Error/Alert Overlay (depends on pose-mismatch detection)
- Light mode (dark mode only for now)
- Kiosk lockdown / Device Owner mode (separate sub-project, next)
- Calibration, timing-profile persistence, real Settings screen content
- Vision Mode itself (the toggle is visually present but disabled)
- Draggable slider interaction for the assistance spectrum (tap-based segmented control instead, per Bos's decision — safer for elderly users)
