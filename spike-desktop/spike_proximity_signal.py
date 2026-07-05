"""
NASYN — Spike Ulangan: Proximity/Blob-Size Signal untuk SUJUD Detection
=========================================================================
Rujukan: PRD-NASYN-v3-1-Kiosk-Edition.md §8.13 (Camera Mounting — Vision Mode)

Bandingkan 2 pendekatan sekali gus:
  1. BOUNDING-BOX (blob-size) — MediaPipe Face Detector (BlazeFace short-range)
  2. FACE LANDMARK (478 titik) — MediaPipe Face Landmarker

CARA GUNA
---------
Setup (sudah siap oleh Claude — venv + model dalam folder ini):
    cd spike-desktop
    source .venv/bin/activate

Mode A — webcam (perlu USB webcam, GMKtec tiada webcam built-in):
    python3 spike_proximity_signal.py

Mode B — video file (DISYORKAN: rakam di Redmi 9A pada mounting sebenar
§8.13, pindah fail ke sini):
    python3 spike_proximity_signal.py rakaman.mp4
    python3 spike_proximity_signal.py rakaman.mp4 90    # kalau video terbalik/melintang: rotate 90/180/270

Keys semasa window terbuka (label frame SEMASA — tekan sebelum mula pose):
    q = QIYAM   r = RUKUK   s = SUJUD   d = DUDUK
    SPACE = pause/resume (mode video sahaja)
    x = STOP & print summary

Output: spike_log_<timestamp>.csv + summary table per label.

INTERPRETASI HASIL (Go/No-Go §8.13)
------------------------------------
- bbox_area_ratio SUJUD jelas lebih besar dari QIYAM/DUDUK, overlap sikit
  → signal boleh dipercayai, proceed Kotlin guna bounding-box.
- landmark_rate jatuh <50% semasa SUJUD → confirm: JANGAN guna Landmarker
  untuk SUJUD, guna bounding-box sahaja.
- bbox_area_ratio overlap teruk antara label → mounting §8.13 kena
  re-design, JANGAN proceed Kotlin.
"""

import csv
import sys
import time
from pathlib import Path

import cv2
import mediapipe as mp
from mediapipe.tasks import python as mp_python
from mediapipe.tasks.python import vision as mp_vision

SCRIPT_DIR = Path(__file__).resolve().parent
FACE_DETECTOR_MODEL = str(SCRIPT_DIR / "face_detector.tflite")
FACE_LANDMARKER_MODEL = str(SCRIPT_DIR / "face_landmarker.task")

LABELS = {
    ord("q"): "QIYAM",
    ord("r"): "RUKUK",
    ord("s"): "SUJUD",
    ord("d"): "DUDUK",
}
STOP_KEY = ord("x")
PAUSE_KEY = ord(" ")

ROTATIONS = {90: cv2.ROTATE_90_CLOCKWISE, 180: cv2.ROTATE_180, 270: cv2.ROTATE_90_COUNTERCLOCKWISE}


def check_models():
    missing = [m for m in (FACE_DETECTOR_MODEL, FACE_LANDMARKER_MODEL) if not Path(m).exists()]
    if missing:
        print("Model file tak jumpa:", missing)
        print("Rujuk docstring — wget URL. NOTA: landmarker ialah .task, BUKAN .tflite.")
        sys.exit(1)


def build_detectors():
    fd_options = mp_vision.FaceDetectorOptions(
        base_options=mp_python.BaseOptions(model_asset_path=FACE_DETECTOR_MODEL),
        # rendah sengaja — kita nak tengok degrade pattern, bukan hard cutoff
        min_detection_confidence=0.3,
        running_mode=mp_vision.RunningMode.IMAGE,
    )
    fl_options = mp_vision.FaceLandmarkerOptions(
        base_options=mp_python.BaseOptions(model_asset_path=FACE_LANDMARKER_MODEL),
        num_faces=1,
        min_face_detection_confidence=0.3,
        min_face_presence_confidence=0.3,
        running_mode=mp_vision.RunningMode.IMAGE,
    )
    return (
        mp_vision.FaceDetector.create_from_options(fd_options),
        mp_vision.FaceLandmarker.create_from_options(fl_options),
    )


def main():
    check_models()

    video_path = sys.argv[1] if len(sys.argv) > 1 else None
    rotate = ROTATIONS.get(int(sys.argv[2])) if len(sys.argv) > 2 else None
    is_video = video_path is not None

    if is_video:
        if not Path(video_path).exists():
            print(f"Video tak jumpa: {video_path}")
            sys.exit(1)
        cap = cv2.VideoCapture(video_path)
    else:
        cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        if is_video:
            print("Tak dapat buka video file.")
        else:
            print("Tak dapat buka webcam. GMKtec tiada webcam built-in — "
                  "sambung USB webcam, atau guna mode video file (rakam di Redmi 9A).")
        sys.exit(1)

    face_detector, face_landmarker = build_detectors()

    current_label = "UNLABELED"
    rows = []
    frame_idx = 0
    paused = False
    frame = None

    print("=" * 60)
    print("NASYN Spike — Proximity/Blob-Size Signal Test (§8.13)")
    print(f"Sumber: {'video ' + video_path if is_video else 'webcam'}")
    print("Keys: q=QIYAM r=RUKUK s=SUJUD d=DUDUK"
          + (" SPACE=pause" if is_video else "") + " x=STOP")
    print("=" * 60)

    while True:
        if not paused:
            ok, frame = cap.read()
            if not ok:
                print("Habis video." if is_video else "Frame gagal baca dari webcam.")
                break
            if rotate is not None:
                frame = cv2.rotate(frame, rotate)

            frame_idx += 1
            h, w = frame.shape[:2]
            frame_area = w * h
            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)

            # --- Bounding-box (blob-size) signal ---
            fd_result = face_detector.detect(mp_image)
            bbox_area_ratio = 0.0
            bbox_conf = 0.0
            bbox_detected = False
            if fd_result.detections:
                det = fd_result.detections[0]
                bbox = det.bounding_box
                bbox_area_ratio = (bbox.width * bbox.height) / frame_area
                bbox_conf = det.categories[0].score if det.categories else 0.0
                bbox_detected = True
                cv2.rectangle(
                    frame,
                    (bbox.origin_x, bbox.origin_y),
                    (bbox.origin_x + bbox.width, bbox.origin_y + bbox.height),
                    (0, 255, 0), 2,
                )

            # --- Face landmark signal ---
            fl_result = face_landmarker.detect(mp_image)
            landmark_detected = bool(fl_result.face_landmarks)
            num_landmarks = len(fl_result.face_landmarks[0]) if landmark_detected else 0

            rows.append({
                "frame": frame_idx,
                "timestamp": round(time.time(), 3),
                "label": current_label,
                "bbox_detected": bbox_detected,
                "bbox_area_ratio": round(bbox_area_ratio, 4),
                "bbox_confidence": round(bbox_conf, 3),
                "landmark_detected": landmark_detected,
                "num_landmarks": num_landmarks,
            })

            overlay = [
                f"LABEL: {current_label}" + ("  [PAUSED]" if paused else ""),
                f"bbox_area_ratio: {bbox_area_ratio:.3f} conf={bbox_conf:.2f} (detected={bbox_detected})",
                f"landmark: {'YES' if landmark_detected else 'NO'} ({num_landmarks} pts)",
            ]
            for i, line in enumerate(overlay):
                cv2.putText(frame, line, (10, 30 + i * 28),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)
            cv2.imshow("NASYN Spike - proximity signal", frame)

        key = cv2.waitKey(30 if paused else 1) & 0xFF
        if key in LABELS:
            current_label = LABELS[key]
            print(f"-> Label: {current_label}")
        elif key == PAUSE_KEY and is_video:
            paused = not paused
        elif key == STOP_KEY:
            break

    cap.release()
    cv2.destroyAllWindows()
    face_detector.close()
    face_landmarker.close()

    if not rows:
        print("Tiada data direkod.")
        return

    out_path = SCRIPT_DIR / f"spike_log_{int(time.time())}.csv"
    with open(out_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)
    print(f"\nLog disimpan: {out_path} ({len(rows)} frames)")

    print_summary(rows)


def print_summary(rows):
    print("\n" + "=" * 60)
    print("SUMMARY — untuk Go/No-Go keputusan §8.13")
    print("=" * 60)
    header = (f"{'LABEL':<12} {'n':>5} {'bbox_rate':>10} {'bbox_min':>9} "
              f"{'bbox_mean':>10} {'bbox_max':>9} {'landmark_rate':>14}")
    print(header)
    print("-" * len(header))
    for lbl in sorted(set(r["label"] for r in rows)):
        sub = [r for r in rows if r["label"] == lbl]
        n = len(sub)
        bbox_vals = [r["bbox_area_ratio"] for r in sub if r["bbox_detected"]]
        bbox_rate = len(bbox_vals) / n * 100
        landmark_rate = sum(1 for r in sub if r["landmark_detected"]) / n * 100
        if bbox_vals:
            print(f"{lbl:<12} {n:>5} {bbox_rate:>9.1f}% {min(bbox_vals):>9.3f} "
                  f"{sum(bbox_vals)/len(bbox_vals):>10.3f} {max(bbox_vals):>9.3f} "
                  f"{landmark_rate:>13.1f}%")
        else:
            print(f"{lbl:<12} {n:>5} {bbox_rate:>9.1f}% {'-':>9} {'-':>10} {'-':>9} "
                  f"{landmark_rate:>13.1f}%")
    print("\nRujuk 'INTERPRETASI HASIL' dalam docstring untuk panduan Go/No-Go.")


if __name__ == "__main__":
    main()
