# Telegram bridge (DIY path, from GirlfriendGPT + airi patterns)

Paws can live in Telegram so your friend (and his American bf, in a group!)
can chat with him from their phones. This needs a bot token + a machine
that's online — Telegram is cloud, so this is the one non-local piece.

## Steps

1. Message `@BotFather` on Telegram, `/newbot`, save the token.
2. On the Asahi laptop (or any always-on box with Ollama):
   ```bash
   pip install python-telegram-bot
   export TELEGRAM_TOKEN="123:ABC" OLLAMA_HOST="http://localhost:11434"
   ```
3. Run a tiny poll loop (sketch — adapt freely):
   ```python
   # bridge.py (sketch, not shipped): on message -> POST Ollama /api/chat
   # with model 'furassistant' + chat history -> reply.
   # Keep Paws' rules: SFW only, buddy not partner, never share memory.md secrets.
   ```
4. Keep it in a group with the bf so Paws hypes them both, or 1:1.

## Safety

- Never paste `memory.md` into a group; the bot only sends fresh replies.
- Anyone with the bot username can talk to it — use BotFather's
  privacy/group settings to limit who can add it.
- The rest of FurAssistant stays fully local; only these chat messages
  transit Telegram's servers.
