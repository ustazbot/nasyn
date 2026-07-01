# Fasa 0: Head-Based Pose Spike Test — Design

**Tarikh:** 2026-07-01
**Sumber:** PRD-NASYN-v3-0-Kiosk-Edition.md §5, §8.2–8.3, §12

## Tujuan

Jawab satu soalan: bolehkah head-based pose classification (nose/ears sebagai
primary signal, shoulders sebagai validator) capai KPI production PRD pada
device refurb sebenar (Redmi 9A, Android 10, ~3.8GB RAM, MediaTek Helio G25)?

GO/NO-GO ini menentukan sama ada Vision Assisted Mode (mod utama produk)
teruskan ke Fasa 3, atau produk fallback penuh ke Guided Mode.

Bukan skop spike ini: Flutter shell, platform channel, FSM, audio, rakaat
counting, kiosk lockdown. Semua itu Fasa 1+.

## Device Sasaran

- Model: Xiaomi Redmi 9A (`M2006C3LG`, codename `dandelion`)
- Android 10 (SDK 29), MemTotal ~3.8GB, MediaTek Helio G25 (mt6765), armeabi-v7a
- Kamera depan tersedia (`android.hardware.camera.front`)
- Disahkan sepadan spesifikasi minimum PRD §5 (Android 10+, RAM 3GB+)

## Architecture

```
CameraX (front camera, ImageAnalysis use case)
  → MediaPipe Tasks Vision PoseLandmarker (LITE model, LIVE_STREAM mode)
  → PoseClassifier (pure Kotlin, rule-based: head-Y + head-shoulder ratio
    vs calibrated baseline — PRD §8.3)
  → PoseOverlayView (skeleton dots + predicted class + confidence% + latency ms)
  → TallyLogger (✓/✗ tap → per-class counters → CSV log)
```

Standalone Android app (Kotlin, single Activity). No Flutter, no platform
channel — those are production concerns (Fasa 3), premature for a
feasibility spike.

## Components

### `PoseClassifier.kt`
Pure Kotlin, no Android dependencies. Input: landmark set (nose, ears,
shoulders) + `CalibrationProfile` (per-user baseline from calibration step).
Output: `PoseClass` enum (`QIYAM, RUKUK, SUJUD, DUDUK, UNKNOWN`) + confidence
0–100.

Rules (PRD §8.3):
- Head Y relative to calibrated standing baseline → primary discriminator
- Head-to-shoulder vertical ratio → primary for SUJUD
- Shoulder landmarks → validator (still visible under telekung)
- Confidence bands: ≥80 ACCEPT, 60–79 HOLD, <60 REJECT/UNKNOWN
- QIYAM vs IKTIDAL is *not* distinguished here — both are "head high
  baseline." That disambiguation is FSM context (Fasa 1), out of scope.

### Calibration (in-Activity, no separate screen needed)
4 buttons: Berdiri / Rukuk / Sujud / Duduk. User holds each pose, taps the
matching button, activity records the current landmark reading as that
pose's baseline. Held in memory only — no persistence needed, spike runs
one session at a time.

### `PoseOverlayView`
Custom `View` drawn over `PreviewView`: draws landmark dots (nose, ears,
shoulders) and live text — predicted class, confidence%, per-frame
inference latency (ms).

### `TallyLogger`
On-screen ✓ / ✗ buttons let the tester mark whether the live overlay's
prediction matches their actual pose. Appends one line per tap:
`timestamp,predictedClass,confidence,latencyMs,correct` to a CSV in
app-local storage (`getExternalFilesDir`), pulled via `adb pull` after the
session.

## Test Protocol

Bos (self) performs each pose class ≥15–20 times, normal clothing (no
telekung/jubah for this first pass), indoor lighting as-is. Tap ✓/✗ against
what the overlay shows for each stabilized (≥500ms) classification.

Telekung/jubah and low-light conditions are a follow-up pass *after* this
baseline confirms the approach works at all — no point testing edge
conditions before the core signal is validated.

## GO / NO-GO Criteria

Pulled CSV → compute per-class accuracy + average/95th-percentile latency.
Compare directly against PRD §12 production KPIs:

| Metrik | Target |
|---|---|
| QIYAM / RUKUK / DUDUK accuracy | >90% |
| SUJUD accuracy | >80% |
| Pose detection latency | <100ms |

- **GO**: all targets met.
- **PARTIAL**: close but under target (e.g. SUJUD 70–80%, or latency
  100–150ms) — tunable in Fasa 3 (model swap, threshold tuning), not a
  blocker.
- **NO-GO**: fundamentally can't discriminate (e.g. RUKUK/DUDUK
  indistinguishable, or latency >250ms unfixable on this hardware).

Output: `SPIKE-RESULT.md` — per-class accuracy table, latency stats,
verdict, notable failure patterns (QIYAM/IKTIDAL confusion is *expected*
and not a failure — that's FSM's job).

## Testing Approach

One JVM unit test (`PoseClassifierTest`) with hand-built landmark fixtures
per class, asserting `PoseClassifier` returns the expected `PoseClass` for
each. Everything else (camera pipeline, overlay, real-world accuracy) is
validated by the manual protocol above, not automated — this is a
throwaway spike, not production code.

## Out of Scope (explicitly)

- Flutter / platform channel integration
- FSM, rakaat counting, tahiyat logic
- Audio engine
- Kiosk lockdown (Device Owner / Screen Pinning)
- Telekung/jubah and low-light testing (follow-up pass, not this spec)
- Calibration persistence across sessions
