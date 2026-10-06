#!/usr/bin/env python3
"""Synthesize a SFW boykisser login chime: happy yips + kiss smack + motif.
Stdlib only, no deps, no binary assets, deterministic (seeded).
Usage: make-chime.py <boykisser|mlm|yippee> <out.wav>
"""
import math
import random
import struct
import sys
import wave

RATE = 44100
random.seed(99)
MOODS = {
    # yip-yip + kiss + bright major arpeggio
    "boykisser": {"yips": [700, 820], "motif": [659.25, 830.61, 987.77, 1318.51]},
    # yip-yip (lower) + kiss + warm triad
    "mlm": {"yips": [560, 660], "motif": [440.00, 554.37, 659.25, 880.00]},
    # pure excitement: triple ascending yip-yip-yip + kiss, no long motif
    "yippee": {"yips": [620, 760, 920], "motif": [1318.51]},
}
NOTE_LEN = 0.34
TAIL = 0.25
YIP_LEN = 0.16


def lowpass(data, cutoff):
    a = math.exp(-2.0 * math.pi * cutoff / RATE)
    y = 0.0
    out = []
    for s in data:
        y += (1.0 - a) * (s - y)
        out.append(y)
    return out


def smack(dur=0.09):
    """Lip-smack pop: band-limited noise burst, sharp attack, fast decay."""
    n = int(dur * RATE)
    noise = [random.uniform(-1.0, 1.0) for _ in range(n)]
    band = [h - l for h, l in zip(lowpass(noise, 3400.0), lowpass(noise, 1100.0))]
    out = []
    for i, s in enumerate(band):
        t = i / RATE
        attack = min(1.0, t / 0.003)
        env = attack * math.exp(-t / 0.028)
        click = noise[i] * 0.6 if t < 0.004 else 0.0
        out.append((s * 1.4 + click) * env)
    return out


def mwah(dur=0.20, f0=700.0, f1=340.0):
    """Soft descending smooch tail under the smack."""
    n = int(dur * RATE)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / RATE
        f = f0 + (f1 - f0) * (t / dur)
        phase += 2.0 * math.pi * f / RATE
        env = math.sin(math.pi * t / dur) ** 0.7
        out.append(0.35 * math.sin(phase) * env)
    return out


def yip(base=620.0, dur=0.13):
    """Happy puppy yip: snappy rising chirp, formant bark body, no electric buzz.
    Few fast-decaying harmonics, organic jitter (not AM tremolo), lowpassed."""
    n = int(dur * RATE)
    out = []
    phases = [0.0] * 5
    for i in range(n):
        t = i / RATE
        frac = t / dur
        # snap up 2.1x in first quarter, relax back down
        glide = 1.0 + 1.1 * frac / 0.25 if frac < 0.25 else 2.1 - 1.05 * (frac - 0.25)
        jit = 1.0 + 0.020 * math.sin(2 * math.pi * 31.0 * t) + 0.010 * math.sin(2 * math.pi * 47.0 * t + 1.0)
        f = base * glide * jit
        s = 0.0
        for k in range(1, 6):
            phases[k - 1] += 2.0 * math.pi * k * f / RATE
            amp = 1.0 / (k ** 1.7)
            # vocal-tract formant bump around 1.0-1.5 kHz
            formant = 1.0 + 1.4 * math.exp(-(((k * f - 1250.0) / 650.0) ** 2))
            s += math.sin(phases[k - 1]) * amp * formant
        attack = min(1.0, t / 0.002)
        env = attack * math.exp(-2.6 * t / dur)
        onset = random.uniform(-1, 1) * 0.35 if t < 0.008 else 0.0
        out.append((s * 0.6 + onset) * env)
    # take the harsh edge off
    out = lowpass(out, 4200.0)
    peak = max(1e-6, max(abs(v) for v in out))
    return [v / peak * 0.85 for v in out]


def tone(freq, n):
    out = []
    for i in range(n):
        t = i / RATE
        env = min(1.0, t / 0.02) * math.exp(-3.0 * t / NOTE_LEN)
        s = math.sin(2 * math.pi * freq * t) + 0.3 * math.sin(4 * math.pi * freq * t)
        out.append(s * env)
    return out


def mix(base, add, at):
    while len(base) < at + len(add):
        base.append(0.0)
    for i, s in enumerate(add):
        base[at + i] += s
    return base


def main():
    if len(sys.argv) != 3 or sys.argv[1] not in MOODS:
        print(f"usage: {sys.argv[0]} <boykisser|mlm|yippee> <out.wav>", file=sys.stderr)
        return 1
    cfg = MOODS[sys.argv[1]]
    s = []
    pos = int(0.02 * RATE)
    for base in cfg["yips"]:
        s = mix(s, yip(base), pos)
        pos += int((YIP_LEN + 0.045) * RATE)
    s = mix(s, smack(), pos)
    s = mix(s, mwah(), pos + int(0.08 * RATE))
    pos += int(0.22 * RATE)
    for f in cfg["motif"]:
        s = mix(s, tone(f, int(NOTE_LEN * RATE)), pos)
        pos += int(NOTE_LEN * RATE)
    s += [0.0] * int(TAIL * RATE)
    peak = max(1e-6, max(abs(x) for x in s))
    with wave.open(sys.argv[2], "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(x / peak * 26000)) for x in s))
    print(f"chime: {sys.argv[2]} ({len(s) / RATE:.1f}s, yips + kiss + motif)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
