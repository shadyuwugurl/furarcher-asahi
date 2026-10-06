#!/bin/bash
# Test macrice with stubbed macOS tools + isolated HOME. Never touches real defaults.
set -u
cd "$(dirname "$0")/.." || exit 1
FAIL=0
pass(){ echo "PASS: $1"; }
fail(){ echo "FAIL: $1"; FAIL=1; }

command -v python3 >/dev/null || { echo "SKIP: need python3"; exit 0; }
[ "$(uname)" = "Darwin" ] || { echo "SKIP: macrice tests run on macOS only"; exit 0; }

export TESTHOME; TESTHOME=$(mktemp -d)
STUBBIN="$TESTHOME/stubbin"; mkdir -p "$STUBBIN"
trap 'rm -rf "$TESTHOME"' EXIT

# linux-uname overlay for refusal test
LINUXBIN="$TESTHOME/linuxbin"; mkdir -p "$LINUXBIN"
printf '#!/bin/bash\necho Linux\n' > "$LINUXBIN/uname"
chmod +x "$LINUXBIN/uname"

cat > "$STUBBIN/defaults" <<EOF
#!/bin/bash
LOG="$TESTHOME/calls.log"
if [ "\$1" = "export" ]; then mkdir -p "\$(dirname "\$3")"; touch "\$3"; exit 0; fi
if [ "\$1" = "read" ]; then
  case "\$3" in
    AppleInterfaceStyle) echo Dark ;;
    AppleAccentColor) echo 6 ;;
    *) echo "stub-val" ;;
  esac
  exit 0
fi
echo "defaults \$*" >> "\$LOG"
EOF
cat > "$STUBBIN/sips" <<EOF
#!/bin/bash
touch "\$6"
echo "sips \$*" >> "$TESTHOME/calls.log"
EOF
for c in osascript afplay launchctl killall sudo nvram ricer; do
  printf '#!/bin/bash\necho "%s $*" >> "$TESTHOME/calls.log"\n' "$c" > "$STUBBIN/$c"
done
printf '#!/bin/bash\nexit 0\n' > "$STUBBIN/kitty"
chmod +x "$STUBBIN"/*
export PATH="$STUBBIN:$PATH"

M="./macos/macrice.sh"
chmod +x "$M"

# 1. refuses non-Darwin
PATH="$LINUXBIN:$PATH" HOME="$TESTHOME" "$M" --check-only >/dev/null 2>&1 \
  && fail "linux refused" || pass "linux refused"
PATH="$LINUXBIN:$PATH" HOME="$TESTHOME" "$M" 2>&1 | grep -q "macOS only" \
  && pass "refusal message" || fail "refusal message"

export HOME="$TESTHOME"
# 2. help / args
"$M" --help >/dev/null 2>&1 && pass "help" || fail "help"
"$M" bogus >/dev/null 2>&1 && fail "bogus rejected" || pass "bogus rejected"
"$M" mlm --check-only | grep -q "mood: mlm" && pass "mood flag" || fail "mood flag"
"$M" --check-only | grep -q "dark:" && pass "check-only" || fail "check-only"

# 3. dry-run writes nothing
"$M" mlm --dry-run --yes >/dev/null 2>&1
[ ! -d "$TESTHOME/.local" ] && [ ! -d "$TESTHOME/Library" ] && pass "dry-run clean" || fail "dry-run clean"

# 4. full apply (stubbed tools, isolated HOME)
mkdir -p "$TESTHOME/.config/kitty"
echo "# kitty" > "$TESTHOME/.config/kitty/kitty.conf"
"$M" mlm --yes >/dev/null 2>&1 || fail "apply exit"
[ -f "$TESTHOME/.local/share/furarcher/mac-backup/NSGlobalDomain.plist" ] && pass "backup nsglobal" || fail "backup nsglobal"
[ -f "$TESTHOME/.local/share/furarcher/mac-backup/com.apple.dock.plist" ] && pass "backup dock" || fail "backup dock"
[ -f "$TESTHOME/.local/share/backgrounds/mac-mlm.png" ] && pass "wallpaper rendered" || fail "wallpaper rendered"
grep -q "System Events" "$TESTHOME/calls.log" && pass "dark osascript" || fail "dark osascript"
grep -q "AppleAccentColor" "$TESTHOME/calls.log" && pass "pink accent" || fail "pink accent"
grep -q "show-recents" "$TESTHOME/calls.log" && pass "dock tweaks" || fail "dock tweaks"
grep -q "KeyRepeat" "$TESTHOME/calls.log" && pass "key feel" || fail "key feel"
grep -q "screencapture location" "$TESTHOME/calls.log" && pass "shots prefs" || fail "shots prefs"
[ -f "$TESTHOME/Library/LaunchAgents/furarcher-chime.plist" ] && pass "chime agent" || fail "chime agent"
grep -q "afplay" "$TESTHOME/Library/LaunchAgents/furarcher-chime.plist" && pass "chime afplay" || fail "chime afplay"
[ -f "$TESTHOME/.local/share/sounds/furarcher-chime-mlm.wav" ] && pass "chime wav" || fail "chime wav"
grep -q "include kitty-furarcher.conf" "$TESTHOME/.config/kitty/kitty.conf" && pass "kitty include" || fail "kitty include"
grep -q "sudo nvram StartupMute" "$TESTHOME/calls.log" && pass "nvram mute path" || fail "nvram mute path"

# 5. restore
"$M" --restore >/dev/null 2>&1 && pass "restore exit" || fail "restore exit"
grep -q "defaults import" "$TESTHOME/calls.log" && pass "restore imports" || fail "restore imports"

rm -rf "$TESTHOME"
if [ "$FAIL" -eq 0 ]; then echo "ALL MACRICE CHECKS PASSED"; else echo "SOME MACRICE CHECKS FAILED"; fi
exit "$FAIL"
