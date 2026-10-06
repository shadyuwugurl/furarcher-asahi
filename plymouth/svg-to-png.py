#!/usr/bin/env python3
"""SVG -> PNG fallback when no system converter exists. Stdlib only (struct+zlib).
Draws the boykisser-dark gradient + glow + kissy face blobs. No text.
Usage: svg-to-png.py <width> <out.png>
"""
import math
import struct
import sys
import zlib

W2560_H1664 = 1664 / 2560


def lerp(a, b, t):
    return tuple(int(x + (y - x) * t) for x, y in zip(a, b))


def main():
    if len(sys.argv) != 3:
        print(f"usage: {sys.argv[0]} <width> <out.png>", file=sys.stderr)
        return 1
    w = int(sys.argv[1])
    h = int(w * W2560_H1664)
    top = (26, 14, 26)
    mid = (43, 16, 48)
    bot = (14, 26, 43)
    pink = (255, 122, 217)
    cx, cy, r = w * 0.5, h * 0.42, w * 0.30
    rows = []
    for y in range(h):
        t = y / max(1, h - 1)
        base = lerp(top, mid, t * 2) if t < 0.5 else lerp(mid, bot, t * 2 - 1)
        row = bytearray(b"\x00")
        for x in range(w):
            d = math.hypot(x - cx, y - cy) / max(1, r)
            glow = max(0.0, 1.0 - d) ** 2 * 0.55
            px = tuple(min(255, int(c + (p - c) * glow)) for c, p in zip(base, pink))
            # kissy cheeks
            for ex in (cx - w * 0.062, cx + w * 0.062):
                dd = math.hypot(x - ex, y - (cy + h * 0.048)) / max(1, w * 0.012)
                if dd < 1.0:
                    px = tuple(min(255, int(c + (255 - c) * 0.35 * (1 - dd))) for c in px)
            row += bytes(px)
        rows.append(bytes(row))
    raw = b"".join(rows)

    def chunk(tag, data):
        c = tag + data
        return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c))

    png = (b"\x89PNG\r\n\x1a\n"
           + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress(raw, 6))
           + chunk(b"IEND", b""))
    with open(sys.argv[2], "wb") as f:
        f.write(png)
    print(f"png: {sys.argv[2]} ({w}x{h}, stdlib fallback, no text)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
