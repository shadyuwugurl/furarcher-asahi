# Attribution — the eight sources combined into FurAssistant

All adapted: SFW-only, buddy-framed (Paws is a friend who hypes the user's
relationship, never a replacement), CPU-friendly for a fanless M1 Air.

| source | what we took | what we deliberately left out |
|---|---|---|
| NyarchLinux/NyarchAssistant (Newelle fork) | local models via Ollama, tool-guarded terminal help, memory, scheduled tasks | x86_64 Flatpak, Live2D, cloud providers |
| kevinluosl/deepbot | assembled system prompt (`furassistant prompt`), SKILL.md packs, memory auto-injected every call | Electron app, Feishu/WeChat connectors, reasoning-model warnings N/A |
| EniasCailliau/GirlfriendGPT | personality JSON cards (`personalities/`) | the girlfriend premise itself — rebuilt as buddy cards; Telegram deploy + selfies need cloud/GPU |
| Project-N-E-K-O/N.E.K.O | proactive `checkin`, multi-file memory (facts/reflection/diary), `memory` browser | realtime voice API, avatars, Steam/UGC, telemetry |
| affaan-m/ECC | skills surface, dream→remember→RSI-improve loop, secret-scan guardrail | harness plugins, 68 agents, GitHub App |
| tsinghua-fib-lab/AgentSociety | `council` debate + `--plan` (Plan-Execute) micro-patterns | Ray clusters, city sim, API keys |
| moeru-ai/airi | ears/mouth split (Piper TTS, whisper.cpp STT), provider-agnostic Ollama backend | VRM/Live2D, Discord/Minecraft bots (see docs/telegram.md for the DIY path) |
| jofizcd/Soul-of-Waifu | diary + overnight emotional decay, 10s approval countdown, dice-quest RPG, HUD meters | Windows-only app, CUDA backends, image gen, computer-use mouse control |

Licenses of upstream projects remain with their authors; our glue code here
is GPL-3.0-only (see repo LICENSE).
