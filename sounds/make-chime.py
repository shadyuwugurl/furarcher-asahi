#!/usr/bin/env python3
"""Synthesize a soft SFW login chime. Stdlib only, no deps, no binary assets.
Usage: make-chime.py <boykisser|mlm> <out.wav>
"""
import math
import struct
import sys
import wave

RATE = 44100
MOODS = {
    # bright major arpeggio, kissy hello
    "boykisser": [659.25, 830.61, 987.77, 1318.51],
    # warm lower triad, holding-hands hello
    "mlm": [440.00, 554.37, 659.25, 880.00],
}
NOTE_LEN = 0.34
TAIL = 0.25


def note(freq, n):
    out = []
    for i in range(n):
        t = i / RATE
        env = min(1.0, t / 0.02) * math.exp(-3.0 * t / NOTE_LEN)
        s = math.sin(2 * math.pi * freq * t) + 0.3 * math.sin(4 * math.pi * freq * t)
        out.append(s * env)
    return out


def main():
    if len(sys.argv) != 3 or sys.argv[1] not in MOODS:
        print(f"usage: {sys.argv[0]} <boykisser|mlm> <out.wav>", file=sys.stderr)
        return 1
    samples = []
    for f in MOODS[sys.argv[1]]:
        samples += note(f, int(NOTE_LEN * RATE))
    samples += [0.0] * int(TAIL * RATE)
    peak = max(1e-6, max(abs(s) for s in samples))
    with wave.open(sys.argv[2], "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(
            struct.pack("<h", int(s / peak * 26000)) for s in samples))
    print(f"chime: {sys.argv[2]} ({len(samples) / RATE:.1f}s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
