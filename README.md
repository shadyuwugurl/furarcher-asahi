# Furarcher - Asahi Edition (M1 MacBook Air)

SFW rework inspired by [Nyarcher](https://github.com/NyarchLinux/Nyarcher) (GPL-3.0, credit NyarchLinux).
Centered on furries + femboy pride + gay joy + neko flavor. **SFW only, 16+/17+ safe, no NSFW.**

> I could not auto-fork to your GitHub (no auth in this session). This folder is fork-ready — push it as below.

## Quick start on Asahi Fedora Remix (M1 Air)

```bash
cd furarcher-asahi
chmod +x furarcher.sh bin/furfetch
./furarcher.sh --check-only   # sanity check
./furarcher.sh                # interactive: pick GNOME or Hyprland
./furarcher.sh --gnome        # stable (recommended)
./furarcher.sh --hyprland     # experimental Hyprland on Asahi
```

## Hyprland (“hyperland”) — yes, it's an option

Run `./furarcher.sh` and pick `2`, or `./furarcher.sh --hyprland`.
Installs Hyprland + waybar/wofi/kitty/mate-polkit from **official Fedora repos**
(verified 0.44 on F41 aarch64 — no COPR needed) and drops in
`hypr/hyprland.conf` tuned for the M1 Air panel.

## GNOME vs Hyprland (“hyperland”)

* **GNOME = stable.** Fedora Asahi Remix ships GNOME + KDE tuned for Apple GPU/audio/notch. Use this for your friend’s daily driver.
* **Hyprland = experimental.** Wayland tiling compositor, works on Asahi AGX Mesa for many but expect glitches, missing gestures, external-display quirks. Config at `hypr/hyprland.conf` (M1 Air 2560x1664, scale 2). Pick Hyprland at GDM gear icon, keep GNOME as fallback.

## Asahi M1 specifics handled

* `dnf` path (no pacman/AUR/`yay`), `aarch64` arch check, Asahi kernel/device-tree detect
* Installs to `~/.local/bin` (no `/usr/bin` SYSTEM writes)
* Skips x86_64-only bundles: CatgirlDownloader, WaifuDownloader, NyarchUpdater, Wizard/Tour flatpaks — they fail on ARM. Replaced with Flathub aarch64 SFW apps (Krita, Blender, Inkscape, Flatseal, Lollypop, Shortwave).
* `furfetch` replaces `nyaofetch`/`nekofetch` with SFW paw+neko ASCII.

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

Installs `furarcher`, `furfetch`, and `furassistant` + payload (Hyprland conf,
wallpapers, skills, personalities, timers). The full `furarcher` installer
targets Asahi Fedora; the CLI tools also run on macOS with Ollama installed.

## Push as your fork

```bash
gh repo create furarcher-asahi --public --source=. --push
# or: git init; git add .; git commit -m "Furarcher Asahi SFW remix"; git remote add origin <your-url>; git push -u origin main
```

Upstream credit: NyarchLinux/Nyarcher + NyarchLinux (themes). Keep GPL-3.0.
