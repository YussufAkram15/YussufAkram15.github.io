#!/usr/bin/env bash
# Install the E-JUST logo shown next to the education block.
# Usage: ./add-uni-logo.sh /path/to/ejust-logo.png
# Until you run this, the block falls back to an "E-JUST" monogram tile.
set -euo pipefail
SRC="${1:?usage: ./add-uni-logo.sh /path/to/ejust-logo.png}"
DIR="$(cd "$(dirname "$0")" && pwd)"
[ -f "$SRC" ] || { echo "no such file: $SRC" >&2; exit 1; }

python3 - "$SRC" "$DIR" <<'PY'
import sys
from PIL import Image, ImageChops
src, d = sys.argv[1], sys.argv[2]
im = Image.open(src).convert("RGBA")

# trim uniform border (screenshots and exports usually carry one)
bg = im.getpixel((0, 0))
diff = ImageChops.difference(im, Image.new("RGBA", im.size, bg)).convert("L")
box = diff.point(lambda v: 255 if v > 18 else 0).getbbox()
if box:
    im = im.crop(box)

im.thumbnail((100, 100), Image.LANCZOS)          # leaves padding in the 112px tile
canvas = Image.new("RGBA", (112, 112), (0, 0, 0, 0))
canvas.paste(im, ((112 - im.width) // 2, (112 - im.height) // 2), im)
canvas.save(f"{d}/assets/ejust-logo.png", "PNG", optimize=True)
print("assets/ejust-logo.png ->", canvas.size)
PY

ls -la "$DIR/assets/ejust-logo.png"
echo "done — reload the page"
