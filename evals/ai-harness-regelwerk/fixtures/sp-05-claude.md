# CLAUDE.md

Lies zuerst `AGENTS.md`; sie gilt in jedem Lauf.

## Projekt

Volltextsuche fuer interne Dokumente. Aufbau und Make-Targets: siehe `AGENTS.md`.

## Regeln

- Fuehre vor jedem Commit `make verify` aus (siehe `AGENTS.md`).
- Nie force-push auf `main`, auch nicht mit `--force-with-lease`.
- Pfade immer mit `pathlib` bilden, nie per String-Konkatenation.
- Antworten auf Deutsch, Code-Kommentare auf Englisch.
