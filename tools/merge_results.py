#!/usr/bin/env python3
"""Fuehrt waza-Ergebnisdateien (je ein Task/Trial) zu einer Datei zusammen: gleiche test_id -> runs werden angehaengt."""
import glob, json, sys
src, out = sys.argv[1], sys.argv[2]
base = None
for f in sorted(glob.glob(f"{src}/*.json")):
    try:
        d = json.load(open(f, encoding="utf-8"))
    except (OSError, ValueError):
        print(f"uebersprungen (nicht lesbar): {f}", file=sys.stderr); continue
    if base is None:
        base = d; base["tasks"] = list(d.get("tasks", [])); continue
    for t in d.get("tasks", []):
        m = next((b for b in base["tasks"] if b["test_id"] == t["test_id"]), None)
        if m is None:
            base["tasks"].append(t)
        else:
            m["runs"] += t["runs"]
if base is None:
    sys.exit("keine Ergebnisdateien gefunden")
for t in base["tasks"]:
    for n, r in enumerate(t["runs"], 1):
        r["run_number"] = n
    t["status"] = "passed" if all(r.get("status") == "passed" for r in t["runs"]) else "failed"
base.pop("summary", None)
json.dump(base, open(out, "w", encoding="utf-8"), ensure_ascii=False)
print(f"{len(base['tasks'])} Tasks, {sum(len(t['runs']) for t in base['tasks'])} Laeufe -> {out}")
