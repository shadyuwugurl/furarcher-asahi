#!/bin/bash
# Offline end-to-end test of furassistant CLI against stub Ollama.
# Usage: ./test-cli.sh   (needs python3 + curl)
set -u
cd "$(dirname "$0")/.." || exit 1
FAIL=0
pass(){ echo "PASS: $1"; }
fail(){ echo "FAIL: $1"; FAIL=1; }

command -v python3 >/dev/null || { echo "SKIP: no python3"; exit 0; }
export TESTHOME; TESTHOME=$(mktemp -d)
export HOME="$TESTHOME"
export OLLAMA_HOST="http://127.0.0.1:11439"
export FUR="$PWD/bin/furassistant"
chmod +x "$FUR" bin/furassistant 2>/dev/null || true

python3 tests/stub-ollama.py & STUB=$!
trap 'kill $STUB 2>/dev/null; wait $STUB 2>/dev/null; rm -rf "$TESTHOME"' EXIT
sleep 1

# seed installed data like install-furassistant.sh does
mkdir -p "$TESTHOME/.local/share/furassistant/skills" "$TESTHOME/.local/share/furassistant/personalities"
cp -rf ./skills/. "$TESTHOME/.local/share/furassistant/skills/"
cp -rf ./personalities/. "$TESTHOME/.local/share/furassistant/personalities/"
cp -f ./data/sk-phrases.md "$TESTHOME/.local/share/furassistant/sk-phrases.md"

"$FUR" ask "hello" | grep -q "stub reply" && pass "ask" || fail "ask"

echo '<html><body><h1>Hi</h1><script>bad()</script><p>Real text here</p></body></html>' > "$TESTHOME/page.html"
"$FUR" research "stubtopic" "file://$TESTHOME/page.html" | grep -q "stub summary" && pass "research" || fail "research"
ls "$TESTHOME/.local/share/furassistant/research/"*.md >/dev/null 2>&1 && pass "research saved" || fail "research saved"

mkdir -p "$TESTHOME/.local/share/furassistant/chats"
echo "**you:** hi" > "$TESTHOME/.local/share/furassistant/chats/$(date +%F).md"
"$FUR" dream | grep -q "dreamt" && pass "dream" || fail "dream"
grep -q "likes pink" "$TESTHOME/.local/share/furassistant/memory.md" && pass "memory updated" || fail "memory updated"
ls "$TESTHOME/.local/share/furassistant/dreams/$(date +%F).md" >/dev/null 2>&1 && pass "dream journal" || fail "dream journal"

echo "y" | "$FUR" config "say hi" | grep -q "stub-test-ok\|proposed plan" && pass "config plan" || fail "config plan"

"$FUR" rsi --iters 1 | grep -q "ACCEPTED" && pass "rsi accept-path" || fail "rsi accept-path"
grep -q "GEN2" "$TESTHOME/.config/furassistant/persona.md" && pass "persona evolved" || fail "persona evolved"
ls "$TESTHOME/.local/share/furassistant/rsi/"*.bak >/dev/null 2>&1 && pass "rsi backup" || fail "rsi backup"

echo "y" | "$FUR" config "run sudo rm -rf /" | grep -qi "refus\|block" && pass "config guardrail" || fail "config guardrail"

# --- new mix commands ---
"$FUR" council "nap or walk?" | grep -q "Verdict" && pass "council" || fail "council"
ls "$TESTHOME/.local/share/furassistant/council/"*.md >/dev/null 2>&1 && pass "council saved" || fail "council saved"

"$FUR" quest start testq "A cozy tavern" | grep -qi "started" && pass "quest start" || fail "quest start"
"$FUR" quest "do" "order hot cocoa" | grep -qi "tavern cheers" && pass "quest do" || fail "quest do"

"$FUR" skill cozy-story "a sleepy fox" | grep -q "Skill applied" && pass "skill" || fail "skill"
"$FUR" skill nope "x" | grep -qi "no such skill" && pass "skill missing" || fail "skill missing"

echo "hi bestie" > "$TESTHOME/.local/share/furassistant/chats/$(date +%F).md"
"$FUR" memory | grep -q "memory" && pass "memory show" || fail "memory show"
"$FUR" memory "bestie" | grep -q "bestie" && pass "memory search" || fail "memory search"

"$FUR" checkin | grep -qi "bestie" && pass "checkin" || fail "checkin"
"$FUR" status | grep -q "mood" && pass "status" || fail "status"

"$FUR" sk "wolf" | grep -qi "vlk" && pass "sk search" || fail "sk search"

"$FUR" speak "hi" | grep -qi "not installed" && pass "speak graceful" || fail "speak graceful"
"$FUR" listen | grep -qi "not installed" && pass "listen graceful" || fail "listen graceful"

"$FUR" ldr | grep -q "call windows" && pass "ldr" || fail "ldr"
printf 'US_ZONE=America/Chicago\nBF_NAME=TestBF\nVISIT_DATE=2030-01-01\n' > "$TESTHOME/.config/furassistant/ldr.conf"
"$FUR" ldr | grep -q "TestBF" && pass "ldr config" || fail "ldr config"
"$FUR" ldr | grep -q "countdown" && pass "ldr countdown" || fail "ldr countdown"

if [ "$FAIL" -eq 0 ]; then echo "ALL CLI CHECKS PASSED"; else echo "SOME CLI CHECKS FAILED"; fi
exit "$FAIL"
