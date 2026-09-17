#!/usr/bin/env bash
# Install a new about-photo. Usage: ./update-photo.sh /path/to/new-headshot.jpg
# Crops to 3:4 and auto-centres on the subject's head against a plain backdrop.
set -euo pipefail
SRC="${1:?usage: ./update-photo.sh /path/to/new-headshot.jpg}"
DIR="$(cd "$(dirname "$0")" && pwd)"

[ -f "$SRC" ] || { echo "no such file: $SRC" >&2; exit 1; }
cp "$SRC" "$DIR/photo-original.jpeg"

python3 - "$DIR" <<'PY'
import sys
import numpy as np
from PIL import Image, ImageOps

d = sys.argv[1]
W, H = 420, 560                      # 3:4, 2x the 210px display column
im = ImageOps.exif_transpose(Image.open(f"{d}/photo-original.jpeg")).convert("RGB")

def head_centering(img):
    """Find the horizontal centering that puts the head in the middle of a 3:4 crop."""
    a = np.asarray(img).astype(float)
    h, w, _ = a.shape
    bg = np.median(
        np.concatenate([a[:60, :60].reshape(-1, 3), a[:60, -60:].reshape(-1, 3)]), axis=0
    )
    subject = np.linalg.norm(a - bg, axis=2) > 38
    band = subject[int(h * 0.12):int(h * 0.38), :]     # hair down to chin
    mass = band.sum(axis=0)
    if mass.sum() == 0:
        return 0.5                                     # busy background: fall back to centre
    centroid = (mass * np.arange(w)).sum() / mass.sum()
    crop_w = h * (W / H)
    slack = w - crop_w
    if slack <= 0:
        return 0.5                                     # already narrower than 3:4
    return float(np.clip((centroid - crop_w / 2) / slack, 0.0, 1.0))

cx = head_centering(im)
print(f"auto-centre cx={cx:.3f}")
out = ImageOps.fit(im, (W, H), Image.LANCZOS, centering=(cx, 0.22))
out.save(f"{d}/photo.jpeg", "JPEG", quality=84, optimize=True, progressive=True)
print("photo.jpeg ->", out.size)
PY

python3 - "$DIR" <<'PY'
import re, sys
d = sys.argv[1]
p = f"{d}/index.html"
s = open(p, encoding="utf-8").read()
s = re.sub(r'(class="about-photo"[^>]*?)width="\d+"\s+height="\d+"',
           r'\1width="420"\n              height="560"', s, count=1, flags=re.S)
open(p, "w", encoding="utf-8").write(s)
print("index.html width/height updated")
PY

ls -la "$DIR/photo.jpeg"
