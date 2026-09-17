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
from PIL import Image
src, d = sys.argv[1], sys.argv[2]
im = Image.open(src)
im = im.convert("RGBA") if im.mode in ("RGBA", "LA", "P") else im.convert("RGB")
im.thumbnail((112, 112), Image.LANCZOS)          # 2x the 56px tile
canvas = Image.new("RGBA", (112, 112), (0, 0, 0, 0))
canvas.paste(im, ((112 - im.width) // 2, (112 - im.height) // 2),
             im if im.mode == "RGBA" else None)
canvas.save(f"{d}/assets/ejust-logo.png", "PNG", optimize=True)
print("assets/ejust-logo.png ->", canvas.size)
PY

ls -la "$DIR/assets/ejust-logo.png"
echo "done — reload the page"
