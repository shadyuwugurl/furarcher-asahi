#!/bin/bash
# Test ricer with stubbed desktop tools + isolated HOME.
set -u
cd "$(dirname "$0")/.." || exit 1
FAIL=0
pass(){ echo "PASS: $1"; }
fail(){ echo "FAIL: $1"; FAIL=1; }

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

rm -rf "$TESTHOME"
if [ "$FAIL" -eq 0 ]; then echo "ALL RICER CHECKS PASSED"; else echo "SOME RICER CHECKS FAILED"; fi
exit "$FAIL"
