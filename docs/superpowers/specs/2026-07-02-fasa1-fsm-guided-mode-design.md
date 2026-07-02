# Fasa 1: FSM + Guided Mode Core — Design

**Tarikh:** 2026-07-02
**Sumber:** PRD-NASYN-v3-0-Kiosk-Edition.md §6 (Mode B: Guided Prayer), §7 (Assistance
Levels), §8.5–8.7 (FSM, Prayer Logic, Guide Walkthrough Controls), §8.11 (Audio
Engine), §12 (Fasa Pembangunan)
**Bergantung pada:** SPIKE-RESULT.md (2026-07-02) — Bos memutuskan teruskan ke Fasa
1 walaupun protokol spike Vision Mode belum lengkap dan SUJUD masih isu terbuka;
Fasa 1 tidak bergantung pada Vision Mode/pose classification, jadi selamat
diteruskan selari.

## Tujuan

Bina teras Guided Mode (timing-based, tiada kamera) yang boleh dipercayai:
Prayer State Engine (FSM) yang betul untuk semua jenis solat (termasuk
tahiyat/rakaat logic yang CTO-AUDIT lama pernah temui bug), timing-based
auto-advance ikut tuma'ninah, audio engine yang wire ke manifest asset sedia
ada, dan Guide Walkthrough Controls (⏪⏸⏩). UI hanya fungsian (tiada
reka bentuk visual) — reka bentuk sebenar (wireframe PRD §10) adalah Fasa 2.

Bukan skop Fasa 1: Vision Mode/pose detection (Fasa 3), kiosk lockdown
(Fasa 2), reka bentuk visual/wireframe sebenar (Fasa 2), persistence/SQLite
untuk timing profile atau settings (guna default PRD §8.5 buat masa ini),
Manual Override hand-icon (khusus Vision Mode), Error Detection & Alert
Modes §8.8 (konsep itu bergantung pada pose-mismatch detection — tiada
makna dalam Guided Mode murni yang deterministic).

## Tech Stack

Flutter (Dart), Riverpod (state management, ikut PRD §8.2), `audioplayers`
package (pemainan MP3 + completion stream — dipilih berbanding `just_audio`
sebab kita hanya perlu main-satu-fail-dan-tahu-bila-habis, bukan gapless
streaming). `fake_async` (dev dependency, untuk test timer-driven logic).

## 1. Data Model — Prayer Configuration

```dart
enum PrayerType { subuh, zuhur, asar, maghrib, isyak, sunat }

class PrayerConfig {
  final PrayerType type;
  final String displayName;
  final int rakaatCount;
  final int? tahiyatAwalAfterRakaat; // null = tiada tahiyat awal
  final bool qunutEligible;          // Subuh sahaja; default OFF (khilaf mazhab)

  const PrayerConfig({
    required this.type,
    required this.displayName,
    required this.rakaatCount,
    required this.tahiyatAwalAfterRakaat,
    required this.qunutEligible,
  });
}

const prayerConfigs = <PrayerType, PrayerConfig>{
  PrayerType.subuh: PrayerConfig(
    type: PrayerType.subuh, displayName: 'Subuh', rakaatCount: 2,
    tahiyatAwalAfterRakaat: null, qunutEligible: true),
  PrayerType.maghrib: PrayerConfig(
    type: PrayerType.maghrib, displayName: 'Maghrib', rakaatCount: 3,
    tahiyatAwalAfterRakaat: 2, qunutEligible: false),
  PrayerType.zuhur: PrayerConfig(
    type: PrayerType.zuhur, displayName: 'Zuhur', rakaatCount: 4,
    tahiyatAwalAfterRakaat: 2, qunutEligible: false),
  PrayerType.asar: PrayerConfig(
    type: PrayerType.asar, displayName: 'Asar', rakaatCount: 4,
    tahiyatAwalAfterRakaat: 2, qunutEligible: false),
  PrayerType.isyak: PrayerConfig(
    type: PrayerType.isyak, displayName: 'Isyak', rakaatCount: 4,
    tahiyatAwalAfterRakaat: 2, qunutEligible: false),
  PrayerType.sunat: PrayerConfig(
    type: PrayerType.sunat, displayName: 'Sunat', rakaatCount: 2,
    tahiyatAwalAfterRakaat: null, qunutEligible: false),
};
```

One config table drives the FSM for all 6 prayer types — no per-solat
branching scattered through logic code.

## 2. FSM — Prayer State Engine

Pure Dart (`lib/prayer/`), zero Flutter/audio/timer imports — same
testable-in-isolation pattern as the pose spike's `PoseClassifier`.

```dart
enum PrayerState {
  takbiratulIhram, qiyam, rukuk, iktidal, sujud1, dudukAntaraSujud, sujud2,
  dudukTahiyatAwal, dudukTahiyatAkhir, salam, selesai,
}

class PrayerStateEngine {
  final PrayerConfig config;
  PrayerState currentState;
  int currentRakaat; // 1-based

  PrayerStateEngine(this.config)
      : currentState = PrayerState.takbiratulIhram, currentRakaat = 1;

  /// Computes and applies the next state deterministically from [config].
  /// No pose input in Guided Mode — the sequence is fully determined by
  /// prayer type + current rakaat. (Vision Mode in Fasa 3 will validate a
  /// detected pose against this same table, not replace it.)
  void advance() { /* full transition table, see plan */ }

  /// Steps back one state for the ⏪ Back walkthrough control. Decrements
  /// currentRakaat if stepping backward crosses a QIYAM boundary.
  void previous() { /* see plan */ }

  bool get isComplete => currentState == PrayerState.selesai;
}
```

**Transition table (core logic, must match PRD §8.6 exactly):**

- `takbiratulIhram → qiyam` (rakaat 1 only, once per session)
- `qiyam → rukuk → iktidal → sujud1 → dudukAntaraSujud → sujud2`
- From `sujud2`:
  - if `currentRakaat == config.tahiyatAwalAfterRakaat` → `dudukTahiyatAwal`, then next `advance()` → `qiyam` (rakaat incremented, no `takbiratulIhram` repeat)
  - else if `currentRakaat == config.rakaatCount` → `dudukTahiyatAkhir` → `salam` → `selesai`
  - else → `qiyam` (rakaat incremented)

This is exactly the BUG #1 scenario CTO-AUDIT flagged in the old codebase:
Tahiyat Awal must trigger when `currentRakaat == tahiyatAwalAfterRakaat`
(i.e. after rakaat **2** lands for Maghrib/Zuhur/Asar/Isyak), never after
rakaat 1. Since this is fresh code, the test suite (section 6) asserts this
explicitly for every multi-rakaat prayer type rather than assuming it.

## 3. Guided Mode Controller

`lib/guided/guided_mode_controller.dart` — a `ChangeNotifier` (exposed via
Riverpod `ChangeNotifierProvider`) that owns a `PrayerStateEngine`, a
`Timer`, and an `AudioService`. Decides *when* `advance()` fires; the FSM
only decides *what* the next state is.

| State type | Advance trigger |
|---|---|
| Fixed-posture (`rukuk`, `iktidal`, `sujud1`, `sujud2`, `dudukAntaraSujud`) | `max(tuma'ninah minimum, Full-Recite audio duration if playing)` elapsed → auto `advance()` |
| Variable-reading (`qiyam`, `dudukTahiyatAwal`, `dudukTahiyatAkhir`) | Full Recite: audio-completion event auto-advances. Takbir Only / Panduan Posisi: waits for manual ⏩ Next (reading pace varies too much for a timer) |

Tuma'ninah defaults (PRD §8.5, no persistence in Fasa 1): Rukuk 3s,
Iktidal 2s, Sujud 3s, Duduk antara sujud 2s.

**Guide Walkthrough Controls (§8.7, Guided Mode column only):**
- ⏸ **Pause**: cancels the active `Timer`/stops audio without advancing; resumes from the same state on un-pause.
- ⏪ **Back**: calls `engine.previous()`, restarts that state's timer/audio.
- ⏩ **Next**: always force-advances via `engine.advance()` regardless of assistance level (this is how a muallaf/learner overrides the reading-phase wait, and how anyone skips ahead intentionally).

## 4. Audio Engine

`lib/audio/audio_service.dart` wraps `audioplayers`:

```dart
class AudioService {
  Future<void> play(String assetPath);
  Future<void> stop();
  Stream<void> get onComplete;
}
```

`lib/audio/audio_cue_resolver.dart` — pure function, separate from playback
mechanism:

```dart
enum AssistanceLevel { takbirOnly, panduanPosisi, fullRecite }

class AudioCueResolver {
  /// Returns the asset path to play for this state at this level, or null
  /// if no audio should play (e.g. Takbir Only during a posture with no
  /// PRD-defined minimal cue).
  String? resolve(PrayerState state, AssistanceLevel level, PrayerConfig config);
}
```

Mapping per PRD §7: Takbir Only → minimal/transition cue only (and
`NasynAudio.takbiratulIhram` at session start); Panduan Posisi →
`NasynAudio` `posisi/` files; Full Recite → `NasynAudio` `rukun/` bacaan
files, plus a Quran surah pendek during `qiyam` (reuses the existing
`NasynAudio.surahPendek` list — Fasa 1 can hardcode Al-Fatihah always,
surah pendek selection/rotation is a later refinement, not blocking).

Uses `NasynAudio.isPendingRecording()` to skip/log a warning instead of
crashing if a cue resolves to one of the 3 not-yet-recorded files
(`doaIftitah`, `bismillah`, `handoverNotis`).

## 5. Minimum UI (functional only, no visual design)

Three screens, plain Material widgets, no styling per PRD §10/§11 (that's
Fasa 2):

- **Home** (`lib/ui/home_screen.dart`): buttons/dropdown for `PrayerType`, radio buttons for `AssistanceLevel`, "Mula" button → Prayer Session.
- **Prayer Session** (`lib/ui/prayer_session_screen.dart`): plain text of current `PrayerState` name (+ a simple BM/Arabic label lookup, no styling), `"Rakaat $n / $total"` text, three buttons ⏪⏸⏩.
- **Session Summary** (`lib/ui/session_summary_screen.dart`): plain text — rakaat completed, total elapsed time, "Selesai" button → Home.

State management: `ChangeNotifierProvider` wrapping `GuidedModeController`
(Riverpod, per PRD's chosen stack — adopting it now avoids a rewrite when
Fasa 2's real UI arrives).

## 6. Testing Plan

- **`PrayerStateEngine`** (heaviest coverage): pure Dart, `dart test`, no
  Flutter/audio deps. Explicit table-driven tests for every `PrayerType`:
  correct full state sequence, Tahiyat Awal firing exactly at
  `tahiyatAwalAfterRakaat` (not rakaat 1 — the BUG #1 scenario), Subuh/Sunat
  never entering `dudukTahiyatAwal`, rakaat incrementing only at
  `sujud2 → qiyam`, `previous()` correctly reversing (including rakaat
  decrement across a `qiyam` boundary).
- **`AudioCueResolver`**: pure function, table-driven unit tests (state ×
  level × config → expected path or null), including the
  `isPendingRecording` skip behavior.
- **`GuidedModeController`**: 2-3 targeted tests using `fake_async` to
  verify auto-advance timing for one fixed-posture state and one
  Full-Recite-audio-completion case, plus Pause/Back/Next control
  behavior. Not chasing full coverage on timer-driven code — full
  experience validated by on-device manual check (Fasa 0's Task 7
  smoke-test pattern), not automated.
- No instrumented/widget tests for the minimum UI — throwaway, rebuilt in
  Fasa 2.

## Addendum (found while writing the implementation plan)

**`takbiratulIhram` and `salam` timing (gap in section 3's table):** these
are brief transitional utterances, not fixed-posture tuma'ninah states or
variable-length recitation. Rule: auto-advance when their audio cue
finishes playing (any assistance level — even Takbir Only plays the
opening takbir per PRD §7); if no cue is defined for a level, fall back to
a short fixed 2s timer instead of waiting on manual Next.

**`AudioService` is an interface, not a concrete class:** `audioplayers`
uses platform channels, which don't run under plain `dart test`/`flutter
test` without real platform bindings. So `AudioService` is an abstract
class (`play`, `stop`, `onComplete` stream) with `AudioPlayerService`
(real `audioplayers`-backed) as the production implementation, and a
`FakeAudioService` test double (in-memory, manually-triggered `onComplete`
stream) for `GuidedModeController` unit tests. `NasynAudio` paths are
declared with the `assets/` prefix (matching pubspec style); `audioplayers`'
`AssetSource` expects that prefix stripped, so `AudioPlayerService.play()`
normalizes the path before use.

## Known Follow-Up Required Before Fasa 2 (Kiosk)

**Audio-completion watchdog.** Several `GuidedModeController` states (the
takbir transition cue, Full-Recite variable-reading states, Salam with a
cue) advance only on `AudioService.onComplete` firing, with no timeout. If
an audio asset ever fails to load/play, the session silently stalls in
that state. In Fasa 1 this is recoverable — the ⏪⏸⏩ walkthrough
controls are always visible and a human is present. It becomes a real
problem in Fasa 2's unattended kiosk mode, where no one is there to tap
Next. Add a watchdog timeout (advance after `onComplete` OR N seconds,
whichever comes first) for every `onComplete`-gated transition, and/or
surface playback errors via an `AudioService.onError` stream, before
kiosk work begins. Found during the final Fasa 1 whole-branch review
(2026-07-02); Bos approved merging Fasa 1 without fixing it now.

## Out of Scope (explicitly)

- Vision Mode / pose detection / camera (Fasa 3)
- Kiosk lockdown, Device Owner mode (Fasa 2)
- Visual design / wireframe styling (Fasa 2, PRD §10-§11)
- SQLite persistence for timing profile, settings, or logs (§8.12) — Fasa 1 uses PRD §8.5 defaults only
- Manual Override hand-icon (Vision Mode safety net, not applicable without a camera)
- Error Detection & Alert Modes (§8.8) — depends on pose-mismatch detection, meaningless in a deterministic Guided Mode
- Recording the 3 still-missing audio files (`doaIftitah`, `bismillah`, `handoverNotis`) — `isPendingRecording()` skip logic handles their absence gracefully
