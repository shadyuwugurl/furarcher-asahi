#!/bin/bash
#
# Furarcher - Asahi Edition (M1 MacBook Air)
# Fork-inspired rework of Nyarcher (https://github.com/NyarchLinux/Nyarcher) for Asahi Linux.
# GPL-3.0 - credit upstream NyarchLinux.
#
# What changed vs upstream nyarcher.sh:
#  - Targets Fedora Asahi Remix (aarch64) with dnf, NOT Arch/pacman/AUR
#  - GNOME mode (stable, recommended) + optional experimental Hyprland mode
#  - Replaces x86_64-only Nyarch flatpak bundles with arch-checked skips
#  - Replaces CatgirlDownloader/WaifuDownloader with SFW furry + neko wallpaper flow (16+/17+ safe, NO NSFW)
#  - Installs to ~/.local/bin (no /usr/bin [SYSTEM] writes)
#  - Theme: furry + femboy + gay pride + neko, SFW only
#
# Tested logic for: M1 MacBook Air (apple,m1), Asahi Fedora Remix, GNOME 46/47, aarch64
# Hyprland on Asahi Apple GPU is EXPERIMENTAL - expect glitches. GNOME is the safe default.
#
set -u

RED='\033[0;31m'; PINK='\033[38;5;212m'; CYAN='\033[0;36m'; NC='\033[0m'
DRY_RUN="false"
AUTO_YES="false"
MODE="gnome"  # gnome | hyprland
MODE_SET="false"
CHECK_ONLY="false"
# Brew installs set FURARCHER_ROOT to the payload dir (symlinked bins break dirname $0)
SCRIPT_DIR="${FURARCHER_ROOT:-$(cd "$(dirname "$0")" && pwd)}"

for arg in "$@"; do
  case "$arg" in
    --hyprland) MODE="hyprland"; MODE_SET="true" ;;
    --gnome) MODE="gnome"; MODE_SET="true" ;;
    --check-only) CHECK_ONLY="true" ;;
    --dry-run) DRY_RUN="true" ;;
    --yes|-y) AUTO_YES="true" ;;
    -h|--help)
      echo "Usage: ./furarcher.sh [--gnome] [--hyprland] [--check-only] [--dry-run] [--yes]"
      echo "  default: --gnome (stable on Asahi M1 Air)"
      echo "  --hyprland: experimental Hyprland path on Asahi"
      echo "  --yes: answer yes to all prompts (for containers/CI)"
      exit 0
      ;;
  esac
done

run() { if [ "$DRY_RUN" = "true" ]; then echo "[dry-run] $*"; else eval "$*"; fi; }
ask() { # ask "prompt" -> returns 0 for yes; AUTO_YES bypasses; EOF = No
  if [ "$AUTO_YES" = "true" ]; then echo "$1 (Y/n): Y [auto-yes]"; return 0; fi
  local prompt="$1" ans
  if ! read -r -p "$prompt (Y/n): " ans; then echo; return 1; fi
  if [ -z "$ans" ]; then return 0; fi
  [[ "$ans" =~ ^([yY][eE][sS]|[yY])$ ]]
}

check_asahi() {
  echo -e "${CYAN}== Asahi / device check ==${NC}"
  echo "arch: $(uname -m)"
  echo "kernel: $(uname -r)"
  if [ "$(uname -m)" != "aarch64" ] && [ "$(uname -m)" != "arm64" ]; then
    echo -e "${RED}WARN: not aarch64. M1 Air needs aarch64 Asahi. Continuing anyway.${NC}"
  fi
  if grep -qi asahi /proc/version 2>/dev/null || [ -f /etc/asahi-release ] || grep -qa apple /proc/device-tree/compatible 2>/dev/null; then
    echo "Asahi/Apple Silicon detected :3"
  else
    echo -e "${RED}WARN: Asahi not detected. This script is tuned for Asahi Fedora Remix on M1 Air.${NC}"
    echo "It will still run on generic Fedora GNOME aarch64, but M1 GPU/audio bits are skipped."
  fi
  if [ -f /etc/os-release ]; then grep -E "^(NAME|VERSION|VARIANT)" /etc/os-release; fi
  if [ "${CHECK_ONLY:-false}" = "true" ]; then exit 0; fi
}

install_deps_asahi() {
  echo -e "${CYAN}Installing deps via dnf (Fedora Asahi)...${NC}"
  # NOTE (verified 2026-09-30 in fedora:41 aarch64 container):
  #  - classic 'wget' is retired on Fedora -> use curl (already listed)
  #  - 'npm' ships as 'nodejs-npm'; 'gnome-shell-extensions' meta does not exist;
  #  - 'polkit-gnome' does not exist -> 'mate-polkit' (hyprland step)
  run "sudo dnf install -y curl flatpak python3-pip gnome-menus kitty git fastfetch nodejs-npm nodejs btop gnome-extensions-app tar wl-clipboard tzdata libnotify"
  run "pip3 install --user pywal"
  # ensure wal on PATH
  if ! command -v wal >/dev/null 2>&1 && [ -f "$HOME/.local/bin/wal" ]; then
    echo "pywal at ~/.local/bin/wal - ensure ~/.local/bin is on PATH"
  fi
}

check_gnome_version_soft() {
  if ! command -v gnome-session >/dev/null 2>&1; then
    echo -e "${RED}gnome-session not found. Install GNOME (Fedora Asahi GNOME remix) or use --hyprland.${NC}"
    return 1
  fi
  local v num major
  v=$(gnome-session --version); num=${v##* }; major=${num%%.*}
  echo "GNOME: $v"
  if [[ "$major" =~ ^[0-9]+$ ]] && [ "$major" -lt 46 ]; then
    echo -e "${RED}GNOME 46+ recommended (47 ideal). Found $v.${NC}"
  fi
}

install_gnome_custom() {
  check_gnome_version_soft || return 1
  echo "Downloading Nyarch base tarball for themes (upstream art)..."
  local url
  url="https://github.com/NyarchLinux/NyarchLinux/releases/latest/download/NyarchLinux.tar.gz"
  run "curl -L -o /tmp/NyarchLinux.tar.gz \"$url\""
  run "cd /tmp && tar -xf NyarchLinux.tar.gz"
  # Extensions backup + copy (best-effort, GNOME version mismatches are common)
  if [ -d "$HOME/.local/share/gnome-shell/extensions" ]; then
    run "mv -f $HOME/.local/share/gnome-shell/extensions $HOME/.local/share/gnome-shell/extensions-backup-furarcher"
  fi
  run "cp -rf /tmp/NyarchLinuxComp/Gnome/etc/skel/.local/share/gnome-shell/extensions $HOME/.local/share/gnome-shell/ || true"
  run "chmod -R 755 $HOME/.local/share/gnome-shell/extensions/* || true"
  echo "Material-You GNOME extension (optional, may fail on version mismatch - safe to skip):"
  if ask "Try building material-you-colors extension"; then
    run "cd /tmp && rm -rf material-you-colors && git clone https://github.com/FrancescoCaracciolo/material-you-colors.git && cd material-you-colors && make build && make install || echo 'material-you build skipped/failed (ok on Asahi)'"
  fi
}

install_furfetch() {
  echo -e "${CYAN}Installing furfetch (SFW) to ~/.local/bin${NC}"
  run "mkdir -p $HOME/.local/bin"
  run "cp -f \"$SCRIPT_DIR/bin/furfetch\" $HOME/.local/bin/furfetch"
  run "chmod +x $HOME/.local/bin/furfetch"
  # keep neko ASCII SFW flavor too
  run "ln -sf $HOME/.local/bin/furfetch $HOME/.local/bin/nekofetch-fur || true"
  echo "Run: ~/.local/bin/furfetch (add ~/.local/bin to PATH if needed)"
}

install_wallpapers_furry_sfw() {
  echo -e "${CYAN}Installing SFW furry/neko wallpapers (local pack, no NSFW fetch)${NC}"
  run "mkdir -p $HOME/.local/share/backgrounds"
  run "cp -rf \"$SCRIPT_DIR/wallpapers/.\" $HOME/.local/share/backgrounds/ || true"
  echo ""
  echo "SFW note: this pack is abstract pride/paw art only."
  echo "To add your friend's own SFW furry art: drop PNG/JPG into ~/.local/share/backgrounds/"
  echo "Optional SFW sources (keep SFW filter ON): nekos.best (neko), yiffyAPI SFW-only endpoints."
  echo "We do NOT install CatgirlDownloader/WaifuDownloader - they pull untagged anime-girl feeds and have x86_64-only builds."
}

install_icons_themes_kitty() {
  echo "Copying GTK themes/icons/kitty from upstream tarball (best-effort)..."
  run "cp -rf /tmp/NyarchLinuxComp/Gnome/etc/skel/.local/share/themes $HOME/.local/share/ || true"
  run "mkdir -p $HOME/.config && cp -rf /tmp/NyarchLinuxComp/Gnome/etc/skel/.config/gtk-3.0 $HOME/.config/ || true"
  run "cp -rf /tmp/NyarchLinuxComp/Gnome/etc/skel/.config/gtk-4.0 $HOME/.config/ || true"
  run "mkdir -p $HOME/.config/kitty && cp -rf /tmp/NyarchLinuxComp/Gnome/etc/skel/.config/kitty/. $HOME/.config/kitty/ || true"
  echo -e "${PINK}Tip for femboy pride vibe:${NC} set Kitty theme to pink/purple in ~/.config/kitty/kitty.conf + pywal (wal -i <wallpaper>)"
}

install_flatpaks_sfw() {
  run "flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"
  # aarch64-safe, SFW creative picks
  run "flatpak install -y flathub org.gtk.Gtk3theme.adw-gtk3 org.gtk.Gtk3theme.adw-gtk3-dark || true"
  run "flatpak install -y flathub com.github.tchx84.Flatseal com.mattjakeman.ExtensionManager org.gnome.Lollypop de.haeckerfelix.Shortwave || true"
  run "flatpak install -y flathub org.kde.Krita org.blender.Blender org.inkscape.Inkscape || echo 'creative apps skipped (ok)'"
  echo "SKIPPED (x86_64-only or untagged feeds): CatgirlDownloader, WaifuDownloader, NyarchUpdater, NyarchWizard/Tour bundles."
  echo "Reason: those flatpak bundles publish x86_64 builds; on M1 aarch64 they fail. Use GNOME Software / Flathub aarch64 builds instead."
}

install_hyprland_asahi_experimental() {
  echo -e "${PINK}== Experimental Hyprland on Asahi (M1 Air) ==${NC}"
  echo "Hyprland = you typed 'hyperland' - this is it (Wayland tiling compositor)."
  echo "Status on Asahi Apple GPU: works for many but glitchy vs GNOME. GNOME stays the stable pick."
  echo "This installs Hyprland from official Fedora repos (0.44+ on F41, verified aarch64)"
  echo " + waybar/wofi/kitty, copies hypr/hyprland.conf tuned for M1 Air 2560x1664."
  if ! ask "Continue with experimental Hyprland install"; then return 0; fi
  run "sudo dnf install -y hyprland waybar wofi kitty foot mate-polkit pipewire wireplumber grim slurp wl-clipboard || echo 'some hypr pkgs missing (ok, partial install)'"
  run "mkdir -p $HOME/.config/hypr"
  run "cp -f \"$SCRIPT_DIR/hypr/hyprland.conf\" $HOME/.config/hypr/hyprland.conf"
  echo "Select Hyprland at login (GDM gear icon). If black screen: switch back to GNOME."
}

configure_gsettings_safe() {
  if [ "$MODE" = "hyprland" ]; then echo "Skipping GNOME dconf load in Hyprland mode."; return 0; fi
  check_gnome_version_soft || return 1
  run "dconf dump / > $HOME/dconf-backup-furarcher.txt"
  echo "Loading upstream GNOME keybindings/theme bits (best-effort)..."
  run "cd /tmp/NyarchLinuxComp/Gnome/etc/dconf/db/local.d && dconf load / < 02-interface || true"
  run "cd /tmp/NyarchLinuxComp/Gnome/etc/dconf/db/local.d && dconf load / < 04-wmpreferences || true"
}

install_furassistant_hook() {
  echo -e "${CYAN}FurAssistant: local Hermes AI (Ollama aarch64 + hermes3:8b, ~5GB download).${NC}"
  echo "Includes chat, auto-research, nightly dreaming, bounded RSI, guarded auto-config. SFW only."
  run "chmod +x \"$SCRIPT_DIR/furassistant/install-furassistant.sh\""
  run "\"$SCRIPT_DIR/furassistant/install-furassistant.sh\""
}

# ---- main ----
echo -e "${PINK}"
echo "  /\  /\  Furarcher - Asahi Edition (M1 Air) ^_^"
echo "  furry + femboy + pride + neko, SFW 16+ only, no NSFW"
echo -e "${NC}"

check_asahi

if [ "$MODE_SET" = "false" ] && [ "$AUTO_YES" = "false" ]; then
  echo "Desktop: [1] GNOME (stable, recommended)  [2] Hyprland (experimental)"
  read -r -p "Pick desktop (1/2, default 1): " _desk
  [ "${_desk:-1}" = "2" ] && MODE="hyprland"
  echo "Going with: $MODE"
fi

if ! ask "Install Fedora Asahi deps with dnf"; then echo "deps skipped"; else install_deps_asahi; fi

if [ "$MODE" = "hyprland" ]; then
  install_hyprland_asahi_experimental
else
  if ask "Install GNOME customizations (extensions/themes, best-effort)"; then install_gnome_custom; fi
fi

if ask "[safe] Install furfetch + SFW neko flavor"; then install_furfetch; fi
if ask "Install SFW furry wallpapers"; then install_wallpapers_furry_sfw; fi
if ask "Install icons/themes/kitty bits"; then install_icons_themes_kitty; fi
if ask "Install SFW flatpaks (aarch64-safe)"; then install_flatpaks_sfw; fi
if ask "Install FurAssistant local AI (Ollama + Hermes, ~5GB)"; then install_furassistant_hook; fi
if ask "Install FurAssistant voice (Piper TTS + whisper STT, ~500MB + short build)"; then
  run "chmod +x \"$SCRIPT_DIR/furassistant/voice/install-voice.sh\""
  run "\"$SCRIPT_DIR/furassistant/voice/install-voice.sh\""
fi
if ask "Apply safe GNOME settings (backup first)"; then configure_gsettings_safe; fi

echo -e "${PINK}Done! Log out/in. Run ~/.local/bin/furfetch. Stay soft, stay proud. <3${NC}"
echo "Push this folder to GitHub as your fork: gh repo create furarcher-asahi --public --source=. --push"
