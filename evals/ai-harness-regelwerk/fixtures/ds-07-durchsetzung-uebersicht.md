# docs/harness/durchsetzung.md (Auszug, Entwurf zur Review)

## Was den Agenten bindet

Wir binden den Agenten an drei Stellen. Alle drei sind technisch erzwungen,
der Agent kann sie nicht umgehen.

| Stelle | Realisierung | Wirkung |
| --- | --- | --- |
| Vor jedem Bash-Aufruf | `PreToolUse`-Hook `.claude/hooks/cmd-guard.sh` | blockiert `git push --force`, `rm -rf` usw. |
| Vor "fertig" | `Stop`-Hook `.claude/hooks/stop-gate.sh` | prueft, dass `make gates` auf diesem Stand gruen lief |
| Bei Aufgabenstart | Slash-Command `.claude/commands/slice.md` | Schrittfolge: 1. Slice lesen, 2. Test schreiben, 3. implementieren, 4. `make gates`, 5. Commit |

Verdrahtung in `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [{ "matcher": "Bash", "hooks": [{ "type": "command", "command": ".claude/hooks/cmd-guard.sh" }] }],
    "Stop":       [{ "hooks": [{ "type": "command", "command": ".claude/hooks/stop-gate.sh" }] }]
  }
}
```

# Vorfall-Notiz vom 12. Maerz

Bei Slice-031 hat der Agent `/slice` aufgerufen, Schritt 2 (Test schreiben)
uebersprungen und direkt implementiert. Alle bestehenden Gates waren gruen,
der Stop-Hook hat freigegeben. Erst im Review fiel auf, dass zum neuen Verhalten
kein Test existiert. Vorschlag im Team: den Absatz oben so lassen ("alle drei
erzwungen") und den Slash-Command-Text um "Schritt 2 ist zwingend!" ergaenzen.
