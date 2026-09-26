#!/usr/bin/env python3
"""Exit 1, wenn ein Lauf einen Infrastrukturfehler zeigt (Wiederholung noetig): Judge ohne Urteil
(passed=False mit Meldung 'All prompts passed' = weder pass noch fail aufgerufen), Grader/Session-Fehler oder keine Datei."""
import json, sys
try:
    d = json.load(open(sys.argv[1], encoding="utf-8"))
except (OSError, ValueError):
    print("keine lesbare Ergebnisdatei"); sys.exit(1)
for t in d.get("tasks", []):
    for r in t.get("runs", []):
        err = (r.get("error_msg") or "")
        if any(k in err for k in ("failed to run grader", "failed to resume session", "session error", "context deadline")):
            print(f"Infrastrukturfehler: {err[:80]}"); sys.exit(1)
        for k, x in (r.get("validations") or {}).items():
            if k.startswith("judge_") and isinstance(x, dict) and x.get("passed") is False \
               and (x.get("feedback") or "").strip() == "All prompts passed":
                print("Judge ohne Urteil"); sys.exit(1)
sys.exit(0)
