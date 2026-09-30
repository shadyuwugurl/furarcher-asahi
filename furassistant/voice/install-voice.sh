#!/bin/bash
# Voice installer for FurAssistant (airi-style ears + mouth, local-only)
# - Mouth: Piper TTS (aarch64 wheel) + espeak-ng from dnf
# - Ears: whisper.cpp built from source (tiny.en model, CPU-fine on M1)
set -u
cd "$(dirname "$0")" || exit 1

VOICEDIR="$HOME/.local/share/furassistant/voices"
BINDIR="$HOME/.local/bin"
mkdir -p "$VOICEDIR" "$BINDIR"

echo "== mouth (Piper TTS) =="
sudo dnf install -y espeak-ng || echo "(espeak-ng install failed - piper needs it, continuing)"
pip3 install --user "https://github.com/OHF-Voice/piper1-gpl/releases/download/v1.8.0/piper_tts-1.8.0-cp39-abi3-manylinux_2_17_aarch64.manylinux2014_aarch64.manylinux_2_28_aarch64.whl" \
  || echo "(piper wheel install failed - see README)"

echo "Picking an English voice (auto-discovery)..."
python3 - <<'PYEOF'
import json, os, urllib.request
vd = os.path.expanduser("~/.local/share/furassistant/voices")
picked = []
try:
    rel = json.load(urllib.request.urlopen(
        "https://api.github.com/repos/rhasspy/piper-voices/releases/latest", timeout=30))
    for a in rel.get("assets", []):
        n = a["name"]
        if "en_US-lessac-medium.onnx" in n and n.endswith(".onnx"):
            for f in (n, n + ".json"):
                url = a["browser_download_url"].replace(n, f)
                dst = os.path.join(vd, f)
                if not os.path.exists(dst):
                    print("downloading", f)
                    urllib.request.urlretrieve(url, dst)
            picked = [n]
            break
except Exception as e:
    print("voice auto-discovery failed:", e)
print("VOICE=" + (picked[0] if picked else ""))
PYEOF

echo "== ears (whisper.cpp, source build ~2-5 min on M1) =="
if [ ! -x "$BINDIR/whisper-cli" ]; then
  sudo dnf install -y cmake gcc-c++ git || echo "(build tools install failed)"
  rm -rf /tmp/whisper.cpp
  git clone --depth 1 https://github.com/ggerganov/whisper.cpp.git /tmp/whisper.cpp
  cmake -B /tmp/whisper.cpp/build -S /tmp/whisper.cpp -DCMAKE_BUILD_TYPE=Release
  cmake --build /tmp/whisper.cpp/build -j "$(nproc)" --target whisper-cli
  cp /tmp/whisper.cpp/build/bin/whisper-cli "$BINDIR/" || echo "(whisper-cli copy failed)"
  curl -fsSL -o "$VOICEDIR/ggml-tiny.en.bin" \
    "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.en.bin" \
    || echo "(tiny.en model download failed)"
else
  echo "whisper-cli already present"
fi

echo "Done. Try: furassistant speak \"Ahoj bestie!\" | furassistant listen"
echo "(playback needs aplay/paplay; recording needs pw-record on pipewire)"
