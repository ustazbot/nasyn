"""Rakam burst dari webcam N saat, run bbox+landmark setiap frame, log CSV,
save keyframe beranotasi setiap K saat. Untuk Claude kawal & analisis sendiri.
Guna: .venv/bin/python burst.py <saat> [prefix]"""
import csv
import sys
import time
import cv2
import mediapipe as mp
import spike_proximity_signal as s

dur = float(sys.argv[1]) if len(sys.argv) > 1 else 40
prefix = sys.argv[2] if len(sys.argv) > 2 else "burst"
KEYFRAME_EVERY = 5.0

cap = cv2.VideoCapture(0)
for _ in range(10):
    cap.read()

fd, fl = s.build_detectors()
rows = []
t0 = time.time()
last_key = -KEYFRAME_EVERY
n_key = 0

while time.time() - t0 < dur:
    ok, frame = cap.read()
    if not ok:
        break
    t = time.time() - t0
    h, w = frame.shape[:2]
    img = mp.Image(image_format=mp.ImageFormat.SRGB, data=cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
    r1 = fd.detect(img)
    r2 = fl.detect(img)

    ratio, conf = 0.0, 0.0
    if r1.detections:
        det = r1.detections[0]
        bb = det.bounding_box
        ratio = (bb.width * bb.height) / (w * h)
        conf = det.categories[0].score
        cv2.rectangle(frame, (bb.origin_x, bb.origin_y),
                      (bb.origin_x + bb.width, bb.origin_y + bb.height), (0, 255, 0), 2)
    lm = bool(r2.face_landmarks)
    if lm:
        for p in r2.face_landmarks[0][::10]:
            cv2.circle(frame, (int(p.x * w), int(p.y * h)), 2, (0, 0, 255), -1)

    rows.append({"t": round(t, 2), "bbox": bool(r1.detections),
                 "ratio": round(ratio, 4), "conf": round(conf, 3), "landmark": lm})

    if t - last_key >= KEYFRAME_EVERY:
        cv2.putText(frame, f"t={t:.1f}s ratio={ratio:.3f} lm={lm}", (10, 30),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)
        cv2.imwrite(f"{prefix}_t{int(t):03d}.jpg", frame)
        n_key += 1
        last_key = t

cap.release(); fd.close(); fl.close()

out = f"{prefix}.csv"
with open(out, "w", newline="") as f:
    wr = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
    wr.writeheader(); wr.writerows(rows)

n = len(rows)
det_rate = sum(1 for r in rows if r["bbox"]) / n * 100
lm_rate = sum(1 for r in rows if r["landmark"]) / n * 100
print(f"{n} frames / {dur:.0f}s | bbox rate {det_rate:.0f}% | landmark rate {lm_rate:.0f}% | {n_key} keyframes | {out}")
