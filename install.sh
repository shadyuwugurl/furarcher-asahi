#!/bin/bash
#
# install.sh - Furarcher Asahi front door (omarchy-style).
# Fresh Asahi Fedora Remix (aarch64, M1 Air) -> riced system in one go.
# Keeps sudo alive, then delegates to furarcher.sh (the Asahi specialist).
#
# Usage: ./install.sh [--gnome] [--hyprland] [--yes] [--dry-run]
#   default: asks everything, like ./furarcher.sh
set -u

cd "$(dirname "$0")" || exit 1

for a in "$@"; do case "$a" in -h|--help)
  echo "Usage: ./install.sh [--gnome] [--hyprland] [--yes] [--dry-run]"
  echo "  Fresh Asahi Fedora Remix -> riced system. Delegates to furarcher.sh."
  exit 0 ;;
esac; done

NEED_SUDO="true"
for a in "$@"; do case "$a" in --dry-run) NEED_SUDO="false" ;; esac; done

if [ "$NEED_SUDO" = "true" ] && ! sudo -v; then
  echo "sudo needed for system packages. Aborting."
  exit 1
fi
keep_sudo_alive() { while true; do sudo -v; sleep 50; done; }
if [ "$NEED_SUDO" = "true" ]; then
  keep_sudo_alive &
  SUDO_PID=$!
  trap 'kill $SUDO_PID 2>/dev/null; sudo -k' EXIT INT TERM
fi

echo "Furarcher Asahi installer ^_^  (payload: $(pwd))"
echo "Layout: bin/ tools | config/ dotfiles | themes/ packs | furassistant/ AI"
chmod +x furarcher.sh bin/ricer bin/furfetch bin/make-themes
./furarcher.sh "$@"
