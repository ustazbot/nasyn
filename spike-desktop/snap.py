"""Snap 1 frame dari webcam, run bbox+landmark, save gambar beranotasi.
Guna: .venv/bin/python snap.py [nama_output.jpg]  — untuk Claude analisis visual."""
import sys
import cv2
import mediapipe as mp
import spike_proximity_signal as s

out = sys.argv[1] if len(sys.argv) > 1 else "snap.jpg"
cap = cv2.VideoCapture(0)
# buang beberapa frame awal — auto-exposure webcam perlu masa settle
for _ in range(10):
    cap.read()
ok, frame = cap.read()
cap.release()
assert ok, "webcam gagal"

h, w = frame.shape[:2]
fd, fl = s.build_detectors()
img = mp.Image(image_format=mp.ImageFormat.SRGB, data=cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
r1 = fd.detect(img)
r2 = fl.detect(img)

if r1.detections:
    det = r1.detections[0]
    bb = det.bounding_box
    ratio = (bb.width * bb.height) / (w * h)
    conf = det.categories[0].score
    cv2.rectangle(frame, (bb.origin_x, bb.origin_y),
                  (bb.origin_x + bb.width, bb.origin_y + bb.height), (0, 255, 0), 2)
    print(f"BBOX: YES ratio={ratio:.3f} conf={conf:.2f} box=({bb.origin_x},{bb.origin_y},{bb.width}x{bb.height})")
else:
    print("BBOX: NO")

if r2.face_landmarks:
    for lm in r2.face_landmarks[0][::10]:
        cv2.circle(frame, (int(lm.x * w), int(lm.y * h)), 2, (0, 0, 255), -1)
    print(f"LANDMARK: YES ({len(r2.face_landmarks[0])} pts)")
else:
    print("LANDMARK: NO")

cv2.imwrite(out, frame)
print(f"Saved: {out} ({w}x{h})")
fd.close(); fl.close()
