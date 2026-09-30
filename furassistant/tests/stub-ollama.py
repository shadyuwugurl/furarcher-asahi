#!/usr/bin/env python3
# Deterministic stub of Ollama /api/tags + /api/chat for testing furassistant.
import json
from http.server import BaseHTTPRequestHandler, HTTPServer

class H(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def _send(self, obj):
        body = json.dumps(obj).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/api/tags":
            return self._send({"models": [{"name": "furassistant"}]})
        self.send_response(404); self.end_headers()

    def do_POST(self):
        if self.path != "/api/chat":
            self.send_response(404); self.end_headers(); return
        length = int(self.headers.get("Content-Length", 0))
        data = json.loads(self.rfile.read(length) or b"{}")
        text = " ".join(m.get("content", "") for m in data.get("messages", []))
        if "sudo rm" in text:
            reply = "REFUSE"
        elif "SECRET_MARKER" in text:
            reply = "MEMORY:\n- mystuff key is sk-SECRET1234567890\nREFLECTION:\nNone.\nDREAM:\nQuiet night.\nMOOD:\ncalm"
        elif "Rate this assistant reply" in text:
            reply = "5" if "CAND response" in text else "2"
        elif "Nightly DREAM" in text:
            reply = "MEMORY:\n- testuser likes pink\nREFLECTION:\nTestuser is kind.\nDREAM:\nDreamt of cozy servers.\nMOOD:\ndreamy"
        elif "improving the assistant persona" in text:
            reply = "GEN2 refined note: be extra cozy and brief."
        elif "desktop auto-config" in text:
            reply = "notify-send stub-test-ok"
        elif "auto-research" in text:
            reply = "TL;DR stub summary\n- fact one\n- fact two"
        elif "synthesizing" in text:
            reply = "Verdict: do both, bestie."
        elif "Draft a short step" in text:
            reply = "PLAN: one gentle step."
        elif "Advisor Practical" in text:
            reply = "Practical says: plan it."
        elif "Advisor Heart" in text:
            reply = "Heart says: feel it."
        elif "tabletop GM" in text:
            reply = "The dice favor you. The tavern cheers!"
        elif "hype note" in text:
            reply = "Good morning bestie! You are loved and amazing!"
        elif "Follow this skill pack" in text:
            reply = "Skill applied: cozy."
        elif "Persona under test" in text:
            reply = "CAND response" if "GEN2" in text else "BASE response"
        else:
            reply = "stub reply ^_^"
        self._send({"message": {"content": reply}})

if __name__ == "__main__":
    HTTPServer(("127.0.0.1", 11439), H).serve_forever()
