# Furarcher - Asahi Edition (M1 MacBook Air)

SFW rework inspired by [Nyarcher](https://github.com/NyarchLinux/Nyarcher) (GPL-3.0, credit NyarchLinux).
Centered on **boykisser + gay boys + furries + femboys + neko**, dark mode only. **SFW only, 16+/17+ safe, no NSFW.**

> I could not auto-fork to your GitHub (no auth in this session). This folder is fork-ready — push it as below.

## Quick start on Asahi Fedora Remix (M1 Air)

Via Homebrew (recommended — no clone needed):

```bash
brew tap shadyuwugurl/furarcher-asahi
brew trust --formula shadyuwugurl/furarcher-asahi/furarcher-asahi  # Linux only, one-time
brew install furarcher-asahi
furarcher --check-only   # sanity check
furarcher                # interactive: pick GNOME or Hyprland
furarcher --gnome        # stable (recommended)
furarcher --hyprland     # Hyprland on Asahi
ricer auto boykisser     # fully automatic web rice
```

From a git clone instead:

```bash
git clone https://github.com/shadyuwugurl/furarcher-asahi.git
cd furarcher-asahi
chmod +x furarcher.sh bin/furfetch
./furarcher.sh --check-only   # sanity check
./furarcher.sh                # interactive: pick GNOME or Hyprland
./furarcher.sh --gnome        # stable (recommended)
./furarcher.sh --hyprland     # Hyprland on Asahi
```

## macOS side (same Mac, booted to macOS)

`macos/macrice.sh` rices macOS itself — user-scope only, no SIP issues, full
backup + `--restore`. Keybinds need no work (macOS is already Cmd-native).

```bash
./macos/macrice.sh mlm --check-only  # read-only: shows current settings
./macos/macrice.sh mlm --dry-run     # prints every change, writes nothing
./macos/macrice.sh boykisser         # interactive apply (asks per section)
```

Applies: dark mode + pink accent, boykisser wallpaper (sips-rendered),
Dock behavior (your apps untouched), Finder bits, fast key repeat +
tap-to-click + natural scroll, screenshot prefs, login chime (afplay
LaunchAgent), kitty theme. Firmware limits: the boot Apple logo and the
built-in startup chime cannot be replaced (script offers sudo-nvram mute only).

## Hyprland (“hyperland”) — dark + dock + macbinds

Run `./furarcher.sh` and pick `2`, or `./furarcher.sh --hyprland`.
Installs Hyprland + waybar/wofi/kitty/mate-polkit from **official Fedora repos**
(verified 0.44 on F41 aarch64 — no COPR needed) and drops in
`hypr/hyprland.conf` (M1 Air 2560x1664, scale 2) with:
* dark mode everywhere (`ricer darkmode`: GTK adw-gtk3-dark, prefer-dark, kitty, waybar, wofi)
* mac-like top bar + bottom dock (`ricer dock` -> `~/.config/waybar/furarcher-{top,dock}.*`)
* macOS keybinds (`ricer macbinds`): full mac map — Cmd+Space Spotlight,
  Cmd+Tab/` window switch, Cmd+Q/W/N/T/H/M/F, Cmd+Opt+Esc force-quit,
  Cmd+Shift+3/4/5 screenshots, Ctrl+Cmd+Q lock, Mission Control spaces 1-5,
  natural scroll + tap-to-click; kitty gets Cmd+C/V/T/W/N, tabs 1-9, font keys;
  GNOME gets Cmd+Q close, Cmd+Tab apps, Ctrl+Space input switch, Cmd+Shift+3/4 shots
* macOS look (`ricer mactheme`, needs network): WhiteSur-Dark GTK = real
  traffic-light buttons (red/yellow/green, left side) in every GTK app on both
  GNOME and Hyprland. Limit: Hyprland draws no titlebars of its own, so there
  are no buttons on bare Hyprland chrome — only inside apps.

```bash
./bin/ricer apply   # boykisser-dark wallpaper + boykisser theme + darkmode + dock + macbinds
./bin/ricer themes  # 16 pride/love palettes: boykisser mlm achillean bear honey midnight paw ...
./bin/ricer theme mlm|achillean|bear|honey|midnight|paw|boykisser|femboy|gay|furry|...
./bin/ricer mood mlm|furry|femboy|gaylove|midnight|bear|achillean|boykisser  # wallpaper+theme preset
./bin/ricer love mlm|gaylove|furry|femboy|boykisser|bear   # wholesome SFW note
./bin/ricer wallpapers  # 5 bundled SVGs: boykisser-dark, boykisser-mlm, gaylove-sunset, furry-paws-night, fur-pride
./bin/furfetch mlm|furry|femboy|gaylove|bear|midnight|boykisser
./bin/ricer darkmode; ./bin/ricer dock; ./bin/ricer macbinds
./bin/ricer gpu     # Asahi AGX Mesa check + honest ANE note
```

## Boot: chime + GRUB art + Plymouth splash

Firmware honesty first: the power-on **Apple logo** and **Mac chime** play from
Apple firmware before Linux loads — no Linux tool can change them (muting the
Mac chime needs macOS NVRAM). Everything *after* firmware is themeable:

```bash
./bin/ricer chime boykisser  # login chime (synthesized WAV, user service, no sudo)
./bin/ricer chime off        # silence it
./bin/ricer grub boykisser   # GRUB menu background (sudo, backup, grub2-mkconfig)
./bin/ricer grub restore
./bin/ricer splash boykisser # Plymouth boot splash, Fedora logo -> boykisser
                             # (sudo + initramfs rebuild, backup kept)
./bin/ricer splash restore
```

The Plymouth theme (`plymouth/furarcher.plymouth`) is `two-step`, key-for-key
compatible with Fedora's stock spinner theme, with boykisser-dark colors and a
pink progress bar. PNG rendering prefers `rsvg-convert`/`inkscape`/`convert`
and falls back to a stdlib gradient (`sudo dnf install -y librsvg2-tools` for
full art).

## Web fetch (SFW only, 5 providers + full-auto)

`ricer find` hits **wallhaven** (`purity=100` SFW-only) + **nekos.best**
(neko / husbando for mlm + gay boys / kitsune for furries) + **safebooru**
(SFW-only imageboard: `cat_ears+kiss`, `2boys+holding_hands`, `femboy`…) +
**openverse** (CC photos, with license credit) + **waifu.im** (best-effort —
currently 403s keyless curl, fails silent). Mood-aware routing included.
Reddit/Pinterest are out by design: both serve login walls to keyless curl
(verified 2026-10-05) — Reddit needs an OAuth app, Pinterest has no public API.

```bash
./bin/ricer auto boykisser           # search web -> top hit -> full rice, bundled fallback if offline
./bin/ricer auto gaylove             # same, honey theme + love note
./bin/ricer find boykisser 6          # cat kiss + neko + SFW anime
./bin/ricer find mlm 6                # husbando (gay boys, SFW) + anime couple
./bin/ricer find furry 6               # kitsune + fox/wolf art, SFW
./bin/ricer find femboy 6 --source=safebooru
./bin/ricer find pastel 4 --source=wallhaven|nekos|waifu|safebooru|openverse|all
./bin/ricer preview 1                 # URL + kitty inline image if available
./bin/ricer get 1 --apply=mlm         # image-validated download, logged, optionally applied
./bin/ricer fetch-pack gaylove 4      # top-4 SFW web hits for a mood, saved to ~/.local/share/backgrounds
```

## GNOME vs Hyprland (“hyperland”)

* **GNOME = stable.** Fedora Asahi Remix ships GNOME + KDE tuned for Apple GPU/audio/notch. Use this for your friend’s daily driver.
* **Hyprland = experimental.** Wayland tiling compositor, works on Asahi AGX Mesa for many but expect glitches, missing gestures, external-display quirks. Config at `hypr/hyprland.conf` (M1 Air 2560x1664, scale 2). Pick Hyprland at GDM gear icon, keep GNOME as fallback.

## Asahi M1 specifics handled

* `dnf` path (no pacman/AUR/`yay`), `aarch64` arch check, Asahi kernel/device-tree detect
* Installs to `~/.local/bin` (no `/usr/bin` SYSTEM writes)
* Skips x86_64-only bundles: CatgirlDownloader, WaifuDownloader, NyarchUpdater, Wizard/Tour flatpaks — they fail on ARM. Replaced with Flathub aarch64 SFW apps (Krita, Blender, Inkscape, Flatseal, Lollypop, Shortwave).
* `furfetch` replaces `nyaofetch`/`nekofetch` with SFW boykisser paw+neko ASCII.
* GPU: Asahi AGX via kernel + Mesa (`mesa-dri-drivers`, `mesa-vulkan-drivers`) — `ricer gpu` verifies.
  ANE has no Linux driver (Apple firmware, no upstream support) — AI runs on CPU, keep <=8B Q4 on the 8GB Air.

## FurAssistant — local Hermes AI (NyarchAssistant replacement)

NyarchAssistant is a [Newelle](https://github.com/qwersyk/Newelle) fork whose
Flatpak is x86_64-only, so M1 Asahi gets a native ARM64 stack instead:
**Ollama + Hermes** (`hermes3:8b`, fits 8GB Air) + `furassistant` CLI.
Offered as an installer step, or standalone:

```bash
cd furassistant && ./install-furassistant.sh
furassistant chat                        # talk to Paws ^_^
furassistant research "topic" URL...     # auto-research -> saved report
furassistant dream                       # nightly memory consolidation (systemd 03:00)
furassistant rsi --iters 3               # bounded self-improvement of persona only
furassistant config "set dark wallpaper" # guarded auto-config, confirm first
```

See `furassistant/README.md`. Everything local, SFW only. Skips Newelle's
GPU-heavy bits (Live2D avatars, Stable Diffusion) — too slow on a fanless Air.
Blends ideas from 8 repos: NyarchAssistant, DeepBot, GirlfriendGPT (as buddy
cards), N.E.K.O, ECC, AgentSociety, airi, Soul-of-Waifu — plus an LDR kit
(SK↔US time bridge, Slovak phrasebook, co-op quest RPG) for him and his bf.

## SFW / 16+ policy

* No porn, no fetish content, no untagged image feeders.
* Wallpapers in `wallpapers/` are abstract pride/paw SVG only. Drop your friend’s own SFW art into `~/.local/share/backgrounds/`.
* Neko kept as cute ears/ASCII + optional `nekos.best` SFW API — keep SFW filter ON.

## Install via Homebrew (tap)

```bash
brew tap shadyuwugurl/furarcher-asahi
brew install furarcher-asahi
```

Installs `furarcher`, `furfetch`, `furassistant`, and `ricer` + payload (Hyprland conf,
wallpapers, skills, personalities, timers). The full `furarcher` installer
targets Asahi Fedora; the CLI tools also run on macOS with Ollama installed.

## Push as your fork

```bash
gh repo create furarcher-asahi --public --source=. --push
# or: git init; git add .; git commit -m "Furarcher Asahi SFW remix"; git remote add origin <your-url>; git push -u origin main
```

Upstream credit: NyarchLinux/Nyarcher + NyarchLinux (themes). Keep GPL-3.0.
