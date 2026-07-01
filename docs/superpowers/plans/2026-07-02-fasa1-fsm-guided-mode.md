# Fasa 1: FSM + Guided Mode Core Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Flutter app (`nasyn_app/`) with a correct Prayer State Engine
(FSM) for all 6 prayer types, a timing/audio-driven Guided Mode controller, and
a minimum (unstyled) UI to run and manually verify a full guided prayer
session end-to-end on the Redmi 9A.

**Architecture:** A pure-Dart FSM (`PrayerStateEngine`) computes the correct
next prayer state from a config table (rakaat count, tahiyat-awal timing) —
no camera/pose input, since Guided Mode is fully deterministic. A
`GuidedModeController` (ChangeNotifier) owns the FSM plus a `Timer` and an
`AudioService`, deciding *when* to advance based on state type (fixed-posture
tuma'ninah vs. variable-length reading) and assistance level. `AudioService`
is an interface so the controller is unit-testable without real platform
audio. UI is plain Material widgets, wired via Riverpod.

**Tech Stack:** Flutter/Dart, flutter_riverpod, audioplayers, fake_async (dev).

## Global Constraints

- New Flutter project at `nasyn_app/` (NOT repo root — root already holds the standalone Kotlin pose-spike Gradle project from Fasa 0)
- Android platform only (`flutter create --platforms=android`)
- Package/org: `com.nasyn`, project name `nasyn_app`
- No Flutter platform channel to native pose code, no camera, no kiosk lockdown, no SQLite persistence, no visual design/wireframe styling — all out of scope per the design spec
- Tuma'ninah defaults (PRD §8.5, hardcoded, no persistence): Rukuk 3s, Iktidal 2s, Sujud 3s, Duduk antara sujud 2s
- `NasynAudio` asset paths are declared with an `assets/` prefix; `audioplayers`'s `AssetSource` needs that prefix stripped
- Device for manual verification: Xiaomi Redmi 9A, adb serial `9HJ7OZ55XSXOPVJZ` — `adb install` is blocked by MIUI's SIM-verification requirement on this SIM-less device; use the push-to-`/sdcard/Download/` + manual Files-app sideload route established in the Fasa 0 spike

---

## Task 1: Flutter project scaffold + audio assets

**Files:**
- Create: `nasyn_app/` (via `flutter create`)
- Modify: `nasyn_app/pubspec.yaml` (add dependencies + asset paths)
- Create: `nasyn_app/assets/audio/rukun/`, `nasyn_app/assets/audio/posisi/`, `nasyn_app/assets/audio/quran/al-husary/`, `nasyn_app/assets/audio/quran/al-misyari/` (copied audio files)
- Create: `nasyn_app/lib/audio/nasyn_audio.dart` (copied from repo root, unchanged)

**Interfaces:**
- Produces: a Flutter project skeleton that builds (`flutter build apk --debug`), with `flutter_riverpod`, `audioplayers` as dependencies and `fake_async` as a dev dependency, audio assets bundled and declared in `pubspec.yaml`, and `NasynAudio` importable as `package:nasyn_app/audio/nasyn_audio.dart`.

- [ ] **Step 1: Confirm Flutter's Android toolchain is wired to the SDK from Fasa 0**

```bash
export ANDROID_HOME=~/Android/Sdk
flutter config --android-sdk ~/Android/Sdk
flutter doctor
```

Expected: no `[✗]` next to "Android toolchain" (a `[!]` about Android Studio itself, if present, is fine — we don't need Android Studio, only the SDK/build-tools already installed in Fasa 0).

- [ ] **Step 2: Create the Flutter project**

```bash
cd /home/astro/claude-project/NASYN-v-Claude
flutter create --platforms=android --org com.nasyn --project-name nasyn_app nasyn_app
```

Expected: `nasyn_app/` directory created with `pubspec.yaml`, `lib/main.dart`, `android/`, etc. `pubspec.yaml`'s `name:` field is `nasyn_app`.

- [ ] **Step 3: Add dependencies**

```bash
cd /home/astro/claude-project/NASYN-v-Claude/nasyn_app
flutter pub add flutter_riverpod audioplayers
flutter pub add dev:fake_async
```

Expected: `pubspec.yaml` gains `flutter_riverpod`, `audioplayers` under `dependencies:` and `fake_async` under `dev_dependencies:`, each with whatever current version `pub` resolves (don't hand-pin versions — let pub pick compatible ones, the way Fasa 0 let Gradle/MediaPipe resolve their own compatible versions).

- [ ] **Step 4: Copy audio assets**

```bash
cd /home/astro/claude-project/NASYN-v-Claude
mkdir -p nasyn_app/assets/audio
cp -r NASYN-v-Claude-assets/assets/audio/rukun nasyn_app/assets/audio/
cp -r NASYN-v-Claude-assets/assets/audio/posisi nasyn_app/assets/audio/
cp -r NASYN-v-Claude-assets/assets/audio/quran nasyn_app/assets/audio/
find nasyn_app/assets/audio -type f | wc -l
```

Expected: 46 files (9 rukun + 6 posisi + 31 quran), matching the counts found in `NASYN-v-Claude-assets/assets/audio/`.

- [ ] **Step 5: Register assets in `pubspec.yaml`**

Open `nasyn_app/pubspec.yaml`, find the `flutter:` section (it already has `uses-material-design: true` from `flutter create`), and add an `assets:` list beneath it:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/audio/rukun/
    - assets/audio/posisi/
    - assets/audio/quran/al-husary/
    - assets/audio/quran/al-misyari/
```

- [ ] **Step 6: Copy `nasyn_audio.dart` into the project**

```bash
mkdir -p nasyn_app/lib/audio
cp nasyn_audio.dart nasyn_app/lib/audio/nasyn_audio.dart
```

No changes needed to the file's content — it's dependency-free (just string constants and two small helper members).

- [ ] **Step 7: Verify the scaffold builds**

```bash
cd /home/astro/claude-project/NASYN-v-Claude/nasyn_app
flutter analyze
flutter build apk --debug
```

Expected: `flutter analyze` reports no errors (the default `flutter create` counter-app template is untouched and analyzer-clean); `flutter build apk --debug` ends with `Built build/app/outputs/flutter-apk/app-debug.apk`.

- [ ] **Step 8: Commit**

```bash
cd /home/astro/claude-project/NASYN-v-Claude
git add nasyn_app
git commit -m "Scaffold nasyn_app Flutter project with audio assets and dependencies"
```

---

## Task 2: `PrayerStateEngine` — the FSM

**Files:**
- Create: `nasyn_app/lib/prayer/prayer_state.dart`
- Create: `nasyn_app/lib/prayer/prayer_config.dart`
- Create: `nasyn_app/lib/prayer/prayer_state_engine.dart`
- Test: `nasyn_app/test/prayer/prayer_state_engine_test.dart`

**Interfaces:**
- Consumes: nothing from other tasks (foundational, pure-Dart layer).
- Produces:
  - `enum PrayerState { takbiratulIhram, qiyam, rukuk, iktidal, sujud1, dudukAntaraSujud, sujud2, dudukTahiyatAwal, dudukTahiyatAkhir, salam, selesai }`
  - `enum PrayerType { subuh, zuhur, asar, maghrib, isyak, sunat }`
  - `class PrayerConfig { final PrayerType type; final String displayName; final int rakaatCount; final int? tahiyatAwalAfterRakaat; final bool qunutEligible; }`
  - `const Map<PrayerType, PrayerConfig> prayerConfigs`
  - `class PrayerStateEngine { PrayerStateEngine(PrayerConfig config); PrayerState currentState; int currentRakaat; final PrayerConfig config; void advance(); void previous(); bool get isComplete; }`

- [ ] **Step 1: Write `prayer_state.dart`**

```dart
enum PrayerState {
  takbiratulIhram,
  qiyam,
  rukuk,
  iktidal,
  sujud1,
  dudukAntaraSujud,
  sujud2,
  dudukTahiyatAwal,
  dudukTahiyatAkhir,
  salam,
  selesai,
}
```

- [ ] **Step 2: Write `prayer_config.dart`**

```dart
enum PrayerType { subuh, zuhur, asar, maghrib, isyak, sunat }

class PrayerConfig {
  final PrayerType type;
  final String displayName;
  final int rakaatCount;
  final int? tahiyatAwalAfterRakaat; // null = no tahiyat awal (Subuh/Sunat)
  final bool qunutEligible; // Subuh only; default OFF (khilaf mazhab)

  const PrayerConfig({
    required this.type,
    required this.displayName,
    required this.rakaatCount,
    required this.tahiyatAwalAfterRakaat,
    required this.qunutEligible,
  });
}

const Map<PrayerType, PrayerConfig> prayerConfigs = {
  PrayerType.subuh: PrayerConfig(
    type: PrayerType.subuh,
    displayName: 'Subuh',
    rakaatCount: 2,
    tahiyatAwalAfterRakaat: null,
    qunutEligible: true,
  ),
  PrayerType.maghrib: PrayerConfig(
    type: PrayerType.maghrib,
    displayName: 'Maghrib',
    rakaatCount: 3,
    tahiyatAwalAfterRakaat: 2,
    qunutEligible: false,
  ),
  PrayerType.zuhur: PrayerConfig(
    type: PrayerType.zuhur,
    displayName: 'Zuhur',
    rakaatCount: 4,
    tahiyatAwalAfterRakaat: 2,
    qunutEligible: false,
  ),
  PrayerType.asar: PrayerConfig(
    type: PrayerType.asar,
    displayName: 'Asar',
    rakaatCount: 4,
    tahiyatAwalAfterRakaat: 2,
    qunutEligible: false,
  ),
  PrayerType.isyak: PrayerConfig(
    type: PrayerType.isyak,
    displayName: 'Isyak',
    rakaatCount: 4,
    tahiyatAwalAfterRakaat: 2,
    qunutEligible: false,
  ),
  PrayerType.sunat: PrayerConfig(
    type: PrayerType.sunat,
    displayName: 'Sunat',
    rakaatCount: 2,
    tahiyatAwalAfterRakaat: null,
    qunutEligible: false,
  ),
};
```

- [ ] **Step 3: Write the failing test — `prayer_state_engine_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nasyn_app/prayer/prayer_config.dart';
import 'package:nasyn_app/prayer/prayer_state.dart';
import 'package:nasyn_app/prayer/prayer_state_engine.dart';

void main() {
  group('PrayerStateEngine - Zuhur (4 rakaat, tahiyat awal after 2)', () {
    test('walks the full expected state sequence', () {
      final engine = PrayerStateEngine(prayerConfigs[PrayerType.zuhur]!);

      final expected = <(PrayerState, int)>[
        (PrayerState.qiyam, 1),
        (PrayerState.rukuk, 1),
        (PrayerState.iktidal, 1),
        (PrayerState.sujud1, 1),
        (PrayerState.dudukAntaraSujud, 1),
        (PrayerState.sujud2, 1),
        (PrayerState.qiyam, 2),
        (PrayerState.rukuk, 2),
        (PrayerState.iktidal, 2),
        (PrayerState.sujud1, 2),
        (PrayerState.dudukAntaraSujud, 2),
        (PrayerState.sujud2, 2),
        (PrayerState.dudukTahiyatAwal, 2),
        (PrayerState.qiyam, 3),
        (PrayerState.rukuk, 3),
        (PrayerState.iktidal, 3),
        (PrayerState.sujud1, 3),
        (PrayerState.dudukAntaraSujud, 3),
        (PrayerState.sujud2, 3),
        (PrayerState.qiyam, 4),
        (PrayerState.rukuk, 4),
        (PrayerState.iktidal, 4),
        (PrayerState.sujud1, 4),
        (PrayerState.dudukAntaraSujud, 4),
        (PrayerState.sujud2, 4),
        (PrayerState.dudukTahiyatAkhir, 4),
        (PrayerState.salam, 4),
        (PrayerState.selesai, 4),
      ];

      expect(engine.currentState, PrayerState.takbiratulIhram);
      expect(engine.currentRakaat, 1);

      for (final (expectedState, expectedRakaat) in expected) {
        engine.advance();
        expect(engine.currentState, expectedState);
        expect(engine.currentRakaat, expectedRakaat);
      }
      expect(engine.isComplete, isTrue);
    });

    test('previous() reverses the full sequence back to the start', () {
      final engine = PrayerStateEngine(prayerConfigs[PrayerType.zuhur]!);
      const totalTransitions = 28;

      for (var i = 0; i < totalTransitions; i++) {
        engine.advance();
      }
      expect(engine.isComplete, isTrue);

      for (var i = 0; i < totalTransitions; i++) {
        engine.previous();
      }

      expect(engine.currentState, PrayerState.takbiratulIhram);
      expect(engine.currentRakaat, 1);
    });
  });

  group('PrayerStateEngine - Subuh (2 rakaat, no tahiyat awal)', () {
    test('never enters dudukTahiyatAwal', () {
      final engine = PrayerStateEngine(prayerConfigs[PrayerType.subuh]!);
      final visitedStates = <PrayerState>[];

      while (!engine.isComplete) {
        engine.advance();
        visitedStates.add(engine.currentState);
      }

      expect(visitedStates, isNot(contains(PrayerState.dudukTahiyatAwal)));
      expect(visitedStates.last, PrayerState.selesai);
      expect(engine.currentRakaat, 2);
    });
  });

  group('PrayerStateEngine - Maghrib (3 rakaat, tahiyat awal after 2)', () {
    test('fires tahiyat awal after rakaat 2 and tahiyat akhir after rakaat 3', () {
      final engine = PrayerStateEngine(prayerConfigs[PrayerType.maghrib]!);

      var sawTahiyatAwal = false;
      while (!engine.isComplete) {
        engine.advance();
        if (engine.currentState == PrayerState.dudukTahiyatAwal) {
          sawTahiyatAwal = true;
          expect(
            engine.currentRakaat,
            2,
            reason: 'BUG #1: tahiyat awal must fire after rakaat 2, not rakaat 1',
          );
        }
        if (engine.currentState == PrayerState.dudukTahiyatAkhir) {
          expect(engine.currentRakaat, 3);
        }
      }

      expect(sawTahiyatAwal, isTrue);
      expect(engine.currentRakaat, 3);
    });
  });
}
```

- [ ] **Step 4: Run test to verify it fails**

```bash
cd /home/astro/claude-project/NASYN-v-Claude/nasyn_app
flutter test test/prayer/prayer_state_engine_test.dart
```

Expected: FAIL — `PrayerStateEngine` is an unresolved reference (file doesn't exist yet).

- [ ] **Step 5: Write `prayer_state_engine.dart`**

```dart
import 'prayer_config.dart';
import 'prayer_state.dart';

class PrayerStateEngine {
  final PrayerConfig config;
  PrayerState currentState;
  int currentRakaat;

  PrayerStateEngine(this.config)
      : currentState = PrayerState.takbiratulIhram,
        currentRakaat = 1;

  static const List<PrayerState> _postureSequence = [
    PrayerState.qiyam,
    PrayerState.rukuk,
    PrayerState.iktidal,
    PrayerState.sujud1,
    PrayerState.dudukAntaraSujud,
    PrayerState.sujud2,
  ];

  bool get isComplete => currentState == PrayerState.selesai;

  /// Computes and applies the next state. No pose input — Guided Mode's
  /// sequence is fully determined by prayer type + current rakaat.
  void advance() {
    switch (currentState) {
      case PrayerState.takbiratulIhram:
        currentState = PrayerState.qiyam;
        return;
      case PrayerState.qiyam:
      case PrayerState.rukuk:
      case PrayerState.iktidal:
      case PrayerState.sujud1:
      case PrayerState.dudukAntaraSujud:
        currentState =
            _postureSequence[_postureSequence.indexOf(currentState) + 1];
        return;
      case PrayerState.sujud2:
        _advanceFromSujud2();
        return;
      case PrayerState.dudukTahiyatAwal:
        currentRakaat += 1;
        currentState = PrayerState.qiyam;
        return;
      case PrayerState.dudukTahiyatAkhir:
        currentState = PrayerState.salam;
        return;
      case PrayerState.salam:
        currentState = PrayerState.selesai;
        return;
      case PrayerState.selesai:
        return;
    }
  }

  void _advanceFromSujud2() {
    if (currentRakaat == config.tahiyatAwalAfterRakaat) {
      currentState = PrayerState.dudukTahiyatAwal;
    } else if (currentRakaat == config.rakaatCount) {
      currentState = PrayerState.dudukTahiyatAkhir;
    } else {
      currentRakaat += 1;
      currentState = PrayerState.qiyam;
    }
  }

  /// Steps back one state, for the guide walkthrough's Back control.
  void previous() {
    switch (currentState) {
      case PrayerState.takbiratulIhram:
        return;
      case PrayerState.qiyam:
        if (currentRakaat == 1) {
          currentState = PrayerState.takbiratulIhram;
        } else if (currentRakaat - 1 == config.tahiyatAwalAfterRakaat) {
          currentRakaat -= 1;
          currentState = PrayerState.dudukTahiyatAwal;
        } else {
          currentRakaat -= 1;
          currentState = PrayerState.sujud2;
        }
        return;
      case PrayerState.rukuk:
        currentState = PrayerState.qiyam;
        return;
      case PrayerState.iktidal:
        currentState = PrayerState.rukuk;
        return;
      case PrayerState.sujud1:
        currentState = PrayerState.iktidal;
        return;
      case PrayerState.dudukAntaraSujud:
        currentState = PrayerState.sujud1;
        return;
      case PrayerState.sujud2:
        currentState = PrayerState.dudukAntaraSujud;
        return;
      case PrayerState.dudukTahiyatAwal:
        currentState = PrayerState.sujud2;
        return;
      case PrayerState.dudukTahiyatAkhir:
        currentState = PrayerState.sujud2;
        return;
      case PrayerState.salam:
        currentState = PrayerState.dudukTahiyatAkhir;
        return;
      case PrayerState.selesai:
        currentState = PrayerState.salam;
        return;
    }
  }
}
```

- [ ] **Step 6: Run test to verify it passes**

```bash
flutter test test/prayer/prayer_state_engine_test.dart
```

Expected: `00:0X +4: All tests passed!` (4 tests: Zuhur sequence, Zuhur round-trip, Subuh no-tahiyat-awal, Maghrib tahiyat timing).

- [ ] **Step 7: Commit**

```bash
cd /home/astro/claude-project/NASYN-v-Claude
git add nasyn_app/lib/prayer nasyn_app/test/prayer
git commit -m "Add PrayerStateEngine FSM with full transition-table test coverage"
```

---

## Task 3: Audio layer — `AudioService`, `AudioPlayerService`, `AudioCueResolver`

**Files:**
- Create: `nasyn_app/lib/audio/audio_service.dart`
- Create: `nasyn_app/lib/audio/audio_player_service.dart`
- Create: `nasyn_app/lib/audio/audio_cue_resolver.dart`
- Test: `nasyn_app/test/audio/audio_cue_resolver_test.dart`
- Test support: `nasyn_app/test/support/fake_audio_service.dart` (used by this task's tests and Task 4's)

**Interfaces:**
- Consumes: `PrayerState` (Task 2), `PrayerConfig` (Task 2), `NasynAudio` (Task 1).
- Produces:
  - `abstract class AudioService { Future<void> play(String assetPath); Future<void> stop(); Stream<void> get onComplete; }`
  - `class AudioPlayerService implements AudioService` (real `audioplayers`-backed)
  - `enum AssistanceLevel { takbirOnly, panduanPosisi, fullRecite }`
  - `class AudioCueResolver { String? resolve(PrayerState state, AssistanceLevel level, PrayerConfig config); }`
  - `class FakeAudioService implements AudioService` (test double, in `test/support/`) with `void completeCurrent()` to manually fire `onComplete`.

- [ ] **Step 1: Write `audio_service.dart`**

```dart
abstract class AudioService {
  Future<void> play(String assetPath);
  Future<void> stop();
  Stream<void> get onComplete;
}
```

- [ ] **Step 2: Write `audio_player_service.dart`**

```dart
import 'package:audioplayers/audioplayers.dart';

import 'audio_service.dart';

class AudioPlayerService implements AudioService {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> play(String assetPath) async {
    // NasynAudio paths are declared with an 'assets/' prefix (pubspec
    // style); audioplayers' AssetSource expects that prefix stripped.
    final normalized = assetPath.startsWith('assets/')
        ? assetPath.substring('assets/'.length)
        : assetPath;
    await _player.stop();
    await _player.play(AssetSource(normalized));
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Stream<void> get onComplete => _player.onPlayerComplete;

  void dispose() => _player.dispose();
}
```

- [ ] **Step 3: Write the failing test for `AudioCueResolver` — `audio_cue_resolver_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nasyn_app/audio/audio_cue_resolver.dart';
import 'package:nasyn_app/audio/nasyn_audio.dart';
import 'package:nasyn_app/prayer/prayer_config.dart';
import 'package:nasyn_app/prayer/prayer_state.dart';

void main() {
  final resolver = AudioCueResolver();
  final zuhurConfig = prayerConfigs[PrayerType.zuhur]!;

  group('Takbir Only', () {
    test('only plays audio for takbiratulIhram, nothing else', () {
      expect(
        resolver.resolve(
            PrayerState.takbiratulIhram, AssistanceLevel.takbirOnly, zuhurConfig),
        NasynAudio.takbiratulIhram,
      );
      expect(
        resolver.resolve(PrayerState.rukuk, AssistanceLevel.takbirOnly, zuhurConfig),
        isNull,
      );
      expect(
        resolver.resolve(PrayerState.qiyam, AssistanceLevel.takbirOnly, zuhurConfig),
        isNull,
      );
    });
  });

  group('Panduan Posisi', () {
    test('plays position-name cues', () {
      expect(
        resolver.resolve(
            PrayerState.rukuk, AssistanceLevel.panduanPosisi, zuhurConfig),
        NasynAudio.posisiRukuk,
      );
      expect(
        resolver.resolve(
            PrayerState.sujud1, AssistanceLevel.panduanPosisi, zuhurConfig),
        NasynAudio.posisiSujud,
      );
      expect(
        resolver.resolve(
            PrayerState.sujud2, AssistanceLevel.panduanPosisi, zuhurConfig),
        NasynAudio.posisiSujudKedua,
      );
      expect(
        resolver.resolve(
            PrayerState.qiyam, AssistanceLevel.panduanPosisi, zuhurConfig),
        isNull,
      );
    });
  });

  group('Full Recite', () {
    test('plays full bacaan for every rukun', () {
      expect(
        resolver.resolve(PrayerState.qiyam, AssistanceLevel.fullRecite, zuhurConfig),
        NasynAudio.alFatihah,
      );
      expect(
        resolver.resolve(PrayerState.rukuk, AssistanceLevel.fullRecite, zuhurConfig),
        NasynAudio.bacaanRukuk,
      );
      expect(
        resolver.resolve(
            PrayerState.dudukTahiyatAwal, AssistanceLevel.fullRecite, zuhurConfig),
        NasynAudio.tahiyatAwal,
      );
      expect(
        resolver.resolve(
            PrayerState.dudukTahiyatAkhir, AssistanceLevel.fullRecite, zuhurConfig),
        NasynAudio.tahiyatAkhir,
      );
      expect(
        resolver.resolve(PrayerState.salam, AssistanceLevel.fullRecite, zuhurConfig),
        NasynAudio.salam,
      );
    });
  });

  test('never resolves to a not-yet-recorded asset for any state/level combination', () {
    for (final state in PrayerState.values) {
      for (final level in AssistanceLevel.values) {
        final path = resolver.resolve(state, level, zuhurConfig);
        if (path != null) {
          expect(
            NasynAudio.isPendingRecording(path),
            isFalse,
            reason: '$state/$level resolved to a not-yet-recorded asset: $path',
          );
        }
      }
    }
  });
}
```

- [ ] **Step 4: Run test to verify it fails**

```bash
cd /home/astro/claude-project/NASYN-v-Claude/nasyn_app
flutter test test/audio/audio_cue_resolver_test.dart
```

Expected: FAIL — `AudioCueResolver`/`AssistanceLevel` unresolved references.

- [ ] **Step 5: Write `audio_cue_resolver.dart`**

```dart
import '../prayer/prayer_config.dart';
import '../prayer/prayer_state.dart';
import 'nasyn_audio.dart';

enum AssistanceLevel { takbirOnly, panduanPosisi, fullRecite }

class AudioCueResolver {
  /// Returns the asset path to play for this state at this level, or null
  /// if nothing should play. [config] is accepted for future per-prayer
  /// cues (e.g. qunut) — unused today, since qunut audio wiring is
  /// deferred (design spec, Out of Scope).
  String? resolve(PrayerState state, AssistanceLevel level, PrayerConfig config) {
    final path = switch (level) {
      AssistanceLevel.takbirOnly => _takbirOnlyCue(state),
      AssistanceLevel.panduanPosisi => _panduanPosisiCue(state),
      AssistanceLevel.fullRecite => _fullReciteCue(state),
    };
    if (path == null) return null;
    if (NasynAudio.isPendingRecording(path)) return null;
    return path;
  }

  String? _takbirOnlyCue(PrayerState state) {
    if (state == PrayerState.takbiratulIhram) return NasynAudio.takbiratulIhram;
    return null;
  }

  String? _panduanPosisiCue(PrayerState state) {
    switch (state) {
      case PrayerState.takbiratulIhram:
        return NasynAudio.takbiratulIhram;
      case PrayerState.rukuk:
        return NasynAudio.posisiRukuk;
      case PrayerState.sujud1:
        return NasynAudio.posisiSujud;
      case PrayerState.sujud2:
        return NasynAudio.posisiSujudKedua;
      case PrayerState.dudukAntaraSujud:
        return NasynAudio.posisiDudukDuaSujud;
      case PrayerState.dudukTahiyatAwal:
        return NasynAudio.posisiTahiyatAwal;
      case PrayerState.dudukTahiyatAkhir:
        return NasynAudio.posisiTahiyatAkhir;
      default:
        return null;
    }
  }

  String? _fullReciteCue(PrayerState state) {
    switch (state) {
      case PrayerState.takbiratulIhram:
        return NasynAudio.takbiratulIhram;
      case PrayerState.qiyam:
        return NasynAudio.alFatihah;
      case PrayerState.rukuk:
        return NasynAudio.bacaanRukuk;
      case PrayerState.iktidal:
        return NasynAudio.bacaanIktidal;
      case PrayerState.sujud1:
      case PrayerState.sujud2:
        return NasynAudio.bacaanSujud;
      case PrayerState.dudukAntaraSujud:
        return NasynAudio.bacaanDudukAntaraSujud;
      case PrayerState.dudukTahiyatAwal:
        return NasynAudio.tahiyatAwal;
      case PrayerState.dudukTahiyatAkhir:
        return NasynAudio.tahiyatAkhir;
      case PrayerState.salam:
        return NasynAudio.salam;
      default:
        return null;
    }
  }
}
```

- [ ] **Step 6: Run test to verify it passes**

```bash
flutter test test/audio/audio_cue_resolver_test.dart
```

Expected: `00:0X +5: All tests passed!`

- [ ] **Step 7: Write the `FakeAudioService` test double**

```dart
import 'dart:async';

import 'package:nasyn_app/audio/audio_service.dart';

class FakeAudioService implements AudioService {
  final _completeController = StreamController<void>.broadcast();
  String? lastPlayedPath;

  @override
  Future<void> play(String assetPath) async {
    lastPlayedPath = assetPath;
  }

  @override
  Future<void> stop() async {}

  @override
  Stream<void> get onComplete => _completeController.stream;

  /// Test helper: simulates the current audio finishing playback.
  void completeCurrent() {
    _completeController.add(null);
  }

  void dispose() {
    _completeController.close();
  }
}
```

Create the file at `nasyn_app/test/support/fake_audio_service.dart`. This has no test of its own (it's a test double) — it's exercised indirectly by Task 4's `GuidedModeController` tests.

- [ ] **Step 8: Verify everything compiles and existing tests still pass**

```bash
flutter analyze
flutter test
```

Expected: no analyzer errors; all tests (Task 2 + Task 3) pass.

- [ ] **Step 9: Commit**

```bash
cd /home/astro/claude-project/NASYN-v-Claude
git add nasyn_app/lib/audio nasyn_app/test/audio nasyn_app/test/support
git commit -m "Add AudioService interface, AudioPlayerService, and AudioCueResolver"
```

---

## Task 4: `GuidedModeController` — timing + audio orchestration

**Files:**
- Create: `nasyn_app/lib/guided/guided_mode_controller.dart`
- Test: `nasyn_app/test/guided/guided_mode_controller_test.dart`

**Interfaces:**
- Consumes: `PrayerStateEngine`, `PrayerConfig`, `PrayerState`, `PrayerType`, `prayerConfigs` (Task 2); `AudioService`, `AudioCueResolver`, `AssistanceLevel` (Task 3); `FakeAudioService` (Task 3, test-only).
- Produces:
  - `class GuidedModeController extends ChangeNotifier` with constructor `GuidedModeController({required PrayerConfig config, required AssistanceLevel level, required AudioService audioService, required AudioCueResolver cueResolver})`
  - Getters: `PrayerState get currentState`, `int get currentRakaat`, `bool get isComplete`, `bool get isPaused`
  - Methods: `void pause()`, `void resume()`, `void back()`, `void next()`, `void dispose()` (override)
  - Later tasks (UI, Task 5) construct this via a Riverpod provider and call these exact members.

- [ ] **Step 1: Write the failing tests — `guided_mode_controller_test.dart`**

```dart
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasyn_app/audio/audio_cue_resolver.dart';
import 'package:nasyn_app/guided/guided_mode_controller.dart';
import 'package:nasyn_app/prayer/prayer_config.dart';
import 'package:nasyn_app/prayer/prayer_state.dart';

import '../support/fake_audio_service.dart';

void main() {
  test('Takbir Only: audio-driven takbir, manual-Next qiyam, fixed-timer rukuk', () {
    fakeAsync((async) {
      final audio = FakeAudioService();
      final controller = GuidedModeController(
        config: prayerConfigs[PrayerType.zuhur]!,
        level: AssistanceLevel.takbirOnly,
        audioService: audio,
        cueResolver: AudioCueResolver(),
      );

      // takbiratulIhram has a cue in Takbir Only -> advances on audio complete
      audio.completeCurrent();
      expect(controller.currentState, PrayerState.qiyam);

      // qiyam is variable-reading, Takbir Only has no cue -> waits for manual Next
      async.elapse(const Duration(seconds: 10));
      expect(controller.currentState, PrayerState.qiyam);
      controller.next();
      expect(controller.currentState, PrayerState.rukuk);

      // rukuk is fixed-posture, Takbir Only has no cue -> fixed 3s timer
      async.elapse(const Duration(seconds: 2, milliseconds: 900));
      expect(controller.currentState, PrayerState.rukuk);
      async.elapse(const Duration(milliseconds: 200));
      expect(controller.currentState, PrayerState.iktidal);
    });
  });

  test('Full Recite: fixed-posture state waits for max(tumaninah, audio)', () {
    fakeAsync((async) {
      final audio = FakeAudioService();
      final controller = GuidedModeController(
        config: prayerConfigs[PrayerType.zuhur]!,
        level: AssistanceLevel.fullRecite,
        audioService: audio,
        cueResolver: AudioCueResolver(),
      );

      audio.completeCurrent(); // takbiratulIhram audio finishes
      expect(controller.currentState, PrayerState.qiyam);

      audio.completeCurrent(); // Al-Fatihah finishes -> qiyam advances (Full Recite)
      expect(controller.currentState, PrayerState.rukuk);

      // rukuk: tuma'ninah 3s, audio not yet complete -> must NOT advance at 3s
      async.elapse(const Duration(seconds: 3));
      expect(controller.currentState, PrayerState.rukuk);

      // audio finishes after tuma'ninah already elapsed -> advances now
      audio.completeCurrent();
      expect(controller.currentState, PrayerState.iktidal);
    });
  });

  test('pause stops the timer; resume re-arms it', () {
    fakeAsync((async) {
      final audio = FakeAudioService();
      final controller = GuidedModeController(
        config: prayerConfigs[PrayerType.subuh]!,
        level: AssistanceLevel.takbirOnly,
        audioService: audio,
        cueResolver: AudioCueResolver(),
      );

      audio.completeCurrent(); // takbiratulIhram -> qiyam
      controller.next(); // qiyam -> rukuk (manual, Takbir Only has no qiyam cue)

      controller.pause();
      async.elapse(const Duration(seconds: 5));
      expect(controller.currentState, PrayerState.rukuk);

      controller.resume();
      async.elapse(const Duration(seconds: 3));
      expect(controller.currentState, PrayerState.iktidal);
    });
  });

  test('back() reverses state via engine.previous()', () {
    fakeAsync((async) {
      final audio = FakeAudioService();
      final controller = GuidedModeController(
        config: prayerConfigs[PrayerType.subuh]!,
        level: AssistanceLevel.takbirOnly,
        audioService: audio,
        cueResolver: AudioCueResolver(),
      );

      audio.completeCurrent();
      controller.next(); // qiyam -> rukuk
      expect(controller.currentState, PrayerState.rukuk);

      controller.back();
      expect(controller.currentState, PrayerState.qiyam);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /home/astro/claude-project/NASYN-v-Claude/nasyn_app
flutter test test/guided/guided_mode_controller_test.dart
```

Expected: FAIL — `GuidedModeController` unresolved reference.

- [ ] **Step 3: Write `guided_mode_controller.dart`**

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../audio/audio_cue_resolver.dart';
import '../audio/audio_service.dart';
import '../prayer/prayer_config.dart';
import '../prayer/prayer_state.dart';
import '../prayer/prayer_state_engine.dart';

const Map<PrayerState, Duration> tumaninahDurations = {
  PrayerState.rukuk: Duration(seconds: 3),
  PrayerState.iktidal: Duration(seconds: 2),
  PrayerState.sujud1: Duration(seconds: 3),
  PrayerState.sujud2: Duration(seconds: 3),
  PrayerState.dudukAntaraSujud: Duration(seconds: 2),
};

class GuidedModeController extends ChangeNotifier {
  final PrayerStateEngine engine;
  final AssistanceLevel level;
  final AudioService audioService;
  final AudioCueResolver cueResolver;

  static const Duration _shortTransitionDuration = Duration(seconds: 2);
  static const _shortTransitionStates = {
    PrayerState.takbiratulIhram,
    PrayerState.salam,
  };
  static const _variableReadingStates = {
    PrayerState.qiyam,
    PrayerState.dudukTahiyatAwal,
    PrayerState.dudukTahiyatAkhir,
  };

  Timer? _timer;
  StreamSubscription<void>? _audioCompleteSub;
  bool _isPaused = false;

  bool get isPaused => _isPaused;
  PrayerState get currentState => engine.currentState;
  int get currentRakaat => engine.currentRakaat;
  bool get isComplete => engine.isComplete;

  GuidedModeController({
    required PrayerConfig config,
    required this.level,
    required this.audioService,
    required this.cueResolver,
  }) : engine = PrayerStateEngine(config) {
    _enterState();
  }

  void _enterState() {
    _timer?.cancel();
    _audioCompleteSub?.cancel();

    if (engine.currentState == PrayerState.selesai) {
      return;
    }

    final cue = cueResolver.resolve(engine.currentState, level, engine.config);
    if (cue != null) {
      audioService.play(cue);
    }

    if (_shortTransitionStates.contains(engine.currentState)) {
      if (cue != null) {
        _audioCompleteSub = audioService.onComplete.listen((_) => _autoAdvance());
      } else {
        _timer = Timer(_shortTransitionDuration, _autoAdvance);
      }
      return;
    }

    if (_variableReadingStates.contains(engine.currentState)) {
      final isFullRecite = level == AssistanceLevel.fullRecite;
      if (isFullRecite && cue != null) {
        _audioCompleteSub = audioService.onComplete.listen((_) => _autoAdvance());
      }
      // else: manual Next only, no timer/subscription armed.
      return;
    }

    // Fixed-posture states.
    final tumaninah = tumaninahDurations[engine.currentState]!;
    final isFullRecite = level == AssistanceLevel.fullRecite;
    if (isFullRecite && cue != null) {
      var tumaninahElapsed = false;
      var audioCompleted = false;
      _timer = Timer(tumaninah, () {
        tumaninahElapsed = true;
        if (audioCompleted) _autoAdvance();
      });
      _audioCompleteSub = audioService.onComplete.listen((_) {
        audioCompleted = true;
        if (tumaninahElapsed) _autoAdvance();
      });
    } else {
      _timer = Timer(tumaninah, _autoAdvance);
    }
  }

  void _autoAdvance() {
    if (_isPaused) return;
    engine.advance();
    _enterState();
    notifyListeners();
  }

  void pause() {
    _isPaused = true;
    _timer?.cancel();
    _audioCompleteSub?.cancel();
    audioService.stop();
    notifyListeners();
  }

  void resume() {
    _isPaused = false;
    _enterState();
    notifyListeners();
  }

  void back() {
    _isPaused = false;
    engine.previous();
    _enterState();
    notifyListeners();
  }

  void next() {
    _isPaused = false;
    engine.advance();
    _enterState();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioCompleteSub?.cancel();
    super.dispose();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/guided/guided_mode_controller_test.dart
```

Expected: `00:0X +4: All tests passed!`

- [ ] **Step 5: Verify full suite still green**

```bash
flutter analyze
flutter test
```

Expected: no analyzer errors; all tests across Tasks 2-4 pass.

- [ ] **Step 6: Commit**

```bash
cd /home/astro/claude-project/NASYN-v-Claude
git add nasyn_app/lib/guided nasyn_app/test/guided
git commit -m "Add GuidedModeController orchestrating FSM timing and audio cues"
```

---

## Task 5: Minimum UI + Riverpod wiring

**Files:**
- Create: `nasyn_app/lib/prayer/prayer_state_labels.dart`
- Create: `nasyn_app/lib/ui/home_screen.dart`
- Create: `nasyn_app/lib/ui/prayer_session_screen.dart`
- Create: `nasyn_app/lib/ui/session_summary_screen.dart`
- Modify: `nasyn_app/lib/main.dart`

**Interfaces:**
- Consumes: `PrayerType`, `PrayerConfig`, `prayerConfigs`, `PrayerState` (Task 2); `AssistanceLevel`, `AudioCueResolver` (Task 3); `AudioPlayerService` (Task 3); `GuidedModeController` (Task 4).
- Produces: a runnable app (`NasynApp` widget in `main.dart`) navigating Home → Prayer Session → Session Summary → Home.

- [ ] **Step 1: Write `prayer_state_labels.dart`**

```dart
import 'prayer_state.dart';

const Map<PrayerState, String> prayerStateLabelsBm = {
  PrayerState.takbiratulIhram: 'Takbiratul Ihram',
  PrayerState.qiyam: 'Berdiri (Qiyam)',
  PrayerState.rukuk: 'Rukuk',
  PrayerState.iktidal: 'Iktidal',
  PrayerState.sujud1: 'Sujud',
  PrayerState.dudukAntaraSujud: 'Duduk Antara Dua Sujud',
  PrayerState.sujud2: 'Sujud Kedua',
  PrayerState.dudukTahiyatAwal: 'Tahiyat Awal',
  PrayerState.dudukTahiyatAkhir: 'Tahiyat Akhir',
  PrayerState.salam: 'Salam',
  PrayerState.selesai: 'Selesai',
};

const Map<PrayerState, String> prayerStateLabelsArabic = {
  PrayerState.takbiratulIhram: 'تكبيرة الإحرام',
  PrayerState.qiyam: 'قيام',
  PrayerState.rukuk: 'ركوع',
  PrayerState.iktidal: 'اعتدال',
  PrayerState.sujud1: 'سجود',
  PrayerState.dudukAntaraSujud: 'جلوس بين السجدتين',
  PrayerState.sujud2: 'سجود',
  PrayerState.dudukTahiyatAwal: 'تشهد أول',
  PrayerState.dudukTahiyatAkhir: 'تشهد أخير',
  PrayerState.salam: 'سلام',
  PrayerState.selesai: '',
};
```

- [ ] **Step 2: Write `prayer_session_screen.dart`** (defines the Riverpod provider used by Home)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_cue_resolver.dart';
import '../audio/audio_player_service.dart';
import '../guided/guided_mode_controller.dart';
import '../prayer/prayer_config.dart';
import '../prayer/prayer_state_labels.dart';
import 'session_summary_screen.dart';

final guidedModeControllerProvider = ChangeNotifierProvider.autoDispose
    .family<GuidedModeController, ({PrayerType type, AssistanceLevel level})>(
  (ref, args) {
    final controller = GuidedModeController(
      config: prayerConfigs[args.type]!,
      level: args.level,
      audioService: AudioPlayerService(),
      cueResolver: AudioCueResolver(),
    );
    ref.onDispose(controller.dispose);
    return controller;
  },
);

class PrayerSessionScreen extends ConsumerWidget {
  final PrayerType prayerType;
  final AssistanceLevel level;

  const PrayerSessionScreen({
    super.key,
    required this.prayerType,
    required this.level,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (type: prayerType, level: level);
    final controller = ref.watch(guidedModeControllerProvider(args));
    final config = prayerConfigs[prayerType]!;

    if (controller.isComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => SessionSummaryScreen(
            prayerType: prayerType,
            totalRakaat: config.rakaatCount,
          ),
        ));
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text(config.displayName)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Rakaat ${controller.currentRakaat} / ${config.rakaatCount}'),
            const SizedBox(height: 16),
            Text(prayerStateLabelsBm[controller.currentState] ?? ''),
            Text(prayerStateLabelsArabic[controller.currentState] ?? ''),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.fast_rewind),
                  onPressed: controller.back,
                ),
                IconButton(
                  icon: Icon(controller.isPaused ? Icons.play_arrow : Icons.pause),
                  onPressed: controller.isPaused ? controller.resume : controller.pause,
                ),
                IconButton(
                  icon: const Icon(Icons.fast_forward),
                  onPressed: controller.next,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Write `session_summary_screen.dart`**

```dart
import 'package:flutter/material.dart';

import '../prayer/prayer_config.dart';
import 'home_screen.dart';

class SessionSummaryScreen extends StatelessWidget {
  final PrayerType prayerType;
  final int totalRakaat;

  const SessionSummaryScreen({
    super.key,
    required this.prayerType,
    required this.totalRakaat,
  });

  @override
  Widget build(BuildContext context) {
    final config = prayerConfigs[prayerType]!;
    return Scaffold(
      appBar: AppBar(title: const Text('Selesai')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${config.displayName} selesai'),
            Text('Rakaat: $totalRakaat / $totalRakaat'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
              child: const Text('Selesai'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Write `home_screen.dart`**

```dart
import 'package:flutter/material.dart';

import '../audio/audio_cue_resolver.dart';
import '../prayer/prayer_config.dart';
import 'prayer_session_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PrayerType _selectedType = PrayerType.zuhur;
  AssistanceLevel _selectedLevel = AssistanceLevel.fullRecite;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NASYN')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Pilih Solat'),
            DropdownButton<PrayerType>(
              value: _selectedType,
              items: PrayerType.values
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(prayerConfigs[t]!.displayName),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedType = value);
              },
            ),
            const SizedBox(height: 16),
            const Text('Tahap Bantuan'),
            RadioListTile<AssistanceLevel>(
              title: const Text('Takbir Only'),
              value: AssistanceLevel.takbirOnly,
              groupValue: _selectedLevel,
              onChanged: (value) => setState(() => _selectedLevel = value!),
            ),
            RadioListTile<AssistanceLevel>(
              title: const Text('Panduan Posisi'),
              value: AssistanceLevel.panduanPosisi,
              groupValue: _selectedLevel,
              onChanged: (value) => setState(() => _selectedLevel = value!),
            ),
            RadioListTile<AssistanceLevel>(
              title: const Text('Full Recite'),
              value: AssistanceLevel.fullRecite,
              groupValue: _selectedLevel,
              onChanged: (value) => setState(() => _selectedLevel = value!),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PrayerSessionScreen(
                    prayerType: _selectedType,
                    level: _selectedLevel,
                  ),
                ));
              },
              child: const Text('Mula'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Replace `main.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: NasynApp()));
}

class NasynApp extends StatelessWidget {
  const NasynApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NASYN',
      home: const HomeScreen(),
    );
  }
}
```

- [ ] **Step 6: Verify it compiles and the existing test suite is unaffected**

```bash
cd /home/astro/claude-project/NASYN-v-Claude/nasyn_app
flutter analyze
flutter test
flutter build apk --debug
```

Expected: no analyzer errors, all existing tests still pass (this task adds no new tests — plain UI wiring, throwaway per the design spec), `Built build/app/outputs/flutter-apk/app-debug.apk`.

- [ ] **Step 7: Commit**

```bash
cd /home/astro/claude-project/NASYN-v-Claude
git add nasyn_app/lib/prayer/prayer_state_labels.dart nasyn_app/lib/ui nasyn_app/lib/main.dart
git commit -m "Add minimum UI (Home, Prayer Session, Summary) wired via Riverpod"
```

---

## Task 6: Device smoke test on Redmi 9A

**Files:**
- None created — this task verifies the app on-device, mirroring Fasa 0's Task 7.

**Interfaces:**
- Consumes: the complete app from Tasks 1-5.
- Produces: confirmed evidence that a full guided prayer session (all 3 assistance levels, at least one multi-rakaat prayer with tahiyat awal) runs correctly end-to-end with real audio playback on the target device.

- [ ] **Step 1: Build the debug APK**

```bash
cd /home/astro/claude-project/NASYN-v-Claude/nasyn_app
flutter build apk --debug
```

Expected: `Built build/app/outputs/flutter-apk/app-debug.apk`.

- [ ] **Step 2: Confirm device is connected and authorized**

```bash
adb devices -l
```

Expected: `9HJ7OZ55XSXOPVJZ  device` (not `unauthorized`, not empty). If it shows nothing, ask the human to reconnect the USB cable and re-check.

- [ ] **Step 3: Sideload (adb install is blocked by MIUI on this device — use the Fasa 0 workaround)**

```bash
adb push build/app/outputs/flutter-apk/app-debug.apk /sdcard/Download/nasyn_app-debug.apk
```

Then ask the human to: open Files/File Manager on the Redmi 9A → Download →
tap `nasyn_app-debug.apk` → if MIUI blocks it, tap Settings, enable "Allow
from this source" for Files, go back, tap install again → Install → Open.

- [ ] **Step 4: Confirm a full guided session runs correctly**

Ask the human to, on-device:
1. Pick **Zuhur** (4 rakaat, exercises the tahiyat-awal-after-rakaat-2 path) with **Full Recite** level, tap Mula.
2. Confirm: Takbiratul Ihram audio plays and auto-advances to Qiyam; Al-Fatihah audio plays in Qiyam and auto-advances to Rukuk; Rukuk holds for at least its bacaan audio duration before advancing; the rakaat counter and state labels update correctly through a full 4-rakaat cycle including one Tahiyat Awal (after rakaat 2) and Tahiyat Akhir (after rakaat 4); session ends on a Summary screen showing "Rakaat 4 / 4"; "Selesai" returns to Home.
3. Repeat quickly with **Subuh** (2 rakaat, no tahiyat awal) at **Takbir Only** level, confirming Qiyam requires a manual ⏩ Next tap (no audio, no auto-advance) and no Tahiyat Awal ever appears.
4. Test ⏸ Pause (session stays on the same state while paused) and ⏪ Back (reverses to the previous state) at least once.

- [ ] **Step 5: Write the report**

Confirm with the human that all checks in Step 4 passed, and note any
discrepancy. If a bug is found (e.g. an audio file doesn't play, wrong
label shown), fix it in the relevant file from Tasks 2-5 and re-verify
before considering this task done — do not commit a known-broken smoke
test as passing.

- [ ] **Step 6: Commit (only if a fix was needed)**

```bash
cd /home/astro/claude-project/NASYN-v-Claude
git add nasyn_app
git commit -m "Fix issue found during Fasa 1 device smoke test"
```

If no fix was needed, skip this step — nothing to commit.

---

## Self-Review Notes

- **Spec coverage:** Data model (§1) = Task 2. FSM (§2, including the BUG #1
  Tahiyat Awal timing scenario) = Task 2. Guided Mode Controller (§3,
  including the addendum's takbir/salam timing rule) = Task 4. Audio Engine
  (§4, including the addendum's testable-interface requirement) = Task 3.
  Minimum UI (§5) = Task 5. Testing Plan (§6) = Tasks 2-4's test steps.
  Out-of-scope items (Vision Mode, kiosk, visual design, SQLite persistence,
  Manual Override, Alert Modes, qunut audio, recording the 3 missing files)
  are correctly absent from every task.
- **Type consistency:** `PrayerState`, `PrayerType`, `PrayerConfig`,
  `prayerConfigs`, `PrayerStateEngine`, `AudioService`, `AudioPlayerService`,
  `AssistanceLevel`, `AudioCueResolver`, `FakeAudioService`,
  `GuidedModeController`, `tumaninahDurations` are each defined once and
  reused with identical signatures across later tasks.
- **No placeholders:** every step has runnable code and an exact expected
  result. The FSM's `advance()`/`previous()` logic was manually traced
  end-to-end (28-transition round trip for Zuhur) before being written into
  this plan, to catch the qiyam-previous() ambiguity (whether the prior
  state was `dudukTahiyatAwal` or `sujud2`) before an implementer hits it.
