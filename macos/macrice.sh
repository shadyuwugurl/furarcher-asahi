#!/bin/bash
#
# macrice - Furarcher macOS rice (Apple Silicon Macs, user-scope only, no SIP issues)
# Applies the boykisser/mlm/furry/femboy dark setup to the macOS side of the
# dual-boot: wallpaper, dark mode, pink accent, Dock, Finder, key/trackpad
# feel, screenshots, login chime, kitty. Keybinds need no work: macOS already
# uses Cmd keys natively (this script only aligns repeat/scroll/tap feel).
#
# Firmware honesty: the boot Apple logo and the built-in startup chime live in
# Apple firmware and CANNOT be replaced. This script can only mute/unmute the
# chime (sudo nvram, opt-in) and theme everything after login.
#
# Usage: ./macrice.sh [mood] [--dry-run] [--yes] [--check-only] [--restore]
#   mood: boykisser|mlm|furry|femboy|gaylove|midnight|bear|achillean (default boykisser)
set -u

if [ "$(uname)" != "Darwin" ]; then
  echo "macrice runs on macOS only (found $(uname)). On Asahi use ./furarcher.sh / ricer."
  exit 1
fi

ROOT="${FURARCHER_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
MOOD="boykisser"
DRY="false"; YES="false"; CHECK="false"; RESTORE="false"
for a in "$@"; do case "$a" in
  --dry-run) DRY="true" ;;
  --yes|-y) YES="true" ;;
  --check-only) CHECK="true" ;;
  --restore) RESTORE="true" ;;
  boykisser|mlm|furry|femboy|gaylove|midnight|bear|achillean) MOOD="$a" ;;
  -h|--help) sed -n '2,14p' "$0"; exit 0 ;;
  *) echo "unknown arg: $a (see --help)"; exit 1 ;;
esac; done

BACKUP="$HOME/.local/share/furarcher/mac-backup"
run() { if [ "$DRY" = "true" ]; then echo "[dry-run] $*"; else eval "$*"; fi; }
ask() {
  if [ "$YES" = "true" ]; then echo "$1 (Y/n): Y [auto-yes]"; return 0; fi
  local ans
  if ! read -r -p "$1 (Y/n): " ans; then echo; return 1; fi
  [ -z "$ans" ] && return 0
  [[ "$ans" =~ ^([yY][eE][sS]|[yY])$ ]]
}

mood_svg() {
  case "$1" in
    boykisser|midnight) echo "$ROOT/wallpapers/boykisser-dark-2560x1664.svg" ;;
    mlm|achillean) echo "$ROOT/wallpapers/boykisser-mlm-2560x1664.svg" ;;
    furry|bear) echo "$ROOT/wallpapers/furry-paws-night-2560x1664.svg" ;;
    femboy) echo "$ROOT/wallpapers/fur-pride-2560x1664.svg" ;;
    gaylove) echo "$ROOT/wallpapers/gaylove-sunset-2560x1664.svg" ;;
  esac
}

do_backup() {
  run "mkdir -p \"$BACKUP\""
  for d in NSGlobalDomain com.apple.dock com.apple.finder com.apple.screencapture com.apple.AppleMultitouchTrackpad; do
    run "defaults export \"$d\" \"$BACKUP/$d.plist\" || true"
  done
  echo "backup: $BACKUP (*.plist, restore with --restore)"
}

do_restore() {
  [ -d "$BACKUP" ] || { echo "no backup at $BACKUP"; return 1; }
  for f in "$BACKUP"/*.plist; do
    [ -f "$f" ] || continue
    d="$(basename "$f" .plist)"
    run "defaults import \"$d\" \"$f\" || true"
  done
  run "killall Dock Finder SystemUIServer 2>/dev/null || true"
  echo "restored macOS defaults from $BACKUP (some need logout)"
}

do_check() {
  echo "mood: $MOOD | svg: $(mood_svg "$MOOD")"
  echo "dark: $(defaults read -g AppleInterfaceStyle 2>/dev/null || echo Light)"
  echo "accent: $(defaults read -g AppleAccentColor 2>/dev/null || echo '(default blue)')"
  echo "dock: size=$(defaults read com.apple.dock tilesize 2>/dev/null) autohide=$(defaults read com.apple.dock autohide 2>/dev/null) recents=$(defaults read com.apple.dock show-recents 2>/dev/null)"
  echo "keyrepeat: $(defaults read -g KeyRepeat 2>&1 | head -1) hold-to-repeat-off=$(defaults read -g ApplePressAndHoldEnabled 2>&1 | head -1)"
  echo "tap-to-click: $(defaults read com.apple.AppleMultitouchTrackpad Clicking 2>&1 | head -1)"
  echo "shots: $(defaults read com.apple.screencapture location 2>/dev/null || echo '(default Desktop)')"
  echo "chime-agent: $(launchctl list 2>/dev/null | grep -c furarcher-chime || true) loaded"
  echo "nvram chime: $(nvram StartupMute 2>/dev/null || echo '(requires sudo to read)')"
}

do_dark_accent() {
  echo "== dark mode + pink accent =="
  run "osascript -e 'tell application \"System Events\" to tell appearance preferences to set dark mode to true' 2>/dev/null || defaults write -g AppleInterfaceStyle -string Dark"
  # Pink = 6 in community-verified mapping; backup covers revert (see --restore)
  run "defaults write -g AppleAccentColor -int 6"
  echo "dark + pink accent (verify: System Settings > Appearance)"
}

do_wallpaper() {
  echo "== wallpaper ($MOOD) =="
  run "mkdir -p \"$HOME/.local/share/backgrounds\""
  png="$HOME/.local/share/backgrounds/mac-$MOOD.png"
  run "sips -s format png \"$(mood_svg "$MOOD")\" --out \"$png\" >/dev/null"
  [ "$DRY" = "true" ] || [ -f "$png" ] || { echo "wallpaper render failed"; return 1; }
  run "osascript -e 'tell application \"System Events\" to set picture of every desktop to \"$png\"'"
  echo "wallpaper: $png"
}

do_dock() {
  echo "== Dock (behavior only, your apps untouched) =="
  run "defaults write com.apple.dock tilesize -int 48"
  run "defaults write com.apple.dock magnification -bool false"
  run "defaults write com.apple.dock mineffect -string genie"
  run "defaults write com.apple.dock minimize-to-application -bool false"
  run "defaults write com.apple.dock show-recents -bool false"
  run "defaults write com.apple.dock autohide -bool false"
  run "defaults write com.apple.dock orientation -string bottom"
  run "killall Dock 2>/dev/null || true"
}

do_finder() {
  echo "== Finder =="
  run "defaults write -g AppleShowAllExtensions -bool true"
  run "defaults write com.apple.finder ShowPathbar -bool true"
  run "defaults write com.apple.finder ShowStatusBar -bool true"
  run "killall Finder 2>/dev/null || true"
}

do_input() {
  echo "== keys + trackpad (mac feel, matches Asahi side) =="
  run "defaults write -g KeyRepeat -int 2"
  run "defaults write -g InitialKeyRepeat -int 15"
  run "defaults write -g ApplePressAndHoldEnabled -bool false"
  run "defaults write -g com.apple.swipescrolldirection -bool true"
  run "defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true"
  run "defaults write -g com.apple.mouse.tapBehavior -int 1"
}

do_shots() {
  echo "== screenshots =="
  run "mkdir -p \"$HOME/Pictures\""
  run "defaults write com.apple.screencapture location \"$HOME/Pictures\""
  run "defaults write com.apple.screencapture type -string png"
  run "defaults write com.apple.screencapture disable-shadow -bool true"
  run "killall SystemUIServer 2>/dev/null || true"
}

do_chime() {
  echo "== login chime ($MOOD, afplay LaunchAgent) =="
  run "mkdir -p \"$HOME/.local/share/sounds\" \"$HOME/Library/LaunchAgents\""
  m="$MOOD"; case "$m" in boykisser|mlm) ;; *) m="boykisser" ;; esac
  wav="$HOME/.local/share/sounds/furarcher-chime-$m.wav"
  run "python3 \"$ROOT/sounds/make-chime.py\" \"$m\" \"$wav\"" || return 1
  run "cat > \"$HOME/Library/LaunchAgents/furarcher-chime.plist\" <<EOF
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\"><dict>
<key>Label</key><string>furarcher-chime</string>
<key>ProgramArguments</key><array><string>/usr/bin/afplay</string><string>$wav</string></array>
<key>RunAtLoad</key><true/>
</dict></plist>
EOF"
  run "launchctl bootstrap gui/$(id -u) \"$HOME/Library/LaunchAgents/furarcher-chime.plist\" 2>/dev/null || launchctl load \"$HOME/Library/LaunchAgents/furarcher-chime.plist\" 2>/dev/null || true"
  if [ "$DRY" != "true" ] && [ -f "$wav" ]; then run "afplay \"$wav\" || true"; fi
  echo "chime plays at every login (remove: rm LaunchAgent + bootout)"
}

do_kitty() {
  echo "== kitty (if present) =="
  if [ -d "$HOME/.config/kitty" ] || command -v kitty >/dev/null 2>&1; then
    run "mkdir -p \"$HOME/.config/kitty\""
    run "cp -f \"$ROOT/hypr/kitty-furarcher.conf\" \"$HOME/.config/kitty/\""
    if [ -f "$HOME/.config/kitty/kitty.conf" ] && ! grep -q "kitty-furarcher.conf" "$HOME/.config/kitty/kitty.conf" 2>/dev/null; then
      run "echo 'include kitty-furarcher.conf' >> \"$HOME/.config/kitty/kitty.conf\""
    fi
    if command -v ricer >/dev/null 2>&1; then run "ricer theme boykisser || true"; fi
  else
    echo "(kitty not found - skipping; brew install --cask kitty)"
  fi
}

do_nvram_chime() {
  echo "The built-in startup chime file cannot be replaced (firmware)."
  if ask "Mute it instead (sudo nvram StartupMute)?"; then
    run "sudo nvram StartupMute=%01"
    echo "(unmute later: sudo nvram StartupMute=%00)"
  fi
}

if [ "$RESTORE" = "true" ]; then do_restore; exit "$?"; fi
if [ "$CHECK" = "true" ]; then do_check; exit 0; fi

echo "macrice ^_^  mood=$MOOD (macOS $(sw_vers -productVersion))"
do_backup
if ask "Dark mode + pink accent"; then do_dark_accent; fi
if ask "Boykisser wallpaper ($MOOD)"; then do_wallpaper; fi
if ask "Dock behavior (apps untouched)"; then do_dock; fi
if ask "Finder bits"; then do_finder; fi
if ask "Key/trackpad feel"; then do_input; fi
if ask "Screenshot prefs"; then do_shots; fi
if ask "Login chime ($MOOD)"; then do_chime; fi
if ask "Kitty theme (if installed)"; then do_kitty; fi
if ask "Mac startup chime options"; then do_nvram_chime; fi
echo "done <3  (revert anytime: ./macos/macrice.sh --restore)"
