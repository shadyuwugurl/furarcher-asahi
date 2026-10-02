#!/bin/bash
# verify-asahi.sh - health check for Furarcher on Asahi M1 Air. Read-only (plus 'furassistant prompt' file write).
# Run: curl -fsSL https://raw.githubusercontent.com/shadyuwugurl/furarcher-asahi/main/verify-asahi.sh | bash
# Paste the whole output back for diagnosis.
set -u
PASS=0; FAIL=0; WARN=0
ok(){ echo "PASS: $1"; PASS=$((PASS+1)); }
bad(){ echo "FAIL: $1"; FAIL=$((FAIL+1)); }
warn(){ echo "WARN: $1"; WARN=$((WARN+1)); }

echo "### system"
echo "arch: $(uname -m) | kernel: $(uname -r)"
grep -qi asahi /proc/version 2>/dev/null && ok "Asahi kernel" || bad "Asahi kernel not detected"
grep -E "^(NAME|VERSION)" /etc/os-release 2>/dev/null || true
command -v gnome-session >/dev/null && echo "gnome: $(gnome-session --version)" || echo "gnome: (not installed)"
command -v hyprland >/dev/null && ok "hyprland present" || warn "hyprland not installed (optional)"

echo "### furarcher payload"
for c in furarcher furfetch furassistant ricer; do
  command -v "$c" >/dev/null && ok "$c on PATH ($(command -v "$c"))" || bad "$c missing from PATH"
done

echo "### deps"
for p in curl git fastfetch kitty python3 wal ollama; do
  command -v "$p" >/dev/null && ok "$p" || warn "$p missing"
done

echo "### ollama + model"
if curl -fs -m 5 http://localhost:11434/api/tags >/dev/null 2>&1; then
  ok "ollama serving"
  curl -fs -m 10 http://localhost:11434/api/tags 2>/dev/null | grep -o '"furassistant[^"]*"' | head -3
else
  bad "ollama not serving (start: systemctl --user start ollama)"
fi

echo "### furassistant (safe commands only)"
furassistant status 2>&1 | head -5 || bad "furassistant status crashed"
furassistant ldr 2>&1 | head -8 || warn "ldr failed"
furassistant prompt 2>&1 | head -2 || warn "prompt failed"
furassistant rice status 2>&1 | head -4 || warn "rice status failed"

echo "### timers"
systemctl --user is-enabled furassistant-dream.timer 2>&1 || warn "dream timer not enabled"
systemctl --user is-enabled furassistant-checkin.timer 2>&1 || warn "checkin timer not enabled"

echo "### voice (optional)"
command -v piper >/dev/null || python3 -c "import piper" 2>/dev/null && ok "piper" || warn "piper not installed (optional)"
[ -x "$HOME/.local/bin/whisper-cli" ] && ok "whisper-cli" || warn "whisper-cli not installed (optional)"

echo "=== RESULT: $PASS pass, $FAIL fail, $WARN warn ==="
