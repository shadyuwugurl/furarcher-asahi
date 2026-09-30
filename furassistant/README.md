# FurAssistant — local Hermes AI for Furarcher Asahi

SFW-only local companion, inspired by NyarchAssistant (which is a
[Newelle](https://github.com/qwersyk/Newelle) fork: multi-provider chat,
local models via Ollama/llama.cpp, terminal commands, MCP tools, memory,
web search, scheduled tasks). Nyarch's Flatpak bundle is x86_64-only, so on
M1 Asahi we ship a native ARM64 stack instead:

- **Ollama** (`linux-arm64` build, CPU inference) + **Hermes agent model**
  - default `hermes3:8b` — 8B, function-calling, roleplay-tuned, fits 8GB M1 Air at Q4
  - 16GB machines: install with `--from=qwen3:14b`, or pull `Hermes-4-14B` GGUF yourself
- **`furassistant` CLI**: `chat` · `ask` · `research` · `dream` · `rsi` · `config`

## Install (on Asahi)

```bash
cd furassistant
chmod +x install-furassistant.sh
./install-furassistant.sh --yes
# 16GB Air: ./install-furassistant.sh --from=qwen3:14b
```

## Features

| command | what it does | mixed from |
|---|---|---|
| `furassistant chat` | REPL with Paws, logged to `~/.local/share/furassistant/chats/` | NyarchAssistant |
| `furassistant ask "..."` | one-shot answer | NyarchAssistant |
| `furassistant research <topic> [URL...]` | fetches pages, model summarizes → report in `research/` | NyarchAssistant web + DeepBot fetch |
| `furassistant dream` | nightly consolidation → `memory.md` + `reflection.md` + `dreams/` journal (systemd timer 03:00), with secret-scan + contradiction care + overnight mood decay | N.E.K.O memory, SoW self-healing diary + decay, ECC shield |
| `furassistant rsi [--iters N]` | bounded Recursive Self-Improvement of `persona.md` only, judge-gated, backups kept | ECC improve-loop |
| `furassistant config "..."` | proposes user-scope shell plan, 10s fail-safe countdown, runs only on confirm | NyarchAssistant terminal + SoW approval banner |
| `furassistant skill <name> "..."` | SKILL.md prompt packs (`ldr-call-plan`, `cozy-story`, `ricer`) | DeepBot + ECC skills |
| `furassistant council [--plan] "..."` | 2-advisor debate (Practical + Heart) + Paws verdict, saved; `--plan` = draft→critique→approve | AgentSociety debate + Plan-Execute |
| `furassistant prompt` | writes the fully assembled system prompt to `PROMPT.md` (base + persona + memory + skills) | DeepBot prompt assembly |
| `furassistant quest ...` | cozy dice RPG with Hermes GM — made for LDR co-op calls | Soul-of-Waifu Stage-lite |
| `furassistant ldr` | SK↔US time bridge, overlap windows, visit countdown | (for him + his bf <3) |
| `furassistant sk [word]` | Slovak mini-phrasebook (SFW love + furry words) | (for the American bf) |
| `furassistant speak "..."` | local Piper TTS | airi mouth |
| `furassistant listen [secs]` | local whisper.cpp STT | airi ears |
| `furassistant checkin` | proactive hype note (timers 08:00/22:00) | N.E.K.O proactive care |
| `furassistant memory [q]` | browse/search memory, diary, dreams, chats | N.E.K.O memory browser |
| `furassistant status` | HUD: energy/hype/mood + both timezones | Soul-of-Waifu state vars |

## Safety rails (why your friend can't nuke the system)

- `config` allowlists user-scope commands only (`gsettings`, `wal`, `flatpak`…),
  blocks `sudo`/`rm -rf /`/`mkfs`/`curl|sh`, always prints the plan first.
- `rsi` only rewrites `~/.config/furassistant/persona.md`, max 3 iters by default,
  keeps `*.bak` of every accepted generation, keeps a change only if it scores higher.
- Everything is local: chats, memory, and models never leave the laptop.

## Notes vs NyarchAssistant

Newelle features we deliberately skip on M1 Air: Live2D avatars (GPU-heavy),
Stable Diffusion image gen (too slow on 8GB CPU-only), cloud providers.
What you keep: local chat, memory, web research, scheduled dreaming,
tool-guarded terminal help — the parts that matter on a fanless Air.

## The mix (credits)

Ideas ported into this remix — all adapted SFW, buddy-framed (Paws is a
friend who hypes the relationship, never a replacement), CPU-friendly:

- NyarchLinux/NyarchAssistant — base concept (local models, tools, memory, tasks)
- kevinluosl/deepbot — dynamic prompt assembly, path whitelist, per-agent memory, skills
- EniasCailliau/GirlfriendGPT — personality JSON cards (rebuilt as buddy cards, not girlfriends)
- Project-N-E-K-O/N.E.K.O — proactive check-ins, 5-dim memory, character cards, memory browser
- affaan-m/ECC — SKILL.md skills, remember→improve loop, secret-scan guardrail
- tsinghua-fib-lab/AgentSociety — `council` micro multi-agent debate
- moeru-ai/airi — ears/mouth split, local TTS/STT, Discord/Telegram bot patterns
- jofizcd/Soul-of-Waifu — diary + emotional decay, approval fail-safe, dice RPG engine, HUD states
