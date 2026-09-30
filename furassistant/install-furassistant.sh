#!/bin/bash
# FurAssistant installer - local AI for Furarcher Asahi (M1 Air)
# Stack: Ollama (aarch64 CPU) + Hermes agent model + furassistant CLI
# Usage: ./install-furassistant.sh [--from MODEL] [--yes] [--skip-model]
#   --from MODEL : base model (default: hermes3:8b, 8GB-safe; 16GB machines: qwen3:14b)
#   --skip-model : install CLI + timers only (model already present / offline)
set -u
cd "$(dirname "$0")" || exit 1

FROM_MODEL="${FURASSISTANT_FROM:-hermes3:8b}"
SKIP_MODEL="false"
PREV=""
for arg in "$@"; do
  if [ "$PREV" = "--from" ]; then FROM_MODEL="$arg"; PREV=""; continue; fi
  case "$arg" in
    --from) PREV="--from" ;;
    --from=*) FROM_MODEL="${arg#--from=}" ;;
    --skip-model) SKIP_MODEL="true" ;;
  esac
done

echo "FurAssistant installer ^_^  (Ollama + Hermes, fully local, SFW)"
echo "arch: $(uname -m) | base model: $FROM_MODEL"

if [ "$(uname -m)" != "aarch64" ] && [ "$(uname -m)" != "arm64" ]; then
  echo "WARN: not ARM64. M1 Air Asahi needs aarch64; continuing anyway."
fi

if ! command -v ollama >/dev/null 2>&1; then
  echo "Installing Ollama (official install.sh, has linux-arm64 builds)..."
  curl -fsSL https://ollama.com/install.sh | sh
else
  echo "Ollama already installed: $(ollama --version 2>/dev/null)"
fi

if [ "$SKIP_MODEL" = "false" ]; then
  echo "Pulling base model (one-time, ~5GB for 8B Q4)..."
  ollama pull "$FROM_MODEL"
  echo "Creating 'furassistant' persona model..."
  ollama create furassistant -f ./Modelfile || {
    echo "Modelfile create failed (hardcoded hermes3:8b). Retrying with $FROM_MODEL..."
    sed "s/^FROM .*/FROM $FROM_MODEL/" ./Modelfile > /tmp/FurModelfile
    ollama create furassistant -f /tmp/FurModelfile
  }
fi

echo "Installing furassistant CLI + skills + personalities to ~/.local/{bin,share}..."
mkdir -p "$HOME/.local/bin"
cp -f ./bin/furassistant "$HOME/.local/bin/furassistant"
chmod +x "$HOME/.local/bin/furassistant"
mkdir -p "$HOME/.local/share/furassistant/skills" "$HOME/.local/share/furassistant/personalities" "$HOME/.local/share/furassistant" "$HOME/.config/furassistant"
cp -rf ./skills/. "$HOME/.local/share/furassistant/skills/"
cp -rf ./personalities/. "$HOME/.local/share/furassistant/personalities/"
cp -f ./data/sk-phrases.md "$HOME/.local/share/furassistant/sk-phrases.md"
[ -f "$HOME/.config/furassistant/ldr.conf" ] || cp -f ./data/ldr.conf.example "$HOME/.config/furassistant/ldr.conf"
chmod +x ./voice/install-voice.sh

echo "Installing nightly dream timer (systemd user)..."
mkdir -p "$HOME/.config/systemd/user"
cp -f ./systemd/furassistant-dream.service ./systemd/furassistant-dream.timer "$HOME/.config/systemd/user/"
cp -f ./systemd/furassistant-checkin.service ./systemd/furassistant-checkin.timer "$HOME/.config/systemd/user/"
if command -v systemctl >/dev/null 2>&1; then
  systemctl --user daemon-reload || true
  systemctl --user enable --now furassistant-dream.timer || echo "(timer enable skipped - ok in containers)"
  systemctl --user enable --now furassistant-checkin.timer || echo "(timer enable skipped - ok in containers)"
fi

echo "Done! Try: furassistant ask \"how do I change my Hyprland wallpaper?\""
echo "Dreaming runs nightly at 03:00, check-ins at 08:00/22:00 via systemd timers."
echo "RSI: furassistant rsi | LDR bridge: furassistant ldr | Voice (opt-in): ./voice/install-voice.sh"
