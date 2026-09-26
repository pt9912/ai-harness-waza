#!/usr/bin/env python3
"""Validiert waza-Dateien gegen die offiziellen JSON-Schemas (Version des Images).

Prueft zusaetzlich, was das Schema nicht kann:
  - Fixture-Dateien aus inputs.files existieren
  - Task-IDs sind eindeutig
  - Regex-Muster sind syntaktisch gueltig und enthalten keine Konstrukte, die Go/RE2
    nicht kennt (Lookaround, Rueckreferenzen, atomare Gruppen, possessive Quantoren).
    Heuristik: die echte Pruefung erfolgt beim Lauf von waza.
Aufruf im Container (Arbeitsverzeichnis /workspace): schema_check.py [wurzel]
"""
import glob, json, os, re, sys
import yaml
from jsonschema import Draft7Validator

SCHEMAS = os.environ.get("WAZA_SCHEMAS", "/opt/waza/schemas")
ROOT = sys.argv[1] if len(sys.argv) > 1 else "."
NOT_RE2 = [(r"\(\?<?[=!]", "Lookahead/Lookbehind"), (r"\\[1-9]", "Rueckreferenz"),
           (r"\(\?>", "atomare Gruppe"), (r"(?<![\\])[*+?}]\+", "possessiver Quantor")]


def validator(name):
    with open(f"{SCHEMAS}/{name}.schema.json", encoding="utf-8") as f:
        return Draft7Validator(json.load(f))


def load(path):
    with open(path, encoding="utf-8") as f:
        return yaml.safe_load(f)


def where(err):
    return "/".join(str(p) for p in err.absolute_path) or "<root>"


def main():
    errors, counts = [], {"task": 0, "eval": 0, "config": 0}
    v_task, v_eval, v_conf = validator("task"), validator("eval"), validator("config")

    def check(kind, v, path):
        counts[kind] += 1
        try:
            data = load(path)
        except yaml.YAMLError as e:
            errors.append(f"{path}: YAML-Fehler: {str(e).splitlines()[0]}")
            return None
        for e in sorted(v.iter_errors(data), key=lambda e: list(e.absolute_path)):
            errors.append(f"{path}: [{kind}-Schema] {where(e)}: {e.message[:140]}")
        return data

    for cfg in glob.glob(os.path.join(ROOT, ".waza.yaml")):
        check("config", v_conf, cfg)

    ids = {}
    for ev in sorted(glob.glob(os.path.join(ROOT, "evals", "*"))):
        for f in sorted(glob.glob(os.path.join(ev, "eval*.yaml"))):
            check("eval", v_eval, f)
        for f in sorted(glob.glob(os.path.join(ev, "tasks", "*.yaml"))):
            t = check("task", v_task, f)
            if not isinstance(t, dict):
                continue
            tid = t.get("id")
            if tid in ids:
                errors.append(f"{f}: Task-ID '{tid}' doppelt (auch in {ids[tid]})")
            ids[tid] = f
            for fx in (t.get("inputs") or {}).get("files") or []:
                p = fx.get("path") if isinstance(fx, dict) else None
                if p and not os.path.exists(os.path.join(ev, "fixtures", p)):
                    errors.append(f"{f}: Fixture fehlt: fixtures/{p}")
            for g in t.get("graders") or []:
                cfg = g.get("config") or {}
                for key in ("regex_match", "regex_not_match"):
                    rxs = cfg.get(key)
                    if not isinstance(rxs, list):
                        continue  # Typfehler meldet bereits das Schema
                    for rx in rxs:
                        if not isinstance(rx, str):
                            continue
                        try:
                            re.compile(rx)
                        except re.error as e:
                            errors.append(f"{f}: Regex ungueltig ({g.get('name')}): {e}: {rx[:70]}")
                            continue
                        for pat, what in NOT_RE2:
                            if re.search(pat, rx):
                                errors.append(f"{f}: Regex nicht RE2-tauglich ({what}) in {g.get('name')}: {rx[:70]}")

    print(f"Schema-Pruefung: {counts['task']} Tasks, {counts['eval']} Evals, {counts['config']} Config")
    for e in errors:
        print("  FEHLER", e)
    print(f"{'OK' if not errors else str(len(errors)) + ' Fehler'}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
