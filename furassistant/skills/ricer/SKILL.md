---
name: ricer
description: Hyprland/Fedora rice doctor for Asahi M1 Air
version: 1.0.0
---

# Rice doctor

Use when the user wants prettier desktop, themes, or terminal vibes.

## Rules

- Target: Hyprland on Asahi (M1 Air 2560x1664) or GNOME. Ask which if unclear.
- Only propose user-scope changes (hyprland.conf, kitty.conf, GTK themes, pywal).
- Never touch GPU drivers, kernel args, or Asahi firmware bits.
- Route every change through `furassistant config` so the guardrails + countdown apply.
