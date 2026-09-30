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
        elif self.path.startswith("/api/v2/neko"):
            body = b'{"results": [{"url": "http://127.0.0.1:11441/tiny.png", "dimensions": {"width": 800, "height": 600}, "artist_name": "stub", "source_url": "http://example.com"}]}'
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
export WALLHAVEN_BASE="http://127.0.0.1:11441" NEKOS_BASE="http://127.0.0.1:11441"
"$R" find neko 2 | grep -q "\[1\] wallhaven" && pass "find wallhaven" || fail "find wallhaven"
"$R" find neko 2 | grep -q "nekos.best 800x600" && pass "find nekos" || fail "find nekos"
"$R" get 1 | grep -q "saved:" && pass "get download" || fail "get download"
[ -f "$TESTHOME/.local/share/backgrounds/tiny.png" ] && pass "get saved" || fail "get saved"
"$R" get 9 >/dev/null 2>&1 && fail "bad index rejected" || pass "bad index rejected"
WALLHAVEN_BASE="http://127.0.0.1:9" NEKOS_BASE="http://127.0.0.1:9" "$R" find fox 2 2>&1 | grep -q "no results" && pass "find graceful" || fail "find graceful"

rm -rf "$TESTHOME"
if [ "$FAIL" -eq 0 ]; then echo "ALL RICER CHECKS PASSED"; else echo "SOME RICER CHECKS FAILED"; fi
exit "$FAIL"
