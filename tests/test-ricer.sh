#!/bin/bash
# Test ricer with stubbed desktop tools + isolated HOME.
set -u
cd "$(dirname "$0")/.." || exit 1
FAIL=0
pass(){ echo "PASS: $1"; }
fail(){ echo "FAIL: $1"; FAIL=1; }

command -v python3 >/dev/null && command -v curl >/dev/null || { echo "SKIP: need python3 + curl"; exit 0; }

export TESTHOME; TESTHOME=$(mktemp -d)
export HOME="$TESTHOME"
STUBBIN="$TESTHOME/stubbin"; mkdir -p "$STUBBIN"
export PATH="$STUBBIN:$PATH"
# stub gsettings + wal that log calls
printf '#!/bin/bash\necho "gsettings $*" >> "$TESTHOME/calls.log"\n' > "$STUBBIN/gsettings"
printf '#!/bin/bash\necho "wal $*" >> "$TESTHOME/calls.log"\n' > "$STUBBIN/wal"
chmod +x "$STUBBIN/gsettings" "$STUBBIN/wal"
R="./bin/ricer"
chmod +x "$R"

echo "fake" > "$TESTHOME/test.png"
mkdir -p "$TESTHOME/.config/hypr" "$TESTHOME/.config/kitty"
echo "# hyprland" > "$TESTHOME/.config/hypr/hyprland.conf"
echo "# kitty" > "$TESTHOME/.config/kitty/kitty.conf"

"$R" apply "$TESTHOME/test.png" pink >/dev/null
[ -f "$TESTHOME/.local/share/backgrounds/test.png" ] && pass "wallpaper copied" || fail "wallpaper copied"
grep -q "ff7ad9" "$TESTHOME/.config/kitty/furarcher-theme.conf" && pass "kitty pink" || fail "kitty pink"
grep -q "rgba(ff7ad9ee)" "$TESTHOME/.config/hypr/furarcher-colors.conf" && pass "hypr pink" || fail "hypr pink"
grep -q "furarcher-colors.conf" "$TESTHOME/.config/hypr/hyprland.conf" && pass "hypr source line" || fail "hypr source line"
grep -q "include furarcher-theme.conf" "$TESTHOME/.config/kitty/kitty.conf" && pass "kitty include" || fail "kitty include"
grep -q "gsettings set org.gnome.desktop.background picture-uri file://" "$TESTHOME/calls.log" && pass "gsettings called" || fail "gsettings called"
grep -q "wal -i" "$TESTHOME/calls.log" && pass "wal on raster" || fail "wal on raster"

"$R" theme purple >/dev/null
grep -q "b28dff" "$TESTHOME/.config/kitty/furarcher-theme.conf" && pass "theme switch" || fail "theme switch"

"$R" theme bogus >/dev/null 2>&1 && fail "bad theme rejected" || pass "bad theme rejected"
"$R" wallpaper /nope.png >/dev/null 2>&1 && fail "missing img rejected" || pass "missing img rejected"

"$R" status | grep -q "mood\|DE:" && pass "status" || fail "status"

rm -rf "$TESTHOME/.local"
"$R" apply "$TESTHOME/test.png" ocean --dry-run >/dev/null
[ ! -d "$TESTHOME/.local" ] && pass "dry-run clean" || fail "dry-run clean"

# --- find/get via local stub APIs (offline-safe) ---
mkdir -p "$TESTHOME/stubwww"
python3 - "$TESTHOME/stubwww" <<'PYEOF' > /dev/null 2>&1 &
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
root = sys.argv[1]
open(root + "/tiny.png", "wb").write(bytes.fromhex(
    "89504e470d0a1a0a0000000d4948445200000001000000010802000000907753de"
    "0000000c4944415478da6360000000020001e221bc330000000049454e44ae426082"))
class H(BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def do_GET(self):
        if self.path.startswith("/api/v1/search"):
            body = b'{"data": [{"id": "ab12cd", "path": "http://127.0.0.1:11441/tiny.png", "dimension_x": 1920, "dimension_y": 1080}], "meta": {"total": 1}}'
        elif self.path.startswith("/api/v2/"):
            body = b'{"results": [{"url": "http://127.0.0.1:11441/tiny.png", "dimensions": {"width": 800, "height": 600}, "artist_name": "stub", "source_url": "http://example.com"}]}'
        elif self.path.startswith("/search/"):
            body = b'{"images": [{"image_id": 4242, "url": "http://127.0.0.1:11441/tiny.png", "width": 1280, "height": 720, "source": "stub-waifu"}]}'
        elif "page=dapi" in self.path:
            body = b'[{"id": 777, "file_url": "http://127.0.0.1:11441/tiny.png", "sample_url": "http://127.0.0.1:11441/tiny.png", "width": 1600, "height": 900}]'
        elif self.path.startswith("/v1/images/"):
            body = b'{"results": [{"id": "ov-stub-1", "url": "http://127.0.0.1:11441/tiny.png", "width": 1024, "height": 768, "license": "by", "provider": "stub-flickr"}]}'
        elif self.path == "/tiny.png":
            body = open(root + "/tiny.png", "rb").read()
        else:
            self.send_response(404); self.end_headers(); return
        self.send_response(200); self.send_header("Content-Length", str(len(body))); self.end_headers()
        self.wfile.write(body)
HTTPServer(("127.0.0.1", 11441), H).serve_forever()
PYEOF
STUBAPI=$!
trap 'kill $STUBAPI 2>/dev/null; wait $STUBAPI 2>/dev/null; rm -rf "$TESTHOME"' EXIT
sleep 1
export WALLHAVEN_BASE="http://127.0.0.1:11441" NEKOS_BASE="http://127.0.0.1:11441" WAIFU_BASE="http://127.0.0.1:11441" SAFEBOORU_BASE="http://127.0.0.1:11441" OPENVERSE_BASE="http://127.0.0.1:11441"
"$R" find neko 2 | grep -q "\[1\] wallhaven" && pass "find wallhaven" || fail "find wallhaven"
"$R" find neko 2 | grep -q "nekos.best 800x600" && pass "find nekos" || fail "find nekos"
"$R" find neko 2 | grep -q "waifu.im 1280x720" && pass "find waifu" || fail "find waifu"
"$R" find neko 2 | grep -q "safebooru 1600x900" && pass "find safebooru" || fail "find safebooru"
"$R" find neko 2 | grep -q "openverse 1024x768" && pass "find openverse" || fail "find openverse"
"$R" find mlm 2 --source=nekos | grep -q "nekos.best" && pass "find mlm nekos route" || fail "find mlm nekos route"
"$R" find furry 2 --source=nekos | grep -q "nekos.best" && pass "find furry nekos route" || fail "find furry nekos route"
"$R" find pastel 2 --source=wallhaven | grep -q "wallhaven" && pass "find source wallhaven" || fail "find source wallhaven"
"$R" find neko 2 --source=waifu | grep -q "waifu.im" && pass "find source waifu" || fail "find source waifu"
"$R" get 1 | grep -q "saved:" && pass "get download" || fail "get download"
[ -f "$TESTHOME/.local/share/backgrounds/tiny.png" ] && pass "get saved" || fail "get saved"
"$R" preview 1 | grep -q "http" && pass "preview url" || fail "preview url"
"$R" fetch-pack boykisser 2 2>&1 | grep -q "pack:" && pass "fetch-pack" || fail "fetch-pack"
"$R" fetch-pack bogus 2 >/dev/null 2>&1 && fail "bad pack rejected" || pass "bad pack rejected"
rm -f "$TESTHOME/.local/share/backgrounds/test.png"
"$R" apply "$TESTHOME/test.png" pink --dry-run >/dev/null
[ ! -f "$TESTHOME/.local/share/backgrounds/test.png" ] && pass "apply dry-run clean" || fail "apply dry-run clean"
"$R" auto --dry-run 2>&1 | grep -q "auto-riced" && pass "auto flag-first" || fail "auto flag-first"
"$R" get 9 >/dev/null 2>&1 && fail "bad index rejected" || pass "bad index rejected"
WALLHAVEN_BASE="http://127.0.0.1:9" NEKOS_BASE="http://127.0.0.1:9" WAIFU_BASE="http://127.0.0.1:9" SAFEBOORU_BASE="http://127.0.0.1:9" OPENVERSE_BASE="http://127.0.0.1:9" "$R" find fox 2 2>&1 | grep -q "no results" && pass "find graceful" || fail "find graceful"
"$R" fetch-pack gaylove 2 --apply-first >/dev/null 2>&1 && grep -q "ff9e5e" "$TESTHOME/.config/kitty/furarcher-theme.conf" && pass "fetch-pack gaylove apply-first (honey)" || fail "fetch-pack gaylove apply-first (honey)"
"$R" auto boykisser 2>&1 | grep -q "auto-riced" && pass "auto boykisser" || fail "auto boykisser"
"$R" auto gaylove 2>&1 | grep -q "auto-riced" && grep -q "ff9e5e" "$TESTHOME/.config/kitty/furarcher-theme.conf" && pass "auto gaylove honey" || fail "auto gaylove honey"
"$R" auto bogus >/dev/null 2>&1 && fail "bad auto rejected" || pass "bad auto rejected"
WALLHAVEN_BASE="http://127.0.0.1:9" NEKOS_BASE="http://127.0.0.1:9" WAIFU_BASE="http://127.0.0.1:9" SAFEBOORU_BASE="http://127.0.0.1:9" OPENVERSE_BASE="http://127.0.0.1:9" "$R" auto furry 2>&1 | grep -q "fallback" && pass "auto offline fallback" || fail "auto offline fallback"

"$R" theme boykisser >/dev/null && grep -q "ff7ad9" "$TESTHOME/.config/kitty/furarcher-theme.conf" && pass "boykisser theme" || fail "boykisser theme"
"$R" darkmode >/dev/null && pass "darkmode" || fail "darkmode"
"$R" dock >/dev/null && [ -f "$TESTHOME/.config/waybar/furarcher-top.jsonc" ] && [ -f "$TESTHOME/.config/waybar/furarcher-dock.jsonc" ] && pass "dock configs" || fail "dock configs"
grep -q "kitty-furarcher.conf" "$TESTHOME/.config/kitty/kitty.conf" && pass "kitty love include" || fail "kitty love include"
"$R" macbinds >/dev/null && grep -q "SUPER, Space" "$TESTHOME/.config/hypr/hyprland.conf" && pass "macbinds" || fail "macbinds"
grep -q "SUPER SHIFT, 3" "$TESTHOME/.config/hypr/hyprland.conf" && pass "mac shots" || fail "mac shots"
grep -q "CTRL SUPER, Q" "$TESTHOME/.config/hypr/hyprland.conf" && pass "mac lock" || fail "mac lock"
grep -q "SUPER ALT, Escape" "$TESTHOME/.config/hypr/hyprland.conf" && pass "mac force-quit" || fail "mac force-quit"
grep -q "switch-applications" "$TESTHOME/calls.log" && pass "gnome cmd-tab" || fail "gnome cmd-tab"
grep -q "area-screenshot" "$TESTHOME/calls.log" && pass "gnome mac shots" || fail "gnome mac shots"
grep -q "map super+c copy_to_clipboard" "$TESTHOME/.config/kitty/kitty-furarcher.conf" && pass "kitty mac keys" || fail "kitty mac keys"
"$R" mactheme --dry-run >/dev/null 2>&1 && fail "mactheme dry-run writes" || pass "mactheme dry-run safe"
[ ! -d "$TESTHOME/.themes" ] && pass "mactheme no writes" || fail "mactheme no writes"
"$R" gpu 2>&1 | grep -q "ANE" && pass "gpu status" || fail "gpu status"
"$R" themes | grep -q "mlm" && pass "themes list mlm" || fail "themes list mlm"
for t in mlm achillean bear honey midnight paw furry gay femboy; do
  "$R" theme "$t" >/dev/null 2>&1 && pass "theme $t" || fail "theme $t"
done
"$R" wallpapers | grep -q "boykisser-mlm" && pass "wallpapers list" || fail "wallpapers list"
"$R" mood mlm >/dev/null && grep -q "078d70" "$TESTHOME/.config/kitty/furarcher-theme.conf" && pass "mood mlm" || fail "mood mlm"
"$R" mood gaylove >/dev/null && grep -q "ff9e5e" "$TESTHOME/.config/kitty/furarcher-theme.conf" && pass "mood gaylove" || fail "mood gaylove"
"$R" mood furry >/dev/null && pass "mood furry" || fail "mood furry"
"$R" mood bogus >/dev/null 2>&1 && fail "bad mood rejected" || pass "bad mood rejected"
"$R" love mlm | grep -qi "men loving men" && pass "love mlm" || fail "love mlm"
"$R" love gaylove | grep -qi "gay love" && pass "love gaylove" || fail "love gaylove"
"$R" love furry | grep -qi "furry" && pass "love furry" || fail "love furry"
"./bin/furfetch" mlm >/dev/null 2>&1 && pass "furfetch mlm" || fail "furfetch mlm"
"./bin/furfetch" gaylove >/dev/null 2>&1 && pass "furfetch gaylove" || fail "furfetch gaylove"

# --- boot: chime/grub/splash (stubbed sudo/system services, isolated HOME) ---
printf '#!/bin/bash\necho "sudo $*" >> "$TESTHOME/calls.log"\n' > "$STUBBIN/sudo"
printf '#!/bin/bash\necho "systemctl $*" >> "$TESTHOME/calls.log"\n' > "$STUBBIN/systemctl"
printf '#!/bin/bash\necho "ffplay $*" >> "$TESTHOME/calls.log"\n' > "$STUBBIN/ffplay"
printf '#!/bin/bash\necho "grub2-mkconfig $*" >> "$TESTHOME/calls.log"\n' > "$STUBBIN/grub2-mkconfig"
printf '#!/bin/bash\nif [ $# -eq 0 ]; then echo spinner; else echo "plymouth-set-default-theme $*" >> "$TESTHOME/calls.log"; fi\n' > "$STUBBIN/plymouth-set-default-theme"
chmod +x "$STUBBIN/sudo" "$STUBBIN/systemctl" "$STUBBIN/ffplay" "$STUBBIN/grub2-mkconfig" "$STUBBIN/plymouth-set-default-theme"
export PLYMOUTH_THEMES_DIR="$TESTHOME/themes"
mkdir -p "$PLYMOUTH_THEMES_DIR/spinner"
echo "fake" > "$PLYMOUTH_THEMES_DIR/spinner/watermark.png"

python3 sounds/make-chime.py boykisser "$TESTHOME/c1.wav" && pass "chime synth" || fail "chime synth"
python3 -c "import wave; w=wave.open('$TESTHOME/c1.wav'); assert w.getframerate()==44100 and w.getnframes()>0" && pass "chime wav valid" || fail "chime wav valid"
python3 - "$TESTHOME/c1.wav" <<'PYEOF' && pass "chime has kiss" || fail "chime has kiss"
import struct, sys, wave
w = wave.open(sys.argv[1]); n = w.getnframes(); rate = w.getframerate()
x = [v / 32768 for v in struct.unpack(f'<{n}h', w.readframes(n))]
def zcr(a):
    return sum(1 for i in range(1, len(a)) if (a[i] >= 0) != (a[i-1] >= 0)) / len(a)
smack = x[int(0.02*rate):int(0.12*rate)]
motif = x[int(0.60*rate):int(0.90*rate)]
assert 0.15 < zcr(smack) < 0.60 and zcr(motif) < 0.10 and max(abs(v) for v in x) <= 1.0
PYEOF
python3 sounds/make-chime.py bogus "$TESTHOME/c2.wav" >/dev/null 2>&1 && fail "bad chime mood rejected" || pass "bad chime mood rejected"
"$R" chime bogus >/dev/null 2>&1 && fail "bad chime rejected" || pass "bad chime rejected"
"$R" chime boykisser >/dev/null && pass "chime install" || fail "chime install"
[ -f "$TESTHOME/.local/share/sounds/furarcher-chime-boykisser.wav" ] && pass "chime wav saved" || fail "chime wav saved"
grep -q "ExecStart=.*ffplay" "$TESTHOME/.config/systemd/user/furarcher-chime.service" && pass "chime unit" || fail "chime unit"
grep -q "systemctl --user enable" "$TESTHOME/calls.log" && pass "chime enabled" || fail "chime enabled"
"$R" chime off >/dev/null && pass "chime off" || fail "chime off"
grep -q "ModuleName=two-step" plymouth/furarcher.plymouth && pass "plymouth theme file" || fail "plymouth theme file"
grep -q "0xff7ad9" plymouth/furarcher.plymouth && pass "plymouth pink" || fail "plymouth pink"
"$R" grub bogus >/dev/null 2>&1 && fail "bad grub rejected" || pass "bad grub rejected"
"$R" grub boykisser >/dev/null && pass "grub flow" || fail "grub flow"
[ -f "$TESTHOME/.local/share/furarcher/grub-bg.png" ] && pass "grub png rendered" || fail "grub png rendered"
grep -q "grub2-mkconfig" "$TESTHOME/calls.log" && pass "grub mkconfig" || fail "grub mkconfig"
"$R" grub restore >/dev/null && pass "grub restore" || fail "grub restore"
"$R" splash bogus >/dev/null 2>&1 && fail "bad splash rejected" || pass "bad splash rejected"
"$R" splash boykisser >/dev/null && pass "splash flow" || fail "splash flow"
[ -f "$TESTHOME/.local/share/furarcher/splash-watermark.png" ] && pass "splash png rendered" || fail "splash png rendered"
grep -q "plymouth-set-default-theme -R furarcher" "$TESTHOME/calls.log" && pass "splash set" || fail "splash set"
"$R" splash restore >/dev/null && pass "splash restore" || fail "splash restore"
"$R" status | grep -q "chime:" && pass "status boot lines" || fail "status boot lines"
rm -f "$TESTHOME/.local/share/furarcher/grub-bg.png"
"$R" grub boykisser --dry-run >/dev/null
[ ! -f "$TESTHOME/.local/share/furarcher/grub-bg.png" ] && pass "grub dry-run clean" || fail "grub dry-run clean"

rm -rf "$TESTHOME"
if [ "$FAIL" -eq 0 ]; then echo "ALL RICER CHECKS PASSED"; else echo "SOME RICER CHECKS FAILED"; fi
exit "$FAIL"
