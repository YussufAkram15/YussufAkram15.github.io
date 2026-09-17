#!/usr/bin/env bash
# Install a new about-photo. Usage: ./update-photo.sh /path/to/new-headshot.jpg
set -euo pipefail
SRC="${1:?usage: ./update-photo.sh /path/to/new-headshot.jpg}"
DIR="$(cd "$(dirname "$0")" && pwd)"

[ -f "$SRC" ] || { echo "no such file: $SRC" >&2; exit 1; }
cp "$SRC" "$DIR/photo-original.jpeg"

python3 - "$DIR" <<'PY'
import sys
from PIL import Image, ImageOps
d = sys.argv[1]
im = ImageOps.exif_transpose(Image.open(f"{d}/photo-original.jpeg")).convert("RGB")
# 3:4 portrait, 2x the 210px display column
im = ImageOps.fit(im, (420, 560), Image.LANCZOS, centering=(0.5, 0.22))
im.save(f"{d}/photo.jpeg", "JPEG", quality=84, optimize=True, progressive=True)
print("photo.jpeg ->", im.size)
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
echo "done — reload the page to see it"
