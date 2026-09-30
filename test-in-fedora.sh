#!/bin/bash
# Container smoke test for Furarcher Asahi Edition
# Runs INSIDE Fedora container (aarch64). Safe: uses --dry-run + temp HOME for real copies.
set -u
cd "$(dirname "$0")" || exit 1
FAIL=0
pass(){ echo "PASS: $1"; }
fail(){ echo "FAIL: $1"; FAIL=1; }

echo "== env =="
uname -m; grep -E "^(NAME|VERSION)" /etc/os-release || true

echo "== 1. syntax =="
bash -n furarcher.sh && bash -n bin/furfetch && pass "bash -n" || fail "bash -n"
command -v shellcheck >/dev/null && { shellcheck -S warning furarcher.sh bin/furfetch && pass "shellcheck" || fail "shellcheck"; } || echo "SKIP shellcheck (not installed)"

echo "== 2. help/check-only =="
./furarcher.sh --help >/dev/null && pass "--help" || fail "--help"
./furarcher.sh --check-only && pass "--check-only" || fail "--check-only"

echo "== 3. dry-run both modes =="
./furarcher.sh --dry-run --yes >/dev/null && pass "dry-run gnome" || fail "dry-run gnome"
./furarcher.sh --hyprland --dry-run --yes >/dev/null && pass "dry-run hyprland" || fail "dry-run hyprland"

echo "== 4. real file ops into temp HOME =="
export TESTHOME
TESTHOME=$(mktemp -d)
printf '1\nn\nn\nY\nY\nn\nn\nn\nn\nn\n' | env HOME="$TESTHOME" ./furarcher.sh >/dev/null 2>&1
[ -x "$TESTHOME/.local/bin/furfetch" ] && pass "furfetch installed" || fail "furfetch installed"
[ -f "$TESTHOME/.local/share/backgrounds/fur-pride-2560x1664.svg" ] && pass "wallpapers installed" || fail "wallpapers installed"
"$TESTHOME/.local/bin/furfetch" >/dev/null 2>&1 && pass "furfetch runs" || fail "furfetch runs"
[ -f "hypr/hyprland.conf" ] && grep -q "eDP-1,2560x1664" hypr/hyprland.conf && pass "hypr conf M1 Air" || fail "hypr conf"
rm -rf "$TESTHOME"

echo "== 5. dnf sanity (no install) =="
if command -v dnf >/dev/null; then
  dnf list fastfetch 2>&1 | head -3 && pass "dnf works" || echo "SKIP dnf list (network/repos)"
else
  echo "SKIP dnf (not Fedora userspace)"
fi

if [ "$FAIL" -eq 0 ]; then echo "ALL CONTAINER CHECKS PASSED"; else echo "SOME CHECKS FAILED"; fi
exit "$FAIL"
